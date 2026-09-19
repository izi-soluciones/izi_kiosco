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

  static Future<IzifyPosSession>? _pairing;
  static IzifyPosAddress? _pairingAddress;

  /// Pairs [address] with this kiosk using the backend configuration and
  /// stores the result. Throws [IzifyPosException] with a Spanish message.
  ///
  /// Concurrent pairings of the same terminal (the configuration screen and a
  /// sale both noticing it forgot the kiosk) share one request: each pairing
  /// rotates the token, so two in a row would leave one caller holding a dead
  /// one. When [stillWanted] says no after the terminal answered, nothing is
  /// stored (the kiosk was unpaired or paired elsewhere meanwhile).
  static Future<IzifyPosSession> pair(
    IzifyPosClient client,
    Device? device,
    IzifyPosAddress address, {
    Map<String, String?> overrides = const {},
    bool Function()? stillWanted,
  }) {
    final inFlight = _pairing;
    final automatic = overrides.values.every((v) => v == null || v.trim().isEmpty);
    if (inFlight != null && _pairingAddress == address && automatic) return inFlight;
    final attempt = _pair(client, device, address, overrides, stillWanted);
    _pairing = attempt;
    _pairingAddress = address;
    attempt.then((_) {}, onError: (_) {}).whenComplete(() {
      if (identical(_pairing, attempt)) _pairing = null;
    });
    return attempt;
  }

  static Future<IzifyPosSession> _pair(
    IzifyPosClient client,
    Device? device,
    IzifyPosAddress address,
    Map<String, String?> overrides,
    bool Function()? stillWanted,
  ) async {
    final pin = device?.config.pin;
    if (pin == null || pin.trim().isEmpty) {
      throw const IzifyPosException(
          'Este dispositivo no tiene un PIN configurado. Configúrelo en el backend antes de emparejar.',
          code: 'MISSING_PIN');
    }
    final ecopay = ecoPayFields(device?.config, overrides: overrides);
    // An EcoPay terminal needs the CAJA credentials: say which are missing
    // before pairing, instead of pairing a terminal that cannot charge.
    // (PayPOS 1.26+ refuses such a pairing too.)
    IzifyPosHealth? health;
    try {
      health = await client.health(address);
    } catch (_) {
      // Unreachable: /pair reports it with the right message.
    }
    if (health != null && health.isEcoPay) {
      final missing = IzifyPosClient.ecoPayRequiredFields
          .where((f) => (ecopay[f] ?? '').trim().isEmpty)
          .toList();
      if (missing.isNotEmpty) {
        throw IzifyPosException(IzifyPosClient.missingEcoPayMessage(missing),
            code: 'MISSING_ECOPAY_CONFIG');
      }
    }
    final token = await client.pair(
      address,
      kioskId: kioskIdOf(device),
      pin: pin.trim(),
      ecopay: ecopay,
    );
    final session = IzifyPosSession(address, token);
    if (stillWanted != null && !stillWanted()) return session;
    await TokenUtils.savePosToken(token);
    await TokenUtils.savePosIp(address.hostPort);
    await rememberName(client, address);
    return session;
  }

  /// Whether [health] comes from the terminal this kiosk paired with, by the
  /// name stored at pairing. Unknown (nothing stored, or an older PayPOS that
  /// reports no name) counts as ours.
  static Future<bool> isOurTerminal(IzifyPosHealth health) async {
    final stored = await TokenUtils.getPosName();
    return stored == null || health.name == null || health.name == stored;
  }

  /// Stores the name the terminal at [address] advertises, so it can be
  /// found again by mDNS if its IP changes. Best effort.
  static Future<void> rememberName(IzifyPosClient client, IzifyPosAddress address,
      {IzifyPosHealth? health}) async {
    try {
      final name = (health ?? await client.health(address)).name;
      if (name != null && name.isNotEmpty) await TokenUtils.savePosName(name);
    } catch (_) {}
  }

  /// Keeps the current pairing but talks to the terminal at [address] from
  /// now on: the same terminal, found at a new IP.
  static Future<void> moveTo(IzifyPosAddress address) =>
      TokenUtils.savePosIp(address.hostPort);

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
    await TokenUtils.deletePosName();
    await TokenUtils.deletePosBackendIp();
  }
}
