import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum MonitoringState {
  /// Not logged in, or no device selected yet: nothing to enroll.
  stopped,

  /// Logged in, the first enrollment has not finished yet.
  pending,

  /// The kiosk holds a device token for the current contribuyente.
  enrolled,

  /// The last enrollment failed; another one is scheduled.
  error,
}

/// What the POS configuration screen shows about monitoring.
class MonitoringStatus {
  final MonitoringState state;

  /// A request to the monitoring service is on its way.
  final bool enrolling;
  final String? deviceId;
  final String? applianceId;

  /// Why the last enrollment failed (see [MonitoringException.cause]).
  final String? lastCause;
  final DateTime? nextAttemptAt;

  /// Enrollments failed in a row.
  final int failures;

  const MonitoringStatus(
      {required this.state,
      this.enrolling = false,
      this.deviceId,
      this.applianceId,
      this.lastCause,
      this.nextAttemptAt,
      this.failures = 0});

  static const MonitoringStatus stopped = MonitoringStatus(state: MonitoringState.stopped);
}

/// The iZi identity this kiosk enrolls under, and the names that make it
/// readable in the support console.
class MonitoringContext {
  final int contribuyenteId;

  /// The iZi device (`dispositivo`) the kiosk runs as.
  final int dispositivoId;
  final String? deviceName;
  final String? contribuyenteNombre;
  final String? sucursalNombre;

  /// `BO`, `CO`...
  final String? pais;

  const MonitoringContext(
      {required this.contribuyenteId,
      required this.dispositivoId,
      this.deviceName,
      this.contribuyenteNombre,
      this.sucursalNombre,
      this.pais});

  /// Null until the kiosk is logged in with its device loaded.
  static MonitoringContext? fromAuth(AuthState state) {
    final device = state.currentDevice;
    final contribuyente = state.currentContribuyente;
    final contribuyenteId = contribuyente?.id;
    if (state.status != AuthStatus.okAuth || device == null || contribuyenteId == null) {
      return null;
    }
    final config = contribuyente?.config;
    final paisId = config is Map ? config['paisId'] : null;
    return MonitoringContext(
      contribuyenteId: contribuyenteId,
      dispositivoId: device.id,
      deviceName: device.nombre,
      contribuyenteNombre: _firstPresent(contribuyente?.nombre, contribuyente?.razonSocial),
      sucursalNombre: _firstPresent(state.currentSucursal?.nombre, device.sucursalName),
      pais: _firstPresent(paisId is String ? paisId : null, state.taxesStrategy.countryCode),
    );
  }

  bool sameIdentity(MonitoringContext other) =>
      contribuyenteId == other.contribuyenteId && dispositivoId == other.dispositivoId;

  static String? _firstPresent(String? a, String? b) =>
      a != null && a.trim().isNotEmpty ? a : (b != null && b.trim().isNotEmpty ? b : null);
}

/// Schedules [callback] after [delay]. [Timer.new] in production.
typedef MonitoringTimerFactory = Timer Function(Duration delay, void Function() callback);

/// Enrolls this kiosk in the iZi monitoring service (contracts §3.1) and
/// keeps its device token.
///
/// Runs while the kiosk is logged in with its device loaded ([followAuth]),
/// enrolls when it has no token for the current contribuyente and device,
/// and retries with exponential backoff ([initialBackoff] → [maxBackoff],
/// each wait shortened by up to [jitter] so a fleet that saw the same outage
/// does not come back in lockstep) when the service cannot be reached. Nothing here is awaited by the UI
/// and nothing throws out of it: monitoring must never get in the way of a
/// sale.
class MonitoringService {
  static const Duration initialBackoff = Duration(seconds: 30);
  static const Duration maxBackoff = Duration(minutes: 30);

  /// The share of each backoff wait that is random.
  static const double jitter = 0.2;

  /// Lets the requests of the login (catalog, currencies, video) go first.
  static const Duration firstAttemptDelay = Duration(seconds: 5);

  /// A last guard over the repository's own timeouts: an attempt that never
  /// ends would stop the retries.
  static const Duration attemptTimeout = Duration(seconds: 45);

  final MonitoringRepository? _injectedRepository;
  final MonitoringStore store;
  final Future<MonitoringApp> Function() _appInfo;
  final MonitoringTimerFactory _timer;
  final DateTime Function() _now;
  final Random _random;
  final ValueNotifier<MonitoringStatus> _status = ValueNotifier(MonitoringStatus.stopped);

  // Created on first use: DioClient reads the API URL from the loaded `.env`.
  late final MonitoringRepository _repository =
      _injectedRepository ?? MonitoringRepositoryHttp();

