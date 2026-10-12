import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/zero_touch_status.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/telemetry/pos_telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/pos_config/pos_config_bloc.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/monitoring_enrollment_code.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';

/// Why the terminal's enrollment cannot be looked at now.
enum TerminalEnrollBlock {
  /// The kiosk itself is not enrolled: it has no appliance to put the
  /// terminal in.
  notEnrolled,
  notPaired,

  /// Paired, but the terminal does not answer or is not ready: its health
  /// loop is busy fixing that, and comes first.
  unhealthy,

  /// A customer is paying: nothing may compete with the charge.
  busy,
}

/// Enrolls the paired PayPOS terminal in the monitoring without anyone
/// typing a code (contracts §3.3).
///
/// While the kiosk is enrolled and its terminal paired and healthy, it asks
/// the terminal `GET /monitoring/status` (with the pairing token). When the
/// terminal says `enrolled:false`, it gets a code `for: terminal` from the
/// service and hands it to the terminal (`POST /monitoring/enroll` with the
/// kiosk's gateway as `apiBaseUrl`), which redeems it.
///
/// - Never while a customer is paying ([KioskActivity.busy]), checked before
///   every call to the terminal; a terminal that answers `BUSY` (409) is
///   asked again in [busyRetry].
/// - A code the terminal reports refused (`ENROLLMENT_CODE_INVALID`: a newer
///   one replaced it, or it expired) is replaced by a new one right away,
///   once (contracts §12.7). What a retry soon would not change
///   ([lastingRefusals]) waits the longest backoff.
/// - A terminal without the routes (404, PayPOS before monitoring) is left
///   alone, asked again in [recheckUnsupported] in case it was updated.
/// - Failures back off like the kiosk's enrollment (30 s → 30 min, with
///   jitter); an enrolled terminal is checked again every [recheckEnrolled]
///   (it may have lost its token).
///
/// Fail-safe: nothing here is awaited by the UI and nothing throws out.
class TerminalEnrollment {
  static const Duration firstCheckDelay = Duration(seconds: 30);
  static const Duration waitForPos = Duration(minutes: 5);
  static const Duration busyRetry = Duration(seconds: 30);
  static const Duration recheckEnrolled = Duration(minutes: 30);
  static const Duration recheckUnsupported = Duration(hours: 6);

  /// Answers of PayPOS a retry soon would not change: it does not report to
  /// this gateway, or does not take what this kiosk sends.
  static const Set<String> lastingRefusals = {'API_NOT_ALLOWED', 'INVALID_BODY'};

  static const String codeInvalid = 'ENROLLMENT_CODE_INVALID';

  /// Failures in a row recorded in detail; after that, one in [logEvery].
  static const int detailedFailures = 3;
  static const int logEvery = 10;

  final MonitoringService _enrollment;
  final MonitoringRepository? _injectedRepository;
  final IzifyPosClient? _injectedClient;
  final Future<IzifyPosSession?> Function(Device? device) _session;
  final bool Function() _busy;
  final String? Function() _apiBaseUrl;
  final MonitoringTimerFactory _timer;
  final DateTime Function() _now;
  final Random _random;
  final ValueNotifier<ZeroTouchStatus> _status = ValueNotifier(ZeroTouchStatus.stopped);

  late final MonitoringRepository _repository =
      _injectedRepository ?? MonitoringRepositoryHttp();
  late final IzifyPosClient _client = _injectedClient ?? IzifyPosClient();

  PosConfigState? Function() _pos = _noPos;
  Device? Function() _device = _noDevice;
  StreamSubscription<PosConfigState>? _posSub;

  bool _started = false;
  bool _inFlight = false;
  Timer? _next;
  int _failures = 0;
  DateTime? _lastCheckAt;
  String? _lastCause;

  /// The terminal last asked, and whether it answered (enrolled or not)
  /// rather than being in the way: a new terminal, or one that comes back,
  /// is checked again soon.
  IzifyPosAddress? _checkedAddress;
  bool _waitingForPos = false;
  bool _reportedUnsupported = false;

