import 'dart:async';
import 'dart:convert';

import 'package:izi_kiosco/data/monitoring/agent_link.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_collector.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_snapshot.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_heartbeat.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_telemetry_sink.dart';
import 'package:izi_kiosco/data/monitoring/terminal_enrollment.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/telemetry/pos_telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';
import 'package:izi_kiosco/domain/models/device.dart';

/// The diagnostics report of this kiosk: what the "Kiosco" tab of the
/// diagnostics dialog shows (context, health, monitoring, latest events) and
/// the terminal's own record (`GET /diagnostics`) when it can be asked.
///
/// The dialog shows it to a technician; `upload_diagnostics` sends it to
/// the monitoring service ([build]), redacted and within [maxBytes]. The
/// terminal is asked only while no customer is paying, checked right before
/// the call: gathering the kiosk's part takes a moment, and a charge may
/// have started since the command was let through.
class KioskDiagnostics {
  /// The service takes up to 2 MB (contracts §6); some room for the
  /// envelope.
  static const int maxBytes = 1900 * 1024;
  static const int eventLimit = 300;
  static const Duration collectTimeout = Duration(seconds: 10);

  final KioskHealthCollector Function() _collector;
  final Future<IzifyPosSession?> Function(Device? device) _session;
  final IzifyPosClient Function() _client;
  final DateTime Function() _now;
  final bool Function() _busy;

  KioskDiagnostics({
    KioskHealthCollector Function()? collector,
    Future<IzifyPosSession?> Function(Device? device)? session,
    IzifyPosClient Function()? client,
    DateTime Function()? now,
    bool Function()? busy,
  })  : _collector = collector ?? (() => KioskHealthCollector.instance),
        _session = session ?? IzifyPosSession.current,
        _client = client ?? IzifyPosClient.new,
        _now = now ?? DateTime.now,
        _busy = busy ?? (() => KioskActivity.instance.busy);

  /// The monitoring's own state: the [health] it reports, the counters not
  /// delivered yet, the heartbeat, the event upload, the remote commands and
  /// the enrollment of the terminal and the PC agent.
  static Map<String, Object?> monitoringSection(KioskHealthSnapshot? health) {
    final status = MonitoringHeartbeat.instance?.status.value;
    final events = MonitoringTelemetrySink.instance?.status.value;
    final terminal = TerminalEnrollment.instance?.status.value;
    final agent = AgentLink.instance?.status.value;
    return {
      if (health != null) 'health': health.toJson(),
      'counters': KioskCounters.instance.snapshot().toJson(),
      if (status != null)
        'heartbeat': {
          'running': status.running,
          'lastOkAt': status.lastOkAt?.toIso8601String(),
          'nextAt': status.nextAt?.toIso8601String(),
          'lastCause': status.lastCause,
          'failures': status.failures,
          'ackSeq': status.ackSeq,
          'intervalSec': status.interval.inSeconds,
        },
      if (events != null) 'events': events.toJson(),
      if (terminal != null) 'terminalEnrollment': terminal.toJson(),
      if (agent != null) 'agent': agent.toJson(),
    };
  }

  /// The "Kiosco" tab.
  static Map<String, Object?> kioskSection(
          {KioskHealthSnapshot? health, required List<TelemetryEvent> events}) =>
      {
        'context': Telemetry.instance.context,
        'state': kioskSnapshot(),
        'monitoring': monitoringSection(health),
        'events': [for (final e in events) e.toJson()],
      };

  /// The report for the monitoring service: redacted, and trimmed to
  /// [maxBytes] dropping the oldest events first. Never throws: what cannot
  /// be read is reported as such.
  Future<Map<String, Object?>> build({Device? device}) async {
    KioskHealthSnapshot? health;
    try {
      health = await _collector().collect().timeout(collectTimeout);
    } catch (_) {}
    final report = <String, Object?>{
      'schema': 1,
      'kind': 'kiosk',
      'generated': _now().toUtc().toIso8601String(),
      'kiosk': kioskSection(health: health, events: _safeEvents()),
      'terminal': await _terminal(device),
    };
    return fit(TelemetryRedactor.redact(report, maxDepth: 12, maxItems: 1000));
  }

  /// The terminal's record, or why there is none: `not_paired`, `busy` (a
  /// customer is paying: the terminal is not asked), `unsupported` (PayPOS
  /// too old) or `unreachable` with its cause.
  Future<Object?> _terminal(Device? device) async {
    IzifyPosClient? client;
    try {
      final session = await _session(device);
      if (session == null) return {'unavailable': 'not_paired'};
      if (_isBusy()) return {'unavailable': 'busy'};
      client = _client();
      final data = await client.diagnostics(session.address, token: session.token);
      return data ?? {'unavailable': 'unsupported'};
    } on IzifyPosException catch (e) {
      return {'unavailable': 'unreachable', 'cause': posFailureCause(e)};
    } catch (e) {
      return {'unavailable': 'error', 'cause': e.runtimeType.toString()};
    } finally {
      client?.close();
    }
  }

  bool _isBusy() {
    try {
      return _busy();
    } catch (_) {
      // Unknown counts as busy: the terminal is never asked during a sale.
      return true;
    }
  }

  static List<TelemetryEvent> _safeEvents() {
    try {
      return Telemetry.recent(limit: eventLimit);
    } catch (_) {
      return const [];
    }
  }

  /// [report] as is when it fits in [limit] bytes of JSON; otherwise with
  /// the older half of the kiosk's and the terminal's events dropped, again
  /// and again, and with neither as a last resort.
  static Map<String, Object?> fit(Map<String, Object?> report, {int limit = maxBytes}) {
    int size(Map<String, Object?> r) => utf8.encode(jsonEncode(r)).length;
    var current = report;
    for (var i = 0; i < 12 && size(current) > limit; i++) {
      current = _halveEvents(current);
    }
    if (size(current) > limit) {
      current = {
        ...current,
        'kiosk': {...?_asMap(current['kiosk']), 'events': const []},
        'terminal': {'unavailable': 'too_large'},
      };
    }
    return current;
  }

  static Map<String, Object?> _halveEvents(Map<String, Object?> report) {
    final kiosk = _asMap(report['kiosk']);
    final terminal = _asMap(report['terminal']);
    return {
      ...report,
      if (kiosk != null) 'kiosk': {...kiosk, 'events': _newestHalf(kiosk['events'])},
      if (terminal != null && terminal['events'] is List)
        'terminal': {...terminal, 'events': _newestHalf(terminal['events'])},
    };
  }

  /// The newer half of [events], by their `ts`, newest first (the order
  /// each side lists them in is its own).
  static List<Object?> _newestHalf(Object? events) {
    if (events is! List || events.isEmpty) return const [];
    String ts(Object? e) => e is Map ? '${e['ts'] ?? ''}' : '';
    final sorted = List<Object?>.of(events)..sort((a, b) => ts(b).compareTo(ts(a)));
    return sorted.sublist(0, sorted.length ~/ 2);
  }

  static Map<String, Object?>? _asMap(Object? value) =>
      value is Map ? Map<String, Object?>.from(value) : null;
}