  MonitoringContext? _context;
  bool _running = false;
  String? _deviceToken;
  Timer? _retryTimer;
  int _failures = 0;

  /// Bumped by [start] with a new identity and by [stop]: an attempt started
  /// under an older value must not act on its result.
  int _epoch = 0;
  int? _inFlightEpoch;
  StreamSubscription<AuthState>? _authSub;

  MonitoringService(
      {MonitoringRepository? repository,
      MonitoringStore? store,
      String flavor = 'local',
      Future<MonitoringApp> Function()? appInfo,
      MonitoringTimerFactory? timer,
      DateTime Function()? now,
      Random? random})
      : _injectedRepository = repository,
        store = store ?? MonitoringStore(),
        _appInfo = appInfo ?? _memo(() => currentApp(flavor)),
        _timer = timer ?? Timer.new,
        _now = now ?? DateTime.now,
        _random = random ?? Random();

  static MonitoringService _instance = MonitoringService();

  static MonitoringService get instance => _instance;

  /// Replaces the global instance (at startup, and in tests).
  static void install(MonitoringService service) => _instance = service;

  ValueListenable<MonitoringStatus> get status => _status;

  /// The token to present as `X-Device-Token`, while enrolled.
  String? get deviceToken => _running ? _deviceToken : null;

  /// Starts and stops with the login: running while the kiosk is logged in
  /// with its device loaded, stopped once it logs out.
  void followAuth(AuthBloc auth) {
    _authSub?.cancel();
    _applyAuth(auth.state);
    _authSub = auth.stream.listen(_applyAuth);
  }

  void _applyAuth(AuthState state) {
    final context = MonitoringContext.fromAuth(state);
    if (context != null) {
      unawaited(start(context));
    } else if (state.status == AuthStatus.noAuth ||
        state.status == AuthStatus.firstContribuyente) {
      stop();
    }
    // init, waitingChange, errorAuth: passing states, the last one stands.
  }

  /// Uses the stored token when it was issued for [context]'s contribuyente
  /// and device; otherwise enrolls (again).
  Future<void> start(MonitoringContext context) async {
    try {
      final previous = _context;
      _context = context;
      if (_running && previous != null && previous.sameIdentity(context)) return;
      _cancelRetry();
      _running = true;
      _failures = 0;
      _deviceToken = null;
      final epoch = ++_epoch;
      _set(const MonitoringStatus(state: MonitoringState.pending));
      final saved = await store.enrollment();
      if (epoch != _epoch) return;
      if (saved != null &&
          saved.isFor(contribuyenteId: context.contribuyenteId, dispositivoId: context.dispositivoId)) {
        _deviceToken = saved.deviceToken;
        _set(MonitoringStatus(
            state: MonitoringState.enrolled,
            deviceId: saved.deviceId,
            applianceId: saved.applianceId));
        Telemetry.setContext({'monitoring.deviceId': saved.deviceId});
        return;
      }
      if (saved != null) await store.clearEnrollment();
      if (epoch != _epoch) return;
      _retryTimer = _timer(firstAttemptDelay, () => unawaited(_attempt(epoch)));
    } catch (_) {}
  }

  /// Logged out: no more requests. The stored token stays, for when the
  /// kiosk logs in again to the same contribuyente.
  void stop() {
    if (!_running && _status.value.state == MonitoringState.stopped) return;
    _epoch++;
    _cancelRetry();
    _running = false;
    _context = null;
    _deviceToken = null;
    _failures = 0;
    _set(MonitoringStatus.stopped);
    Telemetry.setContext({'monitoring.deviceId': null});
  }

  /// "Reintentar enrolamiento" on the configuration screen: enrolls now,
  /// even when already enrolled (the service then issues a new token and
  /// revokes the old one).
  Future<void> retryNow() async {
    if (!_running || _inFlightEpoch == _epoch) return;
    _cancelRetry();
    _failures = 0;
    await _attempt(_epoch, manual: true);
  }

  /// The service rejected [rejectedToken] (`device_token_invalid`): forget
  /// it and enroll again.
  ///
  /// Only when it is still the current token: a request sent with a token
  /// that a manual retry or a re-enrollment already replaced must not wipe
  /// the new one, nor revoke it with yet another enrollment. While an
  /// enrollment is on its way it is left to replace the token.
  Future<void> onTokenRejected(String rejectedToken) async {
    if (!_running || _deviceToken == null || rejectedToken != _deviceToken) return;
    if (_inFlightEpoch == _epoch) return;
    _deviceToken = null;
    await store.clearEnrollment(onlyToken: rejectedToken);
    if (!_running || _deviceToken != null || _inFlightEpoch == _epoch) return;
    _cancelRetry();
    _failures = 0;
    _set(const MonitoringStatus(state: MonitoringState.pending));
    await _attempt(_epoch);
  }

