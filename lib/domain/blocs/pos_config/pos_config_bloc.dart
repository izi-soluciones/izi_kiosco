import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

part 'pos_config_state.dart';

class PosConfigBloc extends Cubit<PosConfigState> {
  final AuthBloc authBloc;
  nsd.Discovery? _discovery;
  Timer? _healthTimer;
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasAttemptedAutoPair = false;

  PosConfigBloc(this.authBloc) : super(PosConfigState.init()) {
    _loadSavedState();
    _authSubscription = authBloc.stream.listen((authState) {
      if (!_hasAttemptedAutoPair && state.status == PosConfigStatus.idle) {
        final ipEcopay = authState.currentDevice?.config.ipEcopay;
        if (ipEcopay != null && ipEcopay.isNotEmpty) {
          _hasAttemptedAutoPair = true;
          pairManually(ipEcopay);
        }
      }
    });
  }

  Future<void> _loadSavedState() async {
    final savedIpPort = await TokenUtils.getPosIp();
    if (savedIpPort != null && savedIpPort.isNotEmpty) {
      _hasAttemptedAutoPair = true;
      final parts = savedIpPort.split(':');
      final ip = parts[0];
      final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 8081 : 8081;
      
      final device = PosDevice(name: "POS ($ip)", ip: ip, port: port);
      emit(state.copyWith(
        status: PosConfigStatus.pairedLoaded,
        pairedDevice: device,
        isHealthy: false, // Will be updated by polling
      ));
      _startHealthPolling(device);
    } else {
      final ipEcopay = authBloc.state.currentDevice?.config.ipEcopay;
      if (ipEcopay != null && ipEcopay.isNotEmpty && !_hasAttemptedAutoPair) {
        _hasAttemptedAutoPair = true;
        pairManually(ipEcopay);
      }
    }
  }