  TerminalEnrollment(
      {required MonitoringService enrollment,
      MonitoringRepository? repository,
      IzifyPosClient? client,
      Future<IzifyPosSession?> Function(Device? device)? session,
      bool Function()? busy,
      String? Function()? apiBaseUrl,
      MonitoringTimerFactory? timer,
      DateTime Function()? now,
      Random? random})
      : _enrollment = enrollment,
        _injectedRepository = repository,
        _injectedClient = client,
        _session = session ?? IzifyPosSession.current,
        _busy = busy ?? (() => KioskActivity.instance.busy),
        _apiBaseUrl = apiBaseUrl ?? MonitoringRepositoryHttp.apiBaseUrl,
        _timer = timer ?? Timer.new,
        _now = now ?? DateTime.now,
        _random = random ?? Random();

  static TerminalEnrollment? _instance;

  static TerminalEnrollment? get instance => _instance;

  static void install(TerminalEnrollment enrollment) => _instance = enrollment;

  ValueListenable<ZeroTouchStatus> get status => _status;

  /// Where the pairing and its health live (set up by `MyApp`).
  void attach({required AuthBloc auth, required PosConfigBloc posConfig}) => attachState(
      pos: () => posConfig.state,
      changes: posConfig.stream,
      device: () => auth.state.currentDevice);

  /// For tests: the states themselves.
  void attachState(
      {required PosConfigState? Function() pos,
      Stream<PosConfigState>? changes,
      Device? Function()? device}) {
    _pos = pos;
    if (device != null) _device = device;
    _posSub?.cancel();
    _posSub = changes?.listen(_onPos);
  }