  Future<void> _attempt(int epoch, {bool manual = false}) async {
    final context = _context;
    if (epoch != _epoch || !_running || context == null || _inFlightEpoch == epoch) return;
    _inFlightEpoch = epoch;
    final reenroll = _status.value.state == MonitoringState.enrolled;
    _set(MonitoringStatus(
        state: _status.value.state,
        enrolling: true,
        deviceId: _status.value.deviceId,
        applianceId: _status.value.applianceId,
        lastCause: _status.value.lastCause,
        failures: _failures));
    try {
      final dto = MonitoringEnrollmentDto(
        installationId: await store.installationId(),
        app: await _appInfo(),
        deviceName: context.deviceName,
        contribuyenteNombre: context.contribuyenteNombre,
        sucursalNombre: context.sucursalNombre,
        pais: context.pais,
      );
      final enrollment = await _repository.enroll(dto).timeout(attemptTimeout);
      if (epoch != _epoch) return;
      await store.saveEnrollment(MonitoringEnrollmentRecord(
        deviceToken: enrollment.deviceToken,
        deviceId: enrollment.deviceId,
        applianceId: enrollment.applianceId,
        contribuyenteId: context.contribuyenteId,
        dispositivoId: context.dispositivoId,
      ));
      if (epoch != _epoch) return;
      _deviceToken = enrollment.deviceToken;
      final attempts = _failures + 1;
      _failures = 0;
      _set(MonitoringStatus(
          state: MonitoringState.enrolled,
          deviceId: enrollment.deviceId,
          applianceId: enrollment.applianceId));
      Telemetry.event('monitoring.enrolled', data: {
        'deviceId': enrollment.deviceId,
        'applianceId': enrollment.applianceId,
        'attempts': attempts,
        'reenroll': reenroll,
        'manual': manual,
      });
      Telemetry.setContext({'monitoring.deviceId': enrollment.deviceId});
    } catch (error) {
      if (epoch != _epoch) return;
      _failures++;
      final delay = retryDelayFor(_failures, _random.nextDouble());
      final cause = switch (error) {
        MonitoringException e => e.cause,
        TimeoutException _ => 'timeout',
        _ => 'error',
      };
      _set(MonitoringStatus(
          state: MonitoringState.error,
          deviceId: _status.value.deviceId,
          applianceId: _status.value.applianceId,
          lastCause: cause,
          nextAttemptAt: _now().add(delay),
          failures: _failures));
      Telemetry.event('monitoring.enroll_failed',
          level: TelemetryLevel.warning,
          data: {
            'cause': cause,
            if (error is MonitoringException && error.code != null) 'code': error.code,
            'attempt': _failures,
            'retryInSec': delay.inSeconds,
            'manual': manual,
          });
      _cancelRetry();
      _retryTimer = _timer(delay, () => unawaited(_attempt(epoch)));
    } finally {
      if (_inFlightEpoch == epoch) _inFlightEpoch = null;
    }
  }

  /// 30 s after the first failure, doubling up to 30 min.
  static Duration backoffFor(int failures) {
    if (failures <= 1) return initialBackoff;
    final seconds = initialBackoff.inSeconds * pow(2, min(failures - 1, 16));
    return Duration(seconds: min(seconds.toInt(), maxBackoff.inSeconds));
  }

  /// The wait before the next attempt: [backoffFor] shortened by up to
  /// [jitter], for [random] in [0, 1), and kept within [initialBackoff] and
  /// [maxBackoff].
  static Duration retryDelayFor(int failures, double random) {
    final base = backoffFor(failures).inMilliseconds;
    final jittered = (base * (1 - jitter * random.clamp(0.0, 1.0))).round();
    return Duration(
        milliseconds: jittered.clamp(initialBackoff.inMilliseconds, maxBackoff.inMilliseconds));
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _set(MonitoringStatus status) {
    try {
      _status.value = status;
    } catch (_) {}
  }

  /// This build, as the contracts name it.
  static Future<MonitoringApp> currentApp(String flavor) async {
    String? version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.buildNumber.isEmpty ? info.version : '${info.version}+${info.buildNumber}';
    } catch (_) {}
    return MonitoringApp(
        version: version,
        flavor: flavor,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase());
  }

  static Future<T> Function() _memo<T>(Future<T> Function() compute) {
    Future<T>? result;
    return () => result ??= compute();
  }
}
