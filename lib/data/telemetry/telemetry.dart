import 'package:izi_kiosco/data/telemetry/send_budget.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_buffer.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_event.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';

export 'package:izi_kiosco/data/telemetry/telemetry_event.dart'
    show TelemetryLevel, TelemetryEvent;

/// Where recorded events go besides the device (Sentry in production).
abstract class TelemetrySink {
  /// [sendLog]: within the log budget. [sendIssue]: the event asked to be an
  /// issue and is within the issue budget.
  void onEvent(TelemetryEvent event,
      {required bool sendLog, required bool sendIssue});

  /// Who this kiosk is, attached to everything sent from now on.
  void setContext(Map<String, Object?> context);
}

/// Told of every event recorded, already redacted (e.g. the monitoring
/// counters). Must be quick and must not record events itself.
typedef TelemetryObserver = void Function(TelemetryEvent event);

/// Records what happens on this kiosk: to the device buffer always, to the
/// [observers], and to the [TelemetrySink] within the [SendBudget].
///
/// Everything goes through [TelemetryRedactor] first. Recording never throws
/// and never waits: it must not be able to break a sale.
class Telemetry {
  final TelemetryBuffer buffer;
  final TelemetrySink? sink;
  final SendBudget budget;
  final List<TelemetryObserver> observers;
  final Stopwatch _uptime = Stopwatch()..start();
  int _seq = 0;
  Map<String, Object?> _context = const {};

  Telemetry(
      {TelemetryBuffer? buffer,
      this.sink,
      SendBudget? budget,
      List<TelemetryObserver> observers = const []})
      : buffer = buffer ?? TelemetryBuffer(),
        budget = budget ?? SendBudget(),
        observers = List.unmodifiable(observers);

  static Telemetry _instance = Telemetry();

  static Telemetry get instance => _instance;

  /// Replaces the global instance (at startup, and in tests).
  static void install(Telemetry telemetry) => _instance = telemetry;

  /// Records [type]. Mark [issue] only for what someone has to look at
  /// (a charge left without a verdict, a crash): issues are scarce.
  static void event(
    String type, {
    TelemetryLevel level = TelemetryLevel.info,
    String? chargeId,
    String? reference,
    Map<String, Object?> data = const {},
    bool issue = false,
  }) =>
      _instance.record(type,
          level: level,
          chargeId: chargeId,
          reference: reference,
          data: data,
          issue: issue);

  /// Who this kiosk is: contribuyente, device, branch. Merged into the
  /// current context; a null value removes the key.
  static void setContext(Map<String, Object?> context) =>
      _instance.updateContext(context);

  static List<TelemetryEvent> recent({int limit = 200}) =>
      _instance.buffer.recent(limit: limit);

  Map<String, Object?> get context => _context;

  Duration get uptime => _uptime.elapsed;

  TelemetryEvent? record(
    String type, {
    TelemetryLevel level = TelemetryLevel.info,
    String? chargeId,
    String? reference,
    Map<String, Object?> data = const {},
    bool issue = false,
  }) {
    try {
      final event = TelemetryEvent(
        seq: ++_seq,
        ts: DateTime.now(),
        upMs: _uptime.elapsedMilliseconds,
        type: type,
        level: level,
        chargeId: chargeId,
        reference: reference,
        data: TelemetryRedactor.redact(data),
      );
      buffer.add(event);
      for (final observer in observers) {
        try {
          observer(event);
        } catch (_) {}
      }
      final sink = this.sink;
      if (sink != null) {
        final sendLog = budget.allowLog(type);
        final sendIssue = issue && budget.allowIssue(issueKey(event));
        sink.onEvent(event, sendLog: sendLog, sendIssue: sendIssue);
      }
      return event;
    } catch (_) {
      return null;
    }
  }

  void updateContext(Map<String, Object?> context) {
    try {
      final next = Map<String, Object?>.of(_context);
      context.forEach((k, v) => v == null ? next.remove(k) : next[k] = v);
      _context = TelemetryRedactor.redact(next);
      sink?.setContext(_context);
    } catch (_) {}
  }

  /// Issues of the same type and cause count against the same allowance.
  static String issueKey(TelemetryEvent event) =>
      '${event.type}:${event.data['code'] ?? event.data['cause'] ?? event.data['status'] ?? ''}';
}
