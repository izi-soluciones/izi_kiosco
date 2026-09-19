import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_discovery.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

part 'pos_config_state.dart';

/// Pairs this kiosk with its Izify POS (EcoPay terminal running PayPOS) and
/// keeps the connection alive.
///
/// The backend device configuration (`ipEcopay`, `pin`, `ecopayConfig`) is
/// the source of truth for the first pairing. From then on the kiosk
/// reconnects on its own, at startup and whenever the terminal stops
/// answering:
/// - the terminal forgot the pairing (reinstalled, unpaired, data cleared):
///   pair again with the backend PIN;
/// - the terminal answers but rejects the kiosk token: pair again;
/// - the terminal no longer answers at its address (the router gave it a new
///   IP): find it on the LAN by its name and move there.
class PosConfigBloc extends Cubit<PosConfigState> {
  final AuthBloc authBloc;
  final IzifyPosClient _client;
  final IzifyPosDiscovery _discovery;
  StreamSubscription<List<DiscoveredPos>>? _discoverySub;
  Timer? _discoveryTimeout;
  Timer? _healthTimer;
  StreamSubscription<AuthState>? _authSubscription;
  bool _savedStateLoaded = false;
  bool _autoPairDisabled = false;
  final Set<IzifyPosAddress> _backendAttempts = {};
  bool _reconnecting = false;

  /// A re-pair is due but the device configuration (with its PIN) has not
  /// loaded yet; retried as soon as it does.
  bool _repairPending = false;
  DateTime? _lastAutoRepair;
  DateTime? _lastRediscovery;
  int _failedChecks = 0;

  static const Duration healthInterval = Duration(seconds: 30);
  static const Duration autoRepairBackoff = Duration(minutes: 2);
  static const Duration rediscoveryBackoff = Duration(minutes: 3);
  static const Duration discoveryDuration = Duration(seconds: 45);

  /// Health checks that must fail in a row before looking for the terminal
  /// elsewhere: one miss is usually a Wi-Fi hiccup.
  static const int failuresBeforeRediscovery = 2;

  /// How long to look for the terminal on the LAN when it stopped
  /// answering at its address.
  final Duration rediscoveryTimeout;

  PosConfigBloc(this.authBloc,
      {IzifyPosClient? client,
      IzifyPosDiscovery? discovery,
      this.rediscoveryTimeout = const Duration(seconds: 12)})
      : _client = client ?? IzifyPosClient(),
        _discovery = discovery ?? IzifyPosDiscovery(client: client),
        super(PosConfigState.init()) {
    _authSubscription = authBloc.stream.listen((_) => _onAuthChanged());
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final saved = IzifyPosAddress.tryParse(await TokenUtils.getPosIp());
    if (saved != null && !isClosed) {
      emit(state.copyWith(
        status: PosConfigStatus.pairedLoaded,
        pairedDevice: _deviceFor(saved),
        isHealthy: false, // Updated by the reconnection below.
      ));
    }
    _savedStateLoaded = true;
    await _syncWithBackend();
    if (state.pairedDevice != null && state.status != PosConfigStatus.pairing) {
      await reconnect(manual: true);
    }
  }

  Future<void> _onAuthChanged() async {
    await _syncWithBackend();
    final pin = authBloc.state.currentDevice?.config.pin;
    if (_repairPending && pin != null && pin.trim().isNotEmpty) {
      _repairPending = false;
      await reconnect(manual: true);
    }
  }

  /// Pairs with the terminal the backend assigns to this kiosk when there is
  /// none yet, or when the backend value changed since the kiosk last paired.
  Future<void> _syncWithBackend() async {
    // Wait for the stored pairing first, or a kiosk already paired with the
    // backend's terminal would pair again on every launch.
    if (!_savedStateLoaded || _autoPairDisabled || state.status == PosConfigStatus.pairing) return;
    final backend =
        IzifyPosAddress.tryParse(authBloc.state.currentDevice?.config.ipEcopay);
    if (backend == null) return;
    final current = state.pairedDevice;
    if (current != null && current.ip == backend.host && current.port == backend.port) return;
    // Already paired while the backend said this: the kiosk has since found
    // the terminal elsewhere (new IP) or been paired by hand. Only a new
    // backend value moves it.
    if (current != null &&
        IzifyPosAddress.tryParse(await TokenUtils.getPosBackendIp()) == backend) {
      return;
    }
    if (!_backendAttempts.add(backend)) return; // Once per launch and value.
    await pairDevice(_deviceFor(backend));
  }

  PosDevice _deviceFor(IzifyPosAddress address) =>
      PosDevice(name: "POS (${address.host})", ip: address.host, port: address.port);

