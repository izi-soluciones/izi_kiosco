import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_collector.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_commands.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_heartbeat_dto.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';

/// What the diagnostics dialog shows about the heartbeat.
class HeartbeatStatus {
  /// The kiosk is enrolled and sending.
  final bool running;
  final DateTime? lastOkAt;
  final DateTime? nextAt;

  /// Why the last heartbeat failed, while they keep failing.
  final String? lastCause;

  /// Heartbeats failed in a row.
  final int failures;
  final int? ackSeq;
  final Duration interval;

  const HeartbeatStatus(
      {required this.running,
      this.lastOkAt,
      this.nextAt,
      this.lastCause,
      this.failures = 0,
      this.ackSeq,
      this.interval = MonitoringHeartbeat.defaultInterval});

  static const HeartbeatStatus stopped = HeartbeatStatus(running: false);
}

/// Sends this kiosk's heartbeat to the monitoring service (contracts §4)
/// while it is enrolled ([MonitoringService]).
///
/// Every [interval] — 60 s, or what the service asks for in `nextInSec`
/// within [minInterval] and [maxInterval] — it posts the
/// [KioskHealthSnapshot] and the [KioskCounters], with the device token.
/// A heartbeat that fails is retried later with backoff (up to
/// [maxBackoff]); the counters keep growing in the same window until one is
/// accepted. A token the service rejects (`device_token_invalid`) is handed
/// back to [MonitoringService], which forgets it and enrolls again (with
/// backoff when the new tokens keep being rejected); sending resumes with the
/// new one.
///
/// Fail-safe like the enrollment: nothing here is awaited by the UI, nothing
/// throws out of it, and building the heartbeat reads only what the kiosk
/// already knows. It never calls the terminal, so it cannot compete with a
/// charge.
class MonitoringHeartbeat {
  static const Duration defaultInterval = Duration(seconds: 60);
  static const Duration minInterval = Duration(seconds: 10);
  static const Duration maxInterval = Duration(minutes: 10);
  static const Duration maxBackoff = Duration(minutes: 5);

  /// After enrolling (or starting with a stored token): lets the health
  /// loops check the terminal once before the first report.
  static const Duration firstBeatDelay = Duration(seconds: 5);

  /// A last guard over the repository's own timeouts, as in the enrollment.
  static const Duration attemptTimeout = Duration(seconds: 45);
  static const Duration collectTimeout = Duration(seconds: 10);

  /// The share of each backoff wait that is random.
  static const double jitter = 0.2;

  /// Failures in a row recorded in detail; after that, one in [logEvery].
  static const int detailedFailures = 3;
  static const int logEvery = 10;

  final MonitoringService _enrollment;
  final MonitoringRepository? _injectedRepository;
  final KioskHealthCollector Function() _collector;
  final KioskCounters Function() _counters;
  final MonitoringCommandQueue commands;
  final Future<MonitoringApp> Function() _appInfo;
  final MonitoringTimerFactory _timer;
  final DateTime Function() _now;
  final Random _random;
  final Stopwatch _uptime = Stopwatch()..start();
  final ValueNotifier<HeartbeatStatus> _status = ValueNotifier(HeartbeatStatus.stopped);

  /// Changes on every app start.
  final String bootId = MonitoringStore.newUuidV4();

  /// The last event `seq` recorded, filled by the event upload (KIO-03).
  int? Function() lastEventSeq = _unknown;

  // Created on first use: the HTTP client reads the API URL from the `.env`.
  late final MonitoringRepository _repository =
      _injectedRepository ?? MonitoringRepositoryHttp();

  bool _started = false;
  bool _inFlight = false;
  String? _token;
  Timer? _next;
  Duration _interval = defaultInterval;
  int _failures = 0;
  int? _ackSeq;
  DateTime? _lastOkAt;
  String? _lastCause;

  MonitoringHeartbeat(
      {required MonitoringService enrollment,
      MonitoringRepository? repository,
      KioskHealthCollector Function()? collector,
      KioskCounters Function()? counters,
      MonitoringCommandQueue? commands,
      String flavor = 'local',
      Future<MonitoringApp> Function()? appInfo,
      MonitoringTimerFactory? timer,
      DateTime Function()? now,
      Random? random})
      : _enrollment = enrollment,
        _injectedRepository = repository,
        _collector = collector ?? (() => KioskHealthCollector.instance),
        _counters = counters ?? (() => KioskCounters.instance),
        commands = commands ?? PendingCommandQueue(),
        _appInfo = appInfo ?? _memo(() => MonitoringService.currentApp(flavor)),
        _timer = timer ?? Timer.new,
        _now = now ?? DateTime.now,
        _random = random ?? Random();

  static MonitoringHeartbeat? _instance;

  /// The heartbeat installed at startup; null before (and in tests that do
  /// not install one).
  static MonitoringHeartbeat? get instance => _instance;

  static void install(MonitoringHeartbeat heartbeat) => _instance = heartbeat;

  ValueListenable<HeartbeatStatus> get status => _status;

  /// The last event `seq` the service persisted, for the event upload (KIO-03).
  int? get ackSeq => _ackSeq;

  Duration get interval => _interval;

