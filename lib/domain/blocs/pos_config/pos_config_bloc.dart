import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'dart:async';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

part 'pos_config_state.dart';

/// Pairs this kiosk with its Izify POS (EcoPay terminal running PayPOS) and
/// keeps watching that the terminal can charge.
///
/// The backend device configuration (`ipEcopay`, `pin`, `ecopayConfig`) is
/// the source of truth: the kiosk pairs on its own at startup, pairs again
/// when the terminal forgets it (unpaired or reinstalled) and moves to a new
/// address when the backend's changes.
class PosConfigBloc extends Cubit<PosConfigState> {
  final AuthBloc authBloc;
  final IzifyPosClient _client;
  nsd.Discovery? _discovery;
  Timer? _healthTimer;
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasAttemptedAutoPair = false;
  bool _savedStateLoaded = false;
  DateTime? _lastAutoRepair;

  static const Duration healthInterval = Duration(seconds: 30);
  static const Duration autoRepairBackoff = Duration(minutes: 2);

  PosConfigBloc(this.authBloc, {IzifyPosClient? client})
      : _client = client ?? IzifyPosClient(),
        super(PosConfigState.init()) {
    _loadSavedState();
    _authSubscription = authBloc.stream.listen((_) => _syncWithBackend());
  }

  Future<void> _loadSavedState() async {
    final saved = IzifyPosAddress.tryParse(await TokenUtils.getPosIp());
    if (saved != null) {
      final device = _deviceFor(saved);
      emit(state.copyWith(
        status: PosConfigStatus.pairedLoaded,
        pairedDevice: device,
        isHealthy: false, // Updated by the first health check.
      ));
      _startHealthPolling(device);
    }
    _savedStateLoaded = true;
    await _syncWithBackend();
  }

  /// Pairs with the terminal the backend assigns to this kiosk when there is
  /// none yet, or when the backend now points somewhere else.
  Future<void> _syncWithBackend() async {
    // Wait for the stored pairing first, or a kiosk already paired with the
    // backend's terminal would pair again on every launch.
    if (!_savedStateLoaded || _hasAttemptedAutoPair || state.status == PosConfigStatus.pairing) return;
    final backend =
        IzifyPosAddress.tryParse(authBloc.state.currentDevice?.config.ipEcopay);
    if (backend == null) return;
    final current = state.pairedDevice;
    if (current != null && current.ip == backend.host && current.port == backend.port) {
      _hasAttemptedAutoPair = true;
      return;
    }
    _hasAttemptedAutoPair = true;
    await pairDevice(_deviceFor(backend));
  }

  PosDevice _deviceFor(IzifyPosAddress address) =>
      PosDevice(name: "POS (${address.host})", ip: address.host, port: address.port);

  Future<void> beginDiscovery() async {
    emit(
      state.copyWith(
        status: PosConfigStatus.discovering,
        discoveredDevices: [],
      ),
    );
    List<PosDevice> devices = [];

    // 1. A PayPOS running on this same device.
    try {
      await _client.health(const IzifyPosAddress('127.0.0.1'));
      devices.add(const PosDevice(name: "Local POS", ip: "127.0.0.1", port: 8081));
    } catch (_) {}

    if (!isClosed) {
      emit(state.copyWith(discoveredDevices: List.from(devices)));
    }

    // 2. mDNS (native platforms only).
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
        // ignore: avoid_print
        print("mDNS discovery unavailable: $e");
      }
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

  /// Pairs with the terminal typed by the technician: `ip` or `ip:port`.
  Future<void> pairManually(String ip, {int? port, String? mqttClientId, String? mqttUserName, String? mqttPassword, String? commerceId, String? cajaId}) async {
    final address = IzifyPosAddress.tryParse(ip);
    if (address == null) return;
    await pairDevice(
      _deviceFor(port != null ? IzifyPosAddress(address.host, port) : address),
      mqttClientId: mqttClientId,
      mqttUserName: mqttUserName,
      mqttPassword: mqttPassword,
      commerceId: commerceId,
      cajaId: cajaId,
    );
  }

  Future<void> pairDevice(PosDevice device, {String? mqttClientId, String? mqttUserName, String? mqttPassword, String? commerceId, String? cajaId}) async {
    emit(state.copyWith(status: PosConfigStatus.pairing));
    try {
      final session = await IzifyPosSession.pair(
        _client,
        authBloc.state.currentDevice,
        IzifyPosAddress(device.ip, device.port),
        overrides: {
          'mqttClientId': mqttClientId,
          'mqttUserName': mqttUserName,
          'mqttPassword': mqttPassword,
          'commerceId': commerceId,
          'cajaId': cajaId,
        },
      );
      final paired = _deviceFor(session.address);
      if (isClosed) return;
      emit(state.copyWith(
        status: PosConfigStatus.paired,
        pairedDevice: paired,
        isHealthy: true,
      ));
      _startHealthPolling(paired);
    } on IzifyPosException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(status: PosConfigStatus.error, errorMessage: e.message));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
            status: PosConfigStatus.error,
            errorMessage: 'No se pudo emparejar el datáfono: $e'));
      }
    }
  }

  void _startHealthPolling(PosDevice device) {
    _healthTimer?.cancel();
    checkHealth(); // Run immediately
    _healthTimer = Timer.periodic(healthInterval, (_) => checkHealth());
  }

  /// Refreshes the terminal's readiness, re-pairing when it forgot us.
  Future<void> checkHealth() async {
    final device = state.pairedDevice;
    if (device == null) return;
    final address = IzifyPosAddress(device.ip, device.port);
    try {
      var health = await _client.health(address);
      if (health.paired == false && _mayAutoRepair()) {
        _lastAutoRepair = DateTime.now();
        try {
          await IzifyPosSession.pair(_client, authBloc.state.currentDevice, address);
          health = await _client.health(address);
        } catch (_) {
          // Keep reporting the terminal as not ready; the reason says why.
        }
      }
      if (isClosed) return;
      emit(state.copyWith(
        isHealthy: health.notReadyReason == null,
        healthData: health.raw,
        health: () => health,
        notReadyReason: () => health.notReadyReason,
      ));
    } on IzifyPosException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isHealthy: false,
        health: () => null,
        notReadyReason: () => e.message,
      ));
    }
  }

  bool _mayAutoRepair() {
    final last = _lastAutoRepair;
    return last == null || DateTime.now().difference(last) > autoRepairBackoff;
  }

  Future<void> unpair() async {
    final device = state.pairedDevice;
    if (device != null) {
      String? token = await TokenUtils.getPosToken();
      token ??= authBloc.state.currentDevice?.config.token;
      if (token != null) {
        await _client.unpair(IzifyPosAddress(device.ip, device.port), token);
      }
    }

    await IzifyPosSession.forget();
    _healthTimer?.cancel();
    // A deliberate unpair must not be undone by the startup auto-pair.
    _hasAttemptedAutoPair = true;
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
