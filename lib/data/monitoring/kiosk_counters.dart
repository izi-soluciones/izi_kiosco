import 'dart:async';
import 'dart:convert';

import 'package:izi_kiosco/data/telemetry/telemetry_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The counters of one heartbeat: what happened since [windowStartAt].
class CounterWindow {
  final DateTime windowStartAt;

  /// When the copy was taken: the start of the next window once it is
  /// accepted.
  final DateTime takenAt;
  final Map<String, int> values;

  const CounterWindow(
      {required this.windowStartAt, required this.takenAt, required this.values});

  /// `counters` of the heartbeat (contracts §4.2): every counter, 0 included.
  Map<String, Object?> toJson() => {
        'windowStartAt': windowStartAt.toUtc().toIso8601String(),
        for (final name in KioskCounters.names) name: values[name] ?? 0,
      };
}

/// Where the counters survive a reload. On web SharedPreferences is the
/// browser's localStorage.
abstract class CountersStore {
  Future<String?> load();
  Future<void> save(String json);
}

class PrefsCountersStore implements CountersStore {
  static const String key = 'monitoring.counters';

  @override
  Future<String?> load() async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> save(String json) async =>
      (await SharedPreferences.getInstance()).setString(key, json);
}

class MemoryCountersStore implements CountersStore {
  String? saved;

  @override
  Future<String?> load() async => saved;

  @override
  Future<void> save(String json) async => saved = json;
}

/// The kiosk's counters for the monitoring heartbeat (contracts §4.2).
///
/// They are deltas since the last heartbeat the service **accepted**: a
/// heartbeat that fails leaves them growing in the same window, and the
/// service, which recognises a window it already counted by its
/// `windowStartAt`, only adds the difference. Only an accepted heartbeat
/// ([acknowledge]) takes what it carried off them and starts the next window;
/// whatever was counted while it was on its way stays for the next one.
///
/// Kept on the device too, so a reload during an outage loses nothing.
class KioskCounters {
  static const String orders = 'orders';
  static const String chargesStarted = 'chargesStarted';
  static const String chargesApproved = 'chargesApproved';
  static const String chargesDeclined = 'chargesDeclined';
  static const String chargesTimeout = 'chargesTimeout';
  static const String chargesError = 'chargesError';
  static const String chargesUnregistered = 'chargesUnregistered';
  static const String printsOk = 'printsOk';
  static const String printsFailed = 'printsFailed';
  static const String posHealthChecks = 'posHealthChecks';
  static const String posHealthFailures = 'posHealthFailures';

  static const List<String> names = [
    orders, chargesStarted, chargesApproved, chargesDeclined, chargesTimeout,
    chargesError, chargesUnregistered, printsOk, printsFailed, posHealthChecks,
    posHealthFailures,
  ];

  final CountersStore _store;
  final DateTime Function() _now;
  final Duration saveDelay;
  final Map<String, int> _values = {};
  late DateTime _windowStartAt;
  Timer? _saveTimer;
  Future<void>? _restoring;

  KioskCounters(
      {CountersStore? store,
      DateTime Function()? now,
      this.saveDelay = const Duration(seconds: 2)})
      : _store = store ?? MemoryCountersStore(),
        _now = now ?? DateTime.now {
    _windowStartAt = _now();
  }

  static KioskCounters _instance = KioskCounters();

  static KioskCounters get instance => _instance;

  /// Replaces the global instance (at startup, and in tests).
  static void install(KioskCounters counters) => _instance = counters;

  DateTime get windowStartAt => _windowStartAt;

  int operator [](String name) => _values[name] ?? 0;

  /// Adds [by] to [name]. Never throws.
  void add(String name, [int by = 1]) {
    try {
      if (by <= 0) return;
      _values[name] = (_values[name] ?? 0) + by;
      _scheduleSave();
    } catch (_) {}
  }

  /// Counts what [event] says about the kiosk's charges. Fed every event
  /// [Telemetry] records, so every charge the payment flow logs is counted
  /// once, whichever path it took.
  void observe(TelemetryEvent event) {
    try {
      for (final name in countersFor(event)) {
        add(name);
      }
    } catch (_) {}
  }