  /// Sends while the kiosk is enrolled, from now on. Once.
  void start() {
    if (_started) return;
    _started = true;
    _enrollment.status.addListener(_onEnrollment);
    _onEnrollment();
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _enrollment.status.removeListener(_onEnrollment);
    _token = null;
    _cancel();
    _set(HeartbeatStatus.stopped);
  }

  void _onEnrollment() {
    try {
      final token = _enrollment.deviceToken;
      if (token == null) {
        // Logged out, or enrolling again: nothing to send with.
        _token = null;
        _cancel();
        _set(HeartbeatStatus.stopped);
        return;
      }
      if (token == _token) return;
      _token = token;
      _failures = 0;
      _lastCause = null;
      _schedule(firstBeatDelay);
    } catch (_) {}
  }

  /// One heartbeat now (also what the timer runs).
  Future<void> beat() async {
    final token = _enrollment.deviceToken;
    if (_inFlight || token == null) return;
    _inFlight = true;
    _cancel();
    Duration? next;
    try {
      final counters = _counters();
      await counters.restore();
      final snapshot = await _collector().collect().timeout(collectTimeout);
      final window = counters.snapshot();
      final dto = MonitoringHeartbeatDto(
        installationId: await _enrollment.store.installationId(),
        sentAt: _now(),
        bootId: bootId,
        uptimeSec: _uptime.elapsed.inSeconds,
        app: await _appInfo(),
        state: snapshot.toJson(),
        counters: window.toJson(),
        lastEventSeq: lastEventSeq(),
      );
      final response =
          await _repository.heartbeat(dto, deviceToken: token).timeout(attemptTimeout);
      counters.acknowledge(window);
      _enrollment.onTokenAccepted(token);
      if (_failures > 0) {
        Telemetry.event('monitoring.heartbeat_recovered', data: {'failures': _failures});
      }
      _failures = 0;
      _lastCause = null;
      _lastOkAt = _now();
      if (response.ackSeq != null) _ackSeq = response.ackSeq;
      _interval = intervalFor(response.nextInSec);
      commands.enqueue(response.commands);
      next = _interval;
    } catch (error) {
      final cause = switch (error) {
        MonitoringException e => e.cause,
        TimeoutException _ => 'timeout',
        _ => 'error',
      };
      _lastCause = cause;
      _failures++;
      next = retryDelayFor(_interval, _failures, _random.nextDouble());
      if (error is MonitoringException && error.isTokenInvalid) {
        Telemetry.event('monitoring.token_rejected', level: TelemetryLevel.warning);
        // Forgets the token and enrolls again; sending resumes with the new
        // token. When the enrollment keeps this one (it was replaced already,
        // or an enrollment is on its way), the retry below goes ahead.
        unawaited(_enrollment.onTokenRejected(token));
      } else {
        if (_failures <= detailedFailures || _failures % logEvery == 0) {
          Telemetry.event('monitoring.heartbeat_failed',
              level: TelemetryLevel.warning,
              data: {
                'cause': cause,
                if (error is MonitoringException && error.code != null) 'code': error.code,
                'failures': _failures,
                'retryInSec': next.inSeconds,
              });
        }
      }
    } finally {
      _inFlight = false;
      if (_started) {
        final current = _enrollment.deviceToken;
        if (current == token) {
          _schedule(next ?? _interval);
        } else if (current != null) {
          // Enrolled again while this one was on its way: start over with the
          // new token. Without a token the enrollment starts us again.
          _token = current;
          _failures = 0;
          _schedule(firstBeatDelay);
        }
      }
    }
  }

  /// What the service asked for, kept within [minInterval] and
  /// [maxInterval]; [defaultInterval] when it did not say.
  static Duration intervalFor(int? nextInSec) {
    if (nextInSec == null || nextInSec <= 0) return defaultInterval;
    final seconds = nextInSec.clamp(minInterval.inSeconds, maxInterval.inSeconds);
    return Duration(seconds: seconds);
  }

  /// After [failures] in a row: [interval], then doubling up to
  /// [maxBackoff], each wait shortened by up to [jitter] for [random] in
  /// [0, 1), and never under [minInterval].
  static Duration retryDelayFor(Duration interval, int failures, double random) {
    final factor = pow(2, min(max(failures - 1, 0), 16));
    final base = min(interval.inMilliseconds * factor, maxBackoff.inMilliseconds).toInt();
    final jittered = (base * (1 - jitter * random.clamp(0.0, 1.0))).round();
    return Duration(milliseconds: max(jittered, minInterval.inMilliseconds));
  }

  void _schedule(Duration delay) {
    _cancel();
    _next = _timer(delay, () => unawaited(beat()));
    _publish(nextAt: _now().add(delay));
  }

  void _cancel() {
    _next?.cancel();
    _next = null;
  }

  void _publish({required DateTime? nextAt}) => _set(HeartbeatStatus(
        running: _token != null,
        lastOkAt: _lastOkAt,
        nextAt: nextAt,
        lastCause: _lastCause,
        failures: _failures,
        ackSeq: _ackSeq,
        interval: _interval,
      ));

  void _set(HeartbeatStatus status) {
    try {
      _status.value = status;
    } catch (_) {}
  }

  static int? _unknown() => null;

  static Future<T> Function() _memo<T>(Future<T> Function() compute) {
    Future<T>? result;
    return () => result ??= compute();
  }
}