  Future<void> beginDiscovery() async {
    emit(
      state.copyWith(
        status: PosConfigStatus.discovering,
        discoveredDevices: [],
      ),
    );
    List<PosDevice> devices = [];

    // 1. Check Localhost (Mock POS) fallback
    try {
      final res = await http
          .get(Uri.parse('http://127.0.0.1:8081/health'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        devices.add(
          const PosDevice(name: "Local POS", ip: "127.0.0.1", port: 8081),
        );
      }
    } catch (_) {}

    // Emit localhost results immediately
    if (!isClosed) {
      emit(state.copyWith(discoveredDevices: List.from(devices)));
    }

    // 2. Start mDNS Discovery (only on native platforms, not web)
    if (!kIsWeb) {
      try {
        final discovery = await nsd.startDiscovery('_http._tcp');
        _discovery = discovery;
        _discovery?.addListener(() {
          final currentServices = _discovery?.services ?? [];
          final newDevices = List<PosDevice>.from(devices);

          for (var service in currentServices) {
            if (service.name != null &&
                service.name!.startsWith("izify-POS-")) {
              final ip = service.host;
              final port = service.port;
              if (ip != null && port != null) {
                final exists = newDevices.any(
                  (d) => d.ip == ip && d.port == port,
                );
                if (!exists) {
                  newDevices.add(
                    PosDevice(name: service.name!, ip: ip, port: port),
                  );
                }
              }
            }
          }

          if (!isClosed) {
            emit(state.copyWith(discoveredDevices: newDevices));
          }
        });
      } catch (e) {
        // mDNS failed but localhost results (if any) are already shown
        // ignore: avoid_print
        print("mDNS discovery unavailable: $e");
      }
    }

    // If no devices found after localhost check (and no mDNS on web), update status
    if (devices.isEmpty && !isClosed) {
      emit(state.copyWith(status: PosConfigStatus.discovering));
    }
  }

  Future<void> endDiscovery() async {
    if (_discovery != null) {
      await nsd.stopDiscovery(_discovery!);
      _discovery = null;
    }
    if (state.status == PosConfigStatus.discovering) {
      emit(state.copyWith(status: PosConfigStatus.idle));
    }
  }

  /// Extracts the 5-digit PIN embedded in the mDNS service name
  /// `izify-POS-<pin>`. Returns null when the name doesn't match (e.g. a
  /// manually-paired device), in which case the caller must supply the pin.
  static String? pinFromServiceName(String name) {
    final match = RegExp(r'izify-POS-(\d{5})$').firstMatch(name);
    return match?.group(1);
  }

  Future<void> pairManually(String ip, {int port = 8081, String? pin, String? mqttClientId, String? mqttUserName, String? mqttPassword, String? commerceId, String? cajaId}) async {
    final trimmedIp = ip.trim();
    if (trimmedIp.isEmpty) return;
    final device = PosDevice(name: "POS ($trimmedIp)", ip: trimmedIp, port: port);
    await pairDevice(device, pin: pin, mqttClientId: mqttClientId, mqttUserName: mqttUserName, mqttPassword: mqttPassword, commerceId: commerceId, cajaId: cajaId);
  }

  Future<void> pairDevice(PosDevice device, {String? pin, String? mqttClientId, String? mqttUserName, String? mqttPassword, String? commerceId, String? cajaId}) async {
    emit(state.copyWith(status: PosConfigStatus.pairing));

    final deviceConfig = authBloc.state.currentDevice?.config;
    final kioskId = authBloc.state.currentDevice?.nombre ?? 'KIOSK-001';
    
    final finalMqttClientId = mqttClientId?.isNotEmpty == true ? mqttClientId : deviceConfig?.mqttClientId;
    final finalMqttUserName = mqttUserName?.isNotEmpty == true ? mqttUserName : deviceConfig?.mqttUserName;
    final finalMqttPassword = mqttPassword?.isNotEmpty == true ? mqttPassword : deviceConfig?.mqttPassword;
    final finalCommerceId = commerceId?.isNotEmpty == true ? commerceId : deviceConfig?.commerceId;
    final finalCajaId = cajaId?.isNotEmpty == true ? cajaId : deviceConfig?.cajaId;

    // The POS now requires the 5-digit PIN from its mDNS service name
    // (izify-POS-<pin>) in the /pair body. Prefer an explicitly provided pin,
    // otherwise derive it from the discovered service name.
    final finalPin = (pin != null && pin.isNotEmpty)
        ? pin
        : pinFromServiceName(device.name);
    if (finalPin == null) {
      emit(
        state.copyWith(
          status: PosConfigStatus.error,
          errorMessage: "Falta el PIN del POS para emparejar",
        ),
      );
      return;
    }

    try {
      final res = await http
          .post(
            Uri.parse('http://${device.ip}:${device.port}/pair'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "kioskId": kioskId,
              "pin": finalPin,
              if (finalMqttClientId != null) "mqttClientId": finalMqttClientId,
              if (finalMqttUserName != null) "mqttUserName": finalMqttUserName,
              if (finalMqttPassword != null) "mqttPassword": finalMqttPassword,
              if (finalCommerceId != null) "commerceId": finalCommerceId,
              if (finalCajaId != null) "cajaId": finalCajaId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['token'] != null) {
          await TokenUtils.savePosToken(
            data['token'],
          );
          await TokenUtils.savePosIp("${device.ip}:${device.port}");
          emit(
            state.copyWith(
              status: PosConfigStatus.paired,
              pairedDevice: device,
              isHealthy: true,
            ),
          );
          _startHealthPolling(device);
        } else {
          emit(
            state.copyWith(
              status: PosConfigStatus.error,
              errorMessage: "Invalid pairing response",
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            status: PosConfigStatus.error,
            errorMessage: "Failed to pair: ${res.statusCode}",
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PosConfigStatus.error,
          errorMessage: "Pairing network error: $e",
        ),
      );
    }
  }

  void _startHealthPolling(PosDevice device) {
    _healthTimer?.cancel();
    _checkHealth(device); // Run immediately
    _healthTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
       _checkHealth(device);
    });
  }

  Future<void> _checkHealth(PosDevice device) async {
    try {
      final res = await http
          .get(Uri.parse('http://${device.ip}:${device.port}/health'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!isClosed) emit(state.copyWith(isHealthy: true, healthData: data is Map<String, dynamic> ? data : null));
      } else {
        if (!isClosed) emit(state.copyWith(isHealthy: false, healthData: null));
      }
    } catch (e) {
      if (!isClosed) emit(state.copyWith(isHealthy: false, healthData: null));
    }
  }

  Future<void> unpair() async {
    if (state.pairedDevice != null) {
      String? token = await TokenUtils.getPosToken();
      token ??= authBloc.state.currentDevice?.config.token;
      try {
        await http
            .post(
              Uri.parse(
                'http://${state.pairedDevice!.ip}:${state.pairedDevice!.port}/unpair',
              ),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    await TokenUtils.deletePosIp();
    await TokenUtils.deletePosToken();
    _healthTimer?.cancel();
    emit(
      state.copyWith(
        status: PosConfigStatus.idle,
        clearPairedDevice: true,
        isHealthy: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _healthTimer?.cancel();
    if (_discovery != null) {
      nsd.stopDiscovery(_discovery!);
    }
    return super.close();
  }
}

class PosDevice extends Equatable {
  final String name;
  final String ip;
  final int port;

  const PosDevice({required this.name, required this.ip, required this.port});

  @override
  List<Object?> get props => [name, ip, port];
}