  String? get _myKioskHash {
    final device = authBloc.state.currentDevice;
    return device == null ? null : IzifyPosClient.kioskHash(IzifyPosSession.kioskIdOf(device));
  }

  /// Lists the terminals on the LAN for the technician, for
  /// [discoveryDuration] or until [endDiscovery].
  Future<void> beginDiscovery() async {
    await _stopDiscovery();
    emit(state.copyWith(status: PosConfigStatus.discovering, discoveredDevices: []));
    final myHash = _myKioskHash;
    _discoverySub = _discovery.watch().listen((found) {
      if (isClosed) return;
      emit(state.copyWith(discoveredDevices: [
        for (final pos in found)
          PosDevice(
            name: pos.name,
            ip: pos.address.host,
            port: pos.address.port,
            pairing: pos.health.paired == false
                ? PosPairing.free
                : (myHash != null && pos.health.pairedKioskHash == myHash)
                    ? PosPairing.thisKiosk
                    : pos.health.paired == true
                        ? PosPairing.otherKiosk
                        : PosPairing.unknown,
            version: pos.health.appVersion,
          ),
      ]));
    });
    _discoveryTimeout = Timer(discoveryDuration, endDiscovery);
  }

  Future<void> endDiscovery() async {
    await _stopDiscovery();
    if (!isClosed && state.status == PosConfigStatus.discovering) {
      emit(state.copyWith(status: PosConfigStatus.idle));
    }
  }

