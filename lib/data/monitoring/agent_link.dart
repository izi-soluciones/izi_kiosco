import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_agent_client.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/zero_touch_status.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/models/monitoring_enrollment_code.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';

/// What to do about the PC agent after asking its `/health`.
enum AgentNext {
  /// Nothing for now: it is enrolled, or the kiosk is not (and has no
  /// appliance to put it in).
  keep,

  /// Ask again soon: unreachable, or enrolling already.
  retry,

  /// Not enrolled: get it a code.
  enroll,
}

/// Follows the iZi agent of the kiosk PC from the web kiosk (contracts
/// §3.3, §4.1 `state.agent`) and enrolls it without anyone typing a code.
///
/// Every [healthInterval] it asks the agent's `GET /health` on loopback.
/// When the agent answers `enrolled:false` and the kiosk is enrolled, it gets
/// a code `for: agent` from the service and hands it to the agent
/// (`POST /enroll` with the kiosk's gateway as `apiBaseUrl`).
///
/// A kiosk PC without the agent (most of them, for now), or a browser that
/// blocks the request (CORS, Private Network Access), looks the same: the
/// agent is unreachable. That is reported (`reachable:false`) and asked
/// again with backoff (30 s → 30 min); nothing else happens.
///
/// Web only: an Android kiosk has no PC agent.
class AgentLink {
  static const Duration firstCheckDelay = Duration(seconds: 20);
  static const Duration healthInterval = Duration(minutes: 5);
  static const Duration enrollingRecheck = Duration(seconds: 30);
  static const Duration busyRetry = Duration(seconds: 30);

  /// Answers of the agent a retry soon would not change: it is set up for
  /// another gateway, or does not allow the kiosk's origin.
  static const Set<String> lastingRefusals = {'api_base_url_mismatch', 'origin_not_allowed'};

  final MonitoringService _enrollment;
  final MonitoringRepository? _injectedRepository;
  final KioskAgentClient _client;
  final bool Function() _busy;
  final String? Function() _apiBaseUrl;
  final MonitoringTimerFactory _timer;
  final DateTime Function() _now;
  final Random _random;
  final ValueNotifier<ZeroTouchStatus> _status = ValueNotifier(ZeroTouchStatus.stopped);

  late final MonitoringRepository _repository =
      _injectedRepository ?? MonitoringRepositoryHttp();

  bool _started = false;
  bool _inFlight = false;
  Timer? _next;
  int _failures = 0;
  DateTime? _lastCheckAt;
  String? _lastCause;
  bool? _reachable;
  bool? _enrolled;

  AgentLink(
      {required MonitoringService enrollment,
      MonitoringRepository? repository,
      KioskAgentClient? client,
      bool Function()? busy,
      String? Function()? apiBaseUrl,
      MonitoringTimerFactory? timer,
      DateTime Function()? now,
      Random? random})
      : _enrollment = enrollment,
        _injectedRepository = repository,
        _client = client ?? KioskAgentClient(),
        _busy = busy ?? (() => KioskActivity.instance.busy),
        _apiBaseUrl = apiBaseUrl ?? MonitoringRepositoryHttp.apiBaseUrl,
        _timer = timer ?? Timer.new,
        _now = now ?? DateTime.now,
        _random = random ?? Random();

  static AgentLink? _instance;

  static AgentLink? get instance => _instance;

  static void install(AgentLink link) => _instance = link;

  ValueListenable<ZeroTouchStatus> get status => _status;

  /// `state.agent` of the heartbeat: null until the agent was asked once.
  Map<String, Object?>? stateSection() {
    final reachable = _reachable;
    if (reachable == null) return null;
    return {'reachable': reachable, if (_enrolled != null) 'enrolled': _enrolled};
  }

  /// Asks the agent from now on. Once.
  void start() {
    if (_started) return;
    _started = true;
    _enrollment.status.addListener(_onEnrollment);
    _schedule(firstCheckDelay);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _enrollment.status.removeListener(_onEnrollment);
    _cancel();
    _set(ZeroTouchStatus.stopped);
  }

  /// What follows from the agent's [health] (null: it could not be asked).
  static AgentNext decide({required KioskAgentHealth? health, required bool monitoringEnrolled}) {
    if (health == null) return AgentNext.retry;
    if (health.enrolled) return AgentNext.keep;
    if (health.status == 'enrolling') return AgentNext.retry;
    if (!monitoringEnrolled) return AgentNext.keep;
    return AgentNext.enroll;
  }

