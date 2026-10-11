import 'package:dio/dio.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';

/// What every health loop of this kiosk has learnt about the link with its
/// card terminal, for the monitoring heartbeat (contracts §4.1, `state.pos`).
///
/// The configuration loop ([PosLinkTracker] `pos_config`) and the home
/// screen (`home`, and the ATC / Linkser check) all report here: they ask the
/// same terminal, so any answer resets the failures in a row and any miss
/// adds one. Only cached results: building a heartbeat never asks the
/// terminal anything, so it cannot compete with a charge.
class PosLinkHealth {
  /// The latencies the median is taken from.
  static const int latencySamples = 20;

  /// How far back a failure still marks the link as `degraded`.
  static const Duration degradedWindow = Duration(minutes: 5);

  /// The causes the monitoring contracts name (`state.pos.lastCause`).
  static const Set<String> contractCauses = {
    'timeout', 'refused', 'unreachable', 'dns', 'closed', 'cors', 'no_answer',
  };

  final DateTime Function() _now;
  final KioskCounters Function() _counters;
  final List<int> _latencies = [];
  final List<DateTime> _failures = [];

  DateTime? _lastOkAt;
  DateTime? _lastCheckAt;
  bool? _lastOk;
  int _consecutiveFailures = 0;
  String? _lastCause;
  String? _notReadyReason;
  String? _address;
  IzifyPosHealth? _terminal;

  PosLinkHealth({DateTime Function()? now, KioskCounters Function()? counters})
      : _now = now ?? DateTime.now,
        _counters = counters ?? (() => KioskCounters.instance);

  static PosLinkHealth _instance = PosLinkHealth();

  static PosLinkHealth get instance => _instance;

  /// Replaces the global instance (in tests).
  static void install(PosLinkHealth health) => _instance = health;

  /// The terminal answered. [notReadyReason] is why it cannot charge, when
  /// it cannot; [terminal] is its own report (Izify POS only).
  void answered(
      {String? address, int? ms, String? notReadyReason, IzifyPosHealth? terminal}) {
    try {
      final now = _now();
      _lastOk = true;
      _lastOkAt = now;
      _lastCheckAt = now;
      _consecutiveFailures = 0;
      _lastCause = null;
      _notReadyReason = notReadyReason;
      if (address != null) _address = address;
      if (terminal != null) _terminal = terminal;
      if (ms != null && ms >= 0) {
        _latencies.add(ms);
        if (_latencies.length > latencySamples) _latencies.removeAt(0);
      }
      _counters().add(KioskCounters.posHealthChecks);
    } catch (_) {}
  }

  /// The terminal did not answer. [cause] is [posFailureCause]'s word.
  void failed({String? address, required String cause}) {
    try {
      final now = _now();
      // On web the first word is often `browser_blocked`, refined later by a
      // probe that only runs for some failures: keep the refined one while
      // the outage lasts.
      final keepRefined = cause == 'browser_blocked' && _lastOk == false && _lastCause != null;
      _lastOk = false;
      _lastCheckAt = now;
      _consecutiveFailures++;
      if (!keepRefined) _lastCause = contractCause(cause);
      if (address != null) _address = address;
      _failures.add(now);
      _prune(now);
      _counters()
        ..add(KioskCounters.posHealthChecks)
        ..add(KioskCounters.posHealthFailures);
    } catch (_) {}
  }

  /// What a probe found out about the last failure (see [probePosFailure]),
  /// while it is still the last result.
  void refineCause(String cause) {
    if (_lastOk == false) _lastCause = contractCause(cause);
  }

  /// Forgets the terminal, e.g. once the kiosk was unpaired from it.
  void reset() {
    _latencies.clear();
    _failures.clear();
    _lastOkAt = null;
    _lastCheckAt = null;
    _lastOk = null;
    _consecutiveFailures = 0;
    _lastCause = null;
    _notReadyReason = null;
    _address = null;
    _terminal = null;
  }

  PosLinkView view() {
    final now = _now();
    _prune(now);
    return PosLinkView(
      lastOk: _lastOk,
      lastOkAt: _lastOkAt,
      lastCheckAt: _lastCheckAt,
      consecutiveFailures: _consecutiveFailures,
      lastCause: _lastCause,
      notReadyReason: _notReadyReason,
      address: _address,
      terminal: _terminal,
      latencyMsP50: median(_latencies),
      failedRecently: _failures.isNotEmpty,
    );
  }

  void _prune(DateTime now) =>
      _failures.removeWhere((at) => now.difference(at) > degradedWindow);

  /// [cause] as one of the contract's words: `http_<status>` and
  /// [contractCauses] stay; the browser's `browser_blocked` and anything
  /// unexpected become `unreachable`, which is what they mean to support:
  /// the kiosk could not get an answer.
  static String contractCause(String cause) {
    if (contractCauses.contains(cause)) return cause;
    if (RegExp(r'^http_\d{1,3}$').hasMatch(cause)) return cause;
    return 'unreachable';
  }

  /// Why the bridge of an ATC or Linkser terminal (`ATC_SERVER_URL`) did not
  /// answer, in the contract's words.
  static String bridgeFailureCause(Object error) {
    if (error is! DioException) return 'unreachable';
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'timeout';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return status == null ? 'unreachable' : 'http_$status';
      default:
        return 'unreachable';
    }
  }

  /// The median of [values], or null when there are none.
  static int? median(List<int> values) {
    if (values.isEmpty) return null;
    final sorted = List.of(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return ((sorted[mid - 1] + sorted[mid]) / 2).round();
  }
}

/// A copy of [PosLinkHealth] at one moment.
class PosLinkView {
  /// Whether the last check got an answer; null before the first one.
  final bool? lastOk;
  final DateTime? lastOkAt;
  final DateTime? lastCheckAt;
  final int consecutiveFailures;
  final String? lastCause;

  /// Why the terminal cannot charge, from its last answer.
  final String? notReadyReason;
  final String? address;
  final IzifyPosHealth? terminal;
  final int? latencyMsP50;

  /// A check failed within [PosLinkHealth.degradedWindow].
  final bool failedRecently;

  const PosLinkView(
      {this.lastOk,
      this.lastOkAt,
      this.lastCheckAt,
      this.consecutiveFailures = 0,
      this.lastCause,
      this.notReadyReason,
      this.address,
      this.terminal,
      this.latencyMsP50,
      this.failedRecently = false});

  static const PosLinkView none = PosLinkView();
}
