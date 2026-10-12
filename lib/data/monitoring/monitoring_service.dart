import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_backoff.dart';
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
/// each wait moved by up to [jitter] either way so a fleet that saw the same
/// outage does not come back in lockstep, [MonitoringBackoff]) when the
/// service cannot be reached. A contribuyente blocked for non-payment (the
/// gateway's `401 {"bloqueadoPago":true}`, contracts §12.1) is one more such
/// failure: it ends when the payment does. Nothing here is awaited by the UI
/// and nothing throws out of it: monitoring must never get in the way of a
/// sale.
class MonitoringService {
  static const Duration initialBackoff = Duration(seconds: 30);
  static const Duration maxBackoff = Duration(minutes: 30);

  /// The share of each backoff wait that is random, either way.
  static const double jitter = MonitoringBackoff.jitter;

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

  /// Tokens the service rejected in a row, with no heartbeat accepted in
  /// between ([onTokenAccepted]). A fresh token that is rejected again (two
  /// kiosk PCs cloned with the same installationId revoking each other's
  /// token, or a service that cannot verify the tokens it issues) must not
  /// turn into an enrollment on every heartbeat.
  int _tokenRejections = 0;

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
      _tokenRejections = 0;
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
    _tokenRejections = 0;
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
  ///
  /// The first rejection enrolls now (a token revoked from the console, or
  /// one the service lost). When the new token is rejected too, before any
  /// heartbeat was accepted with it, the next enrollment waits with the same
  /// backoff as a failed one ([retryDelayFor]: 30 s doubling up to 30 min);
  /// nothing is sent in the meantime.
  Future<void> onTokenRejected(String rejectedToken) async {
    if (!_running || _deviceToken == null || rejectedToken != _deviceToken) return;
    if (_inFlightEpoch == _epoch) return;
    _deviceToken = null;
    _tokenRejections++;
    await store.clearEnrollment(onlyToken: rejectedToken);
    if (!_running || _deviceToken != null || _inFlightEpoch == _epoch) return;
    _cancelRetry();
    _failures = 0;
    if (_tokenRejections <= 1) {
      _set(const MonitoringStatus(state: MonitoringState.pending));
      await _attempt(_epoch);
      return;
    }
    final epoch = _epoch;
    final delay = retryDelayFor(_tokenRejections - 1, _random.nextDouble());
    _set(MonitoringStatus(
        state: MonitoringState.error,
        deviceId: _status.value.deviceId,
        applianceId: _status.value.applianceId,
        lastCause: MonitoringException.deviceTokenInvalid,
        nextAttemptAt: _now().add(delay),
        failures: _tokenRejections));
    Telemetry.event('monitoring.reenroll_delayed',
        level: TelemetryLevel.warning,
        data: {'rejections': _tokenRejections, 'retryInSec': delay.inSeconds});
    _retryTimer = _timer(delay, () => unawaited(_attempt(epoch)));
  }

  /// A device token the service sends with `rotate_token` (contracts
  /// §12.5): `izd_` and 16 to 128 base64url characters.
  static final RegExp rotatedTokenFormat = RegExp(r'^izd_[A-Za-z0-9_-]{16,128}$');

  /// `rotate_token` with the new token in its args (contracts §12.5): keeps
  /// [token] in place of the current one, stored first, so the result is
  /// confirmed with it. The service revokes the old one only then.
  ///
  /// False when there is nothing to rotate (logged out, enrolling, or a
  /// [token] that is not a device token); the current token stays.
  Future<bool> adoptRotatedToken(String token) async {
    try {
      final context = _context;
      final current = _deviceToken;
      if (!_running || context == null || current == null) return false;
      if (_inFlightEpoch == _epoch || !rotatedTokenFormat.hasMatch(token)) return false;
      if (token == current) return true;
      final epoch = _epoch;
      final status = _status.value;
      await store.saveEnrollment(MonitoringEnrollmentRecord(
        deviceToken: token,
        deviceId: status.deviceId,
        applianceId: status.applianceId,
        contribuyenteId: context.contribuyenteId,
        dispositivoId: context.dispositivoId,
      ));
      if (epoch != _epoch || !_running || _deviceToken != current) return false;
      _deviceToken = token;
      _tokenRejections = 0;
      _set(MonitoringStatus(
          state: MonitoringState.enrolled,
          deviceId: status.deviceId,
          applianceId: status.applianceId));
      Telemetry.event('monitoring.token_rotated', data: {'via': 'command'});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// `rotate_token` without a token in its args: enrolls again, which gets
  /// a new token and revokes the old one. Returns the new token, or null
  /// when that enrollment failed (it is then retried with backoff).
  Future<String?> reenroll() async {
    final before = _deviceToken;
    await retryNow();
    final after = deviceToken;
    return after != null && after != before ? after : null;
  }

  /// The service accepted a heartbeat sent with [token]: it works, so the
  /// next rejection enrolls again right away.
  void onTokenAccepted(String token) {
    if (token == _deviceToken) _tokenRejections = 0;
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
  static Duration backoffFor(int failures) =>
      MonitoringBackoff.base(first: initialBackoff, max: maxBackoff, failures: failures);

  /// The wait before the next attempt: [backoffFor] moved by up to [jitter]
  /// either way, for [random] in [0, 1) (0.5 leaves it as is), and kept
  /// within [initialBackoff] and [maxBackoff].
  static Duration retryDelayFor(int failures, double random) => MonitoringBackoff.delay(
      first: initialBackoff, max: maxBackoff, failures: failures, random: random);

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