  /// Works while the kiosk is enrolled, from now on. Once.
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
    _cancel();
    _set(ZeroTouchStatus.stopped);
  }

  /// What keeps the terminal's enrollment from being looked at, or null
  /// when it can be.
  static TerminalEnrollBlock? blockedBy(
      {required bool monitoringEnrolled, required PosConfigState? pos, required bool busy}) {
    if (!monitoringEnrolled) return TerminalEnrollBlock.notEnrolled;
    if (pos == null || pos.pairedDevice == null) return TerminalEnrollBlock.notPaired;
    if (pos.status == PosConfigStatus.pairing || pos.isHealthy != true) {
      return TerminalEnrollBlock.unhealthy;
    }
    if (busy) return TerminalEnrollBlock.busy;
    return null;
  }

  void _onEnrollment() {
    try {
      if (_enrollment.deviceToken == null) {
        _cancel();
        if (_started) _set(const ZeroTouchStatus(state: 'waiting', reason: 'not_enrolled'));
        return;
      }
      if (_next == null && !_inFlight) _schedule(firstCheckDelay);
    } catch (_) {}
  }

  void _onPos(PosConfigState pos) {
    try {
      if (!_started || _inFlight || _enrollment.deviceToken == null) return;
      final paired = pos.pairedDevice;
      if (paired == null || pos.isHealthy != true) return;
      final address = IzifyPosAddress(paired.ip, paired.port);
      // Soon after the terminal comes back, or a new one is paired; not on
      // every health check of the one already looked at.
      if (!_waitingForPos && address == _checkedAddress) return;
      final due = _status.value.nextAt;
      if (due != null && !due.isAfter(_now().add(firstCheckDelay))) return;
      _schedule(firstCheckDelay);
    } catch (_) {}
  }

  /// One look at the terminal now (also what the timer runs).
  Future<void> check() async {
    final token = _enrollment.deviceToken;
    if (_inFlight || token == null) return;
    _inFlight = true;
    _cancel();
    _lastCheckAt = _now();
    Duration? next;
    try {
      final block = blockedBy(
          monitoringEnrolled: true, pos: _safe(_pos), busy: _isBusy());
      if (block != null) {
        next = _blocked(block);
        return;
      }
      final session = await _session(_safe(_device));
      if (session == null) {
        next = _blocked(TerminalEnrollBlock.notPaired);
        return;
      }
      // The session took a moment: the customer may have started paying.
      if (_isBusy()) {
        next = _blocked(TerminalEnrollBlock.busy);
        return;
      }
      _waitingForPos = false;
      _set(_snapshot('checking'));
      final terminal = await _client.monitoringStatus(session.address, token: session.token);
      _checkedAddress = session.address;
      if (terminal == null) {
        next = _unsupported(session.address);
        return;
      }
      if (terminal.enrolled) {
        _failures = 0;
        _lastCause = null;
        next = recheckEnrolled;
        _set(_snapshot('enrolled', next: next));
        return;
      }
      if (_isBusy()) {
        next = _blocked(TerminalEnrollBlock.busy);
        return;
      }
      final apiBaseUrl = _apiBaseUrl();
      if (apiBaseUrl == null) {
        next = _failed('no_api_url', MonitoringService.longestRetryDelay(_random.nextDouble()));
        return;
      }
      _set(_snapshot('enrolling'));
      for (var attempt = 1;; attempt++) {
        final code = await _repository
            .requestEnrollmentCode(MonitoringEnrollmentCode.forTerminal, deviceToken: token)
            .timeout(MonitoringService.attemptTimeout);
        // The code took a moment: the customer may have started paying.
        if (_isBusy()) {
          next = _blocked(TerminalEnrollBlock.busy);
          return;
        }
        try {
          await _client.monitoringEnroll(session.address,
              token: session.token, code: code.code, apiBaseUrl: apiBaseUrl);
          break;
        } on IzifyPosException catch (e) {
          // Replaced by a newer code, or expired on its way: a new one, now.
          if (e.code != codeInvalid || attempt > 1) rethrow;
          Telemetry.event('monitoring.terminal_code_refused', level: TelemetryLevel.warning);
        }
      }
      Telemetry.event('monitoring.terminal_enrolled',
          data: {'address': session.address.hostPort, 'reenroll': terminal.reenrollRequired});
      _failures = 0;
      _lastCause = null;
      next = recheckEnrolled;
      _set(_snapshot('enrolled', next: next));
    } on IzifyPosException catch (e) {
      switch (e.code) {
        case 'BUSY':
          next = _blocked(TerminalEnrollBlock.busy);
        case 'UNSUPPORTED':
          next = _unsupported(_checkedAddress);
        case final String code when lastingRefusals.contains(code):
          // This PayPOS build does not report to this gateway, or does not
          // take the request: nothing a retry soon would change.
          next = _failed(
              code.toLowerCase(), MonitoringService.longestRetryDelay(_random.nextDouble()));
        default:
          next = _failed(e.code?.toLowerCase() ?? posFailureCause(e), null);
      }
    } on MonitoringException catch (e) {
      if (e.isTokenInvalid) unawaited(_enrollment.onTokenRejected(token));
      next = _failed(e.cause, null);
    } on TimeoutException {
      next = _failed('timeout', null);
    } catch (_) {
      next = _failed('error', null);
    } finally {
      _inFlight = false;
      if (_started && next != null && _enrollment.deviceToken != null) {
        _schedule(next);
      }
    }
  }

  Duration? _blocked(TerminalEnrollBlock block) {
    switch (block) {
      case TerminalEnrollBlock.notEnrolled:
        _set(const ZeroTouchStatus(state: 'waiting', reason: 'not_enrolled'));
        return null;
      case TerminalEnrollBlock.busy:
        _set(_snapshot('waiting', reason: 'busy', next: busyRetry));
        return busyRetry;
      case TerminalEnrollBlock.notPaired:
      case TerminalEnrollBlock.unhealthy:
        // The pairing changing wakes this up sooner (_onPos).
        _waitingForPos = true;
        final reason = block == TerminalEnrollBlock.notPaired ? 'not_paired' : 'unhealthy';
        _set(_snapshot('waiting', reason: reason, next: waitForPos));
        return waitForPos;
    }
  }

  Duration _unsupported(IzifyPosAddress? address) {
    if (!_reportedUnsupported) {
      _reportedUnsupported = true;
      Telemetry.event('monitoring.terminal_unsupported',
          data: {if (address != null) 'address': address.hostPort});
    }
    _failures = 0;
    _set(_snapshot('unsupported', next: recheckUnsupported));
    return recheckUnsupported;
  }

  /// [delay] null: the usual backoff for the failures so far.
  Duration _failed(String cause, Duration? delay) {
    _failures++;
    final next = delay ?? MonitoringService.retryDelayFor(_failures, _random.nextDouble());
    if (_failures <= detailedFailures || _failures % logEvery == 0 || cause != _lastCause) {
      Telemetry.event('monitoring.terminal_enroll_failed',
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
    final current = _status.value;
    _set(ZeroTouchStatus(
        state: current.state == 'stopped' ? 'waiting' : current.state,
        reason: current.reason,
        lastCause: current.lastCause,
        failures: current.failures,
        lastCheckAt: current.lastCheckAt,
        nextAt: _now().add(delay)));
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

  static T? _safe<T>(T? Function() read) {
    try {
      return read();
    } catch (_) {
      return null;
    }
  }

  static PosConfigState? _noPos() => null;

  static Device? _noDevice() => null;
}