  /// The counters [event] adds to.
  ///
  /// - `charge.start` (sent to the terminal) counts a charge started;
  ///   `charge.not_started` (the terminal could not take it) counts one
  ///   started and one error, so every attempt has an outcome.
  /// - `charge.result` / `charge.timeout`: approved, declined (the terminal
  ///   or the acquirer said no, or the charge was cancelled), timeout (no
  ///   verdict: the card may have been charged) or error (it never reached
  ///   the terminal, or the kiosk could not ask).
  /// - `charge.register_failed`: approved, but iZi does not know. The
  ///   recovery's later attempts on the same charge are not counted again;
  ///   a charge it recovers after a reload counts as approved too.
  /// - `print.ok` / `print.failed`.
  static List<String> countersFor(TelemetryEvent event) {
    final data = event.data;
    switch (event.type) {
      case 'charge.start':
        return const [chargesStarted];
      case 'charge.not_started':
        return const [chargesStarted, chargesError];
      case 'charge.timeout':
        return const [chargesTimeout];
      case 'charge.result':
        return switch (data['status']) {
          'success' => const [chargesApproved],
          'error' || 'cancelled' => const [chargesDeclined],
          'notFound' || 'no_session' || 'failed' => const [chargesError],
          _ => const [chargesTimeout],
        };
      case 'charge.register_failed':
        return switch (data['recovered']) {
          null => const [chargesUnregistered],
          true => const [chargesApproved, chargesUnregistered],
          _ => const [],
        };
      case 'charge.registered_late':
        return data['recovered'] == true ? const [chargesApproved] : const [];
      case 'charge.recovered':
        return switch (data['status']) {
          'ERROR' || 'CANCELLED' => const [chargesDeclined],
          'not_found' => const [chargesTimeout],
          _ => const [],
        };
      case 'print.ok':
        return const [printsOk];
      case 'print.failed':
        return const [printsFailed];
    }
    return const [];
  }

  /// The counters to send now.
  CounterWindow snapshot() => CounterWindow(
      windowStartAt: _windowStartAt, takenAt: _now(), values: Map.of(_values));

  /// The service accepted [sent]: takes what it carried off the counters and
  /// starts the next window. A window that is no longer the current one (it
  /// was acknowledged already) changes nothing.
  void acknowledge(CounterWindow sent) {
    try {
      if (sent.windowStartAt != _windowStartAt) return;
      sent.values.forEach((name, value) {
        final left = (_values[name] ?? 0) - value;
        if (left > 0) {
          _values[name] = left;
        } else {
          _values.remove(name);
        }
      });
      // Strictly later, so the service never takes the next window for a
      // resend of this one.
      _windowStartAt = sent.takenAt.isAfter(_windowStartAt)
          ? sent.takenAt
          : _windowStartAt.add(const Duration(milliseconds: 1));
      _scheduleSave();
    } catch (_) {}
  }

  /// Loads what an earlier session left unsent, keeping its window, and adds
  /// what was counted since this one started. Once; never throws.
  Future<void> restore() => _restoring ??= _restore();

  Future<void> _restore() async {
    try {
      final raw = await _store.load();
      if (raw == null) return;
      final json = jsonDecode(raw);
      if (json is! Map) return;
      final start = DateTime.tryParse('${json['windowStartAt']}');
      final values = json['values'];
      if (start == null || values is! Map) return;
      if (start.isBefore(_windowStartAt)) _windowStartAt = start;
      values.forEach((name, value) {
        if (name is String && value is int && value > 0) {
          _values[name] = (_values[name] ?? 0) + value;
        }
      });
    } catch (_) {
      // Unreadable: start over.
    }
  }

  void _scheduleSave() {
    _saveTimer ??= Timer(saveDelay, () {
      _saveTimer = null;
      unawaited(flush());
    });
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    try {
      await _store.save(jsonEncode({
        'windowStartAt': _windowStartAt.toUtc().toIso8601String(),
        'values': _values,
      }));
    } catch (_) {
      // Storage full or blocked: the counters stay in memory.
    }
  }
}
