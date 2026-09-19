import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/models/device.dart';

/// The terminal this kiosk charges on, and the token it was paired with.
class IzifyPosSession {
  final IzifyPosAddress address;
  final String token;

  const IzifyPosSession(this.address, this.token);

  /// The terminal paired on this kiosk, falling back to the backend device
  /// configuration (`ipEcopay` + `token`) when nothing was paired locally.
  static Future<IzifyPosSession?> current(Device? device) async {
    final savedAddress = IzifyPosAddress.tryParse(await TokenUtils.getPosIp());
    final savedToken = await TokenUtils.getPosToken();
    if (savedAddress != null && savedToken != null && savedToken.isNotEmpty) {
      return IzifyPosSession(savedAddress, savedToken);
    }
    final config = device?.config;
    final backendAddress = IzifyPosAddress.tryParse(config?.ipEcopay);
    final backendToken = config?.token;
    if (backendAddress != null && backendToken != null && backendToken.isNotEmpty) {
      return IzifyPosSession(backendAddress, backendToken);
    }
    return null;
  }

  /// The terminal address to use, whether or not it is paired yet.
  static Future<IzifyPosAddress?> configuredAddress(Device? device) async =>
      IzifyPosAddress.tryParse(await TokenUtils.getPosIp()) ??
      IzifyPosAddress.tryParse(device?.config.ipEcopay);

  /// The EcoPay settings the backend holds for this kiosk, as `/pair` wants
  /// them. [overrides] win over the backend when non-empty (typed by the
  /// technician on the configuration screen).
  static Map<String, String?> ecoPayFields(ConfigDevice? config,
      {Map<String, String?> overrides = const {}}) {
    String? pick(String key, String? backend) {
      final typed = overrides[key]?.trim();
      return (typed != null && typed.isNotEmpty) ? typed : backend;
    }

    return {
      'mqttClientId': pick('mqttClientId', config?.mqttClientId),
      'mqttUserName': pick('mqttUserName', config?.mqttUserName),
      'mqttPassword': pick('mqttPassword', config?.mqttPassword),
      'commerceId': pick('commerceId', config?.commerceId),
      'cajaId': pick('cajaId', config?.cajaId),
    };
  }

  /// Pairs [address] with this kiosk using the backend configuration and
  /// stores the result. Throws [IzifyPosException] with a Spanish message.
  static Future<IzifyPosSession> pair(
    IzifyPosClient client,
    Device? device,
    IzifyPosAddress address, {
    Map<String, String?> overrides = const {},
  }) async {
    final pin = device?.config.pin;
    if (pin == null || pin.trim().isEmpty) {
      throw const IzifyPosException(
          'Este dispositivo no tiene un PIN configurado. Configúrelo en el backend antes de emparejar.',
          code: 'MISSING_PIN');
    }
    final token = await client.pair(
      address,
      kioskId: kioskIdOf(device),
      pin: pin.trim(),
      ecopay: ecoPayFields(device?.config, overrides: overrides),
    );
    await TokenUtils.savePosToken(token);
    await TokenUtils.savePosIp(address.hostPort);
    return IzifyPosSession(address, token);
  }

  /// How the terminal knows this kiosk. It must stay stable: the terminal
  /// accepts re-pairing only from the kiosk it is already paired with.
  static String kioskIdOf(Device? device) {
    final name = device?.nombre.trim();
    if (name != null && name.isNotEmpty) return name;
    final id = device?.id;
    return id != null ? 'KIOSK-$id' : 'KIOSK-001';
  }

  static Future<void> forget() async {
    await TokenUtils.deletePosIp();
    await TokenUtils.deletePosToken();
  }
}