  /// The kiosk just enrolled: an agent waiting for a code gets it soon.
  void _onEnrollment() {
    try {
      if (!_started || _inFlight || _enrollment.deviceToken == null) return;
      if (_reachable == true && _enrolled == false) _schedule(firstCheckDelay);
    } catch (_) {}
  }

  /// One look at the agent now (also what the timer runs).
  Future<void> check() async {
    if (_inFlight) return;
    _inFlight = true;
    _cancel();
    _lastCheckAt = _now();
    Duration? next;
    try {
      KioskAgentHealth? health;
      try {
        health = await _client.health();
        _reachable = true;
        _enrolled = health.enrolled;
      } on KioskAgentException catch (e) {
        _reachable = false;
        _enrolled = null;
        next = _failed(e.code == 'unreachable' ? 'agent_unreachable' : e.code, null, log: false);
        return;
      }
      final token = _enrollment.deviceToken;
      switch (decide(health: health, monitoringEnrolled: token != null)) {
        case AgentNext.retry:
          next = enrollingRecheck;
          _set(_snapshot('enrolling', next: next));
          return;
        case AgentNext.keep:
          _failures = 0;
          _lastCause = null;
          next = healthInterval;
          _set(health.enrolled
              ? _snapshot('enrolled', next: next)
              : _snapshot('waiting', reason: 'not_enrolled', next: next));
          return;
        case AgentNext.enroll:
          break;
      }
      if (_isBusy()) {
        next = busyRetry;
        _set(_snapshot('waiting', reason: 'busy', next: next));
        return;
      }
      final apiBaseUrl = _apiBaseUrl();
      if (apiBaseUrl == null) {
        next = _failed('no_api_url', MonitoringService.maxBackoff);
        return;
      }
      _set(_snapshot('enrolling'));
      final code = await _repository
          .requestEnrollmentCode(MonitoringEnrollmentCode.forAgent, deviceToken: token!)
          .timeout(MonitoringService.attemptTimeout);
      await _client.enroll(code: code.code, apiBaseUrl: apiBaseUrl);
      _enrolled = true;
      _failures = 0;
      _lastCause = null;
      Telemetry.event('monitoring.agent_enrolled', data: {'agentStatus': health.status});
      // Confirmed by the next /health.
      next = enrollingRecheck;
      _set(_snapshot('enrolled', next: next));
    } on KioskAgentException catch (e) {
      if (e.code == 'already_enrolled') {
        _enrolled = true;
        next = healthInterval;
        _set(_snapshot('enrolled', next: next));
      } else if (e.code == 'enrollment_in_progress') {
        next = enrollingRecheck;
        _set(_snapshot('enrolling', next: next));
      } else {
        next = _failed(
            e.code, lastingRefusals.contains(e.code) ? MonitoringService.maxBackoff : null);
      }
    } on MonitoringException catch (e) {
      final token = _enrollment.deviceToken;
      if (e.isTokenInvalid && token != null) unawaited(_enrollment.onTokenRejected(token));
      next = _failed(e.cause, null);
    } on TimeoutException {
      next = _failed('timeout', null);
    } catch (_) {
      next = _failed('error', null);
    } finally {
      _inFlight = false;
      if (_started && next != null) _schedule(next);
    }
  }

  /// [delay] null: the usual backoff for the failures so far. [log] false
  /// for an agent that is simply not there.
  Duration _failed(String cause, Duration? delay, {bool log = true}) {
    _failures++;
    final next = delay ?? MonitoringService.retryDelayFor(_failures, _random.nextDouble());
    if (log && (cause != _lastCause || _failures <= 3)) {
      Telemetry.event('monitoring.agent_enroll_failed',
          level: TelemetryLevel.warning,
          data: {'cause': cause, 'failures': _failures, 'retryInSec': next.inSeconds});
    }
    _lastCause = cause;
    _set(_snapshot('failed', next: next));
    return next;
  }

  ZeroTouchStatus _snapshot(String state, {String? reason, Duration? next}) => ZeroTouchStatus(
      state: state,
      reason: reason,
      lastCause: _lastCause,
      failures: _failures,
      lastCheckAt: _lastCheckAt,
      nextAt: next == null ? null : _now().add(next));

  bool _isBusy() {
    try {
      return _busy();
    } catch (_) {
      return true;
    }
  }

  void _schedule(Duration delay) {
    _cancel();
    _next = _timer(delay, () {
      _next = null;
      unawaited(check());
    });
  }

  void _cancel() {
    _next?.cancel();
    _next = null;
  }

  void _set(ZeroTouchStatus status) {
    try {
      _status.value = status;
    } catch (_) {}
  }
}