  Future<void> _stopDiscovery() async {
    _discoveryTimeout?.cancel();
    _discoveryTimeout = null;
    final sub = _discoverySub;
    _discoverySub = null;
    await sub?.cancel();
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
    await _stopDiscovery();
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
      await _acknowledgeBackend();
      _autoPairDisabled = false;
      final paired = _deviceFor(session.address);
      if (isClosed) return;
      emit(state.copyWith(
        status: PosConfigStatus.paired,
        pairedDevice: paired,
        isHealthy: true,
      ));
      _startHealthPolling();
      unawaited(checkHealth());
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

  /// Records the backend `ipEcopay` in force when the kiosk paired, so that
  /// only a later change of it moves the kiosk to another terminal.
  Future<void> _acknowledgeBackend() async {
    final backend = IzifyPosAddress.tryParse(authBloc.state.currentDevice?.config.ipEcopay);
    if (backend != null) await TokenUtils.savePosBackendIp(backend.hostPort);
  }

  void _startHealthPolling() {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(healthInterval, (_) => checkHealth());
  }

  /// Makes sure the paired terminal answers and still accepts this kiosk,
  /// fixing what it can: pairs again when the terminal forgot the kiosk or
  /// rejects its token, and follows the terminal to a new IP.
  ///
  /// [manual] (startup, the "Verificar ahora" button, the device settings
  /// arriving) skips the backoffs that keep the periodic check from
  /// hammering a terminal that is down.
  Future<void> reconnect({bool manual = false}) async {
    final device = state.pairedDevice;
    if (device == null || _reconnecting || state.status == PosConfigStatus.pairing) return;
    _reconnecting = true;
    try {
      var address = IzifyPosAddress(device.ip, device.port);
      IzifyPosHealth? health;
      String? unreachable;
      try {
        health = await _client.health(address);
      } on IzifyPosException catch (e) {
        unreachable = e.message;
      }

      if (health == null && (manual || _mayRediscover())) {
        if (!isClosed) {
          emit(state.copyWith(
            isHealthy: false,
            notReadyReason: () => 'El datáfono no responde en ${address.host}. Buscándolo en la red...',
          ));
        }
        final found = await _findPairedTerminal();
        if (found != null && found.address != address) {
          address = found.address;
          health = found.health;
          await IzifyPosSession.moveTo(address);
          if (!isClosed) emit(state.copyWith(pairedDevice: _deviceFor(address)));
        }
      }

      if (health == null) {
        _report(null, unreachable ?? 'El datáfono no responde.');
        return;
      }
      _failedChecks = 0;
      final problem = await _ensurePaired(address, health, manual: manual);
      if (problem.health != null) health = problem.health!;
      _report(health, problem.reason);
    } finally {
      _reconnecting = false;
      if (_healthTimer == null && !isClosed) _startHealthPolling();
    }
  }

  /// Refreshes the terminal's readiness every [healthInterval]. Hands over
  /// to [reconnect] when the terminal forgot the kiosk or stopped answering.
  Future<void> checkHealth() async {
    final device = state.pairedDevice;
    if (device == null || _reconnecting) return;
    final address = IzifyPosAddress(device.ip, device.port);
    try {
      var health = await _client.health(address);
      _failedChecks = 0;
      String? reason;
      if (health.paired == false || _repairPending || _pairedElsewhere(health)) {
        final result = await _ensurePaired(address, health);
        health = result.health ?? health;
        reason = result.reason;
      }
      _report(health, reason);
    } on IzifyPosException catch (e) {
      _failedChecks++;
      _report(null, e.message);
      if (_failedChecks >= failuresBeforeRediscovery && _mayRediscover()) {
        unawaited(reconnect());
      }
    }
  }

  bool _pairedElsewhere(IzifyPosHealth health) {
    final mine = _myKioskHash;
    final theirs = health.pairedKioskHash;
    return health.paired == true && mine != null && theirs != null && theirs != mine;
  }

  /// Pairs again when the terminal at [address] no longer accepts this
  /// kiosk. Returns the fresh health after pairing, and why the terminal is
  /// still not usable when it could not be fixed.
  Future<({IzifyPosHealth? health, String? reason})> _ensurePaired(
      IzifyPosAddress address, IzifyPosHealth health,
      {bool manual = false}) async {
    var needsPair = health.paired == false;
    if (!needsPair) {
      if (_pairedElsewhere(health)) {
        needsPair = true;
      } else {
        final token = await TokenUtils.getPosToken() ??
            authBloc.state.currentDevice?.config.token;
        if (token != null && token.isNotEmpty) {
          needsPair = await _client.tokenAccepted(address, token) == false;
        }
      }
    }
    if (!needsPair) {
      _repairPending = false;
      await IzifyPosSession.rememberName(_client, address, health: health);
      return (health: null, reason: null);
    }

    final device = authBloc.state.currentDevice;
    final pin = device?.config.pin;
    if (device == null || pin == null || pin.trim().isEmpty) {
      // Retried from _onAuthChanged once the device settings load.
      _repairPending = true;
      return (health: null, reason: 'El datáfono no reconoce a este kiosko. Se volverá a emparejar al cargar la configuración del dispositivo.');
    }
    if (!manual && !_mayAutoRepair()) {
      return (health: null, reason: 'El datáfono no reconoce a este kiosko.');
    }
    _lastAutoRepair = DateTime.now();
    try {
      await IzifyPosSession.pair(_client, device, address);
      _repairPending = false;
      return (health: await _client.health(address), reason: null);
    } on IzifyPosException catch (e) {
      // e.g. 409: the terminal is paired with another kiosk.
      return (health: null, reason: e.message);
    }
  }

  /// Looks on the LAN for the terminal this kiosk is paired with, by the name
  /// stored at pairing or by the kiosk the terminal says it is paired with.
  Future<DiscoveredPos?> _findPairedTerminal() async {
    final name = await TokenUtils.getPosName();
    final hash = _myKioskHash;
    if (name == null && hash == null) return null;
    bool mine(DiscoveredPos pos) =>
        (name != null && pos.health.name == name) ||
        (hash != null && pos.health.pairedKioskHash == hash);
    _lastRediscovery = DateTime.now();
    final found = await _discovery.scan(timeout: rediscoveryTimeout, stopWhen: mine);
    for (final pos in found) {
      if (mine(pos)) return pos;
    }
    return null;
  }

  void _report(IzifyPosHealth? health, String? problem) {
    if (isClosed) return;
    final reason = problem ?? health?.notReadyReason;
    emit(state.copyWith(
      isHealthy: health != null && reason == null,
      healthData: health?.raw,
      health: () => health,
      notReadyReason: () => reason,
    ));
  }

  bool _mayAutoRepair() {
    final last = _lastAutoRepair;
    return last == null || DateTime.now().difference(last) > autoRepairBackoff;
  }

  bool _mayRediscover() {
    final last = _lastRediscovery;
    return last == null || DateTime.now().difference(last) > rediscoveryBackoff;
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
    _healthTimer = null;
    _repairPending = false;
    // A deliberate unpair must not be undone by the automatic pairing.
    _autoPairDisabled = true;
    emit(
      state.copyWith(
        status: PosConfigStatus.idle,
        clearPairedDevice: true,
        isHealthy: false,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    _healthTimer?.cancel();
    await _stopDiscovery();
    return super.close();
  }
}

/// Whether a terminal found on the LAN is free to pair with this kiosk.
enum PosPairing { unknown, free, thisKiosk, otherKiosk }

class PosDevice extends Equatable {
  final String name;
  final String ip;
  final int port;
  final PosPairing pairing;
  final String? version;

  const PosDevice({
    required this.name,
    required this.ip,
    required this.port,
    this.pairing = PosPairing.unknown,
    this.version,
  });

  @override
  List<Object?> get props => [name, ip, port, pairing, version];
}
