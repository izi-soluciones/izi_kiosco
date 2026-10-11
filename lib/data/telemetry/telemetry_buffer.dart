import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:izi_kiosco/data/telemetry/telemetry_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the buffer survives a reload. On web, SharedPreferences is the
/// browser's localStorage.
abstract class TelemetryStore {
  Future<List<String>> load();
  Future<void> save(List<String> events);
}

class PrefsTelemetryStore implements TelemetryStore {
  static const String key = 'telemetry.events';

  @override
  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? const [];
  }

  @override
  Future<void> save(List<String> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, events);
  }
}

class MemoryTelemetryStore implements TelemetryStore {
  List<String> saved = [];

  @override
  Future<List<String>> load() async => List.of(saved);

  @override
  Future<void> save(List<String> events) async => saved = List.of(events);
}

/// The last [capacity] events of this kiosk, kept on the device.
///
/// This is what the diagnostics screen shows, and what is left to look at
/// when Sentry never got the events: the Sentry SDK does not keep anything
/// offline on web. Events of earlier sessions are kept too: the moments
/// before a reload are often the interesting ones.
///
/// It is also what the monitoring upload sends from
/// (`MonitoringTelemetrySink`): the events not acknowledged yet are the
/// newest ones, so they survive a reload here too.
class TelemetryBuffer {
  final int capacity;
  final TelemetryStore _store;
  final Duration saveDelay;
  final List<TelemetryEvent> _events = [];
  Timer? _saveTimer;
  int _lastSeq = 0;

  TelemetryBuffer(
      {TelemetryStore? store,
      this.capacity = 500,
      this.saveDelay = const Duration(seconds: 2)})
      : _store = store ?? MemoryTelemetryStore();

  /// Loads what earlier sessions left, before the events of this one.
  Future<void> restore() async {
    try {
      final saved = (await _store.load())
          .map((line) {
            try {
              return TelemetryEvent.fromJson(jsonDecode(line));
            } catch (_) {
              return null;
            }
          })
          .whereType<TelemetryEvent>()
          .toList();
      _events.insertAll(0, saved);
      for (final e in saved) {
        if (e.seq > _lastSeq) _lastSeq = e.seq;
      }
      _trim();
    } catch (_) {
      // A broken store must never stop the kiosk: start empty.
    }
  }

  void add(TelemetryEvent event) {
    _events.add(event);
    if (event.seq > _lastSeq) _lastSeq = event.seq;
    _trim();
    _saveTimer ??= Timer(saveDelay, () {
      _saveTimer = null;
      unawaited(flush());
    });
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    try {
      await _store.save([for (final e in _events) jsonEncode(e.toJson())]);
    } catch (_) {
      // localStorage full or blocked: the events stay in memory.
    }
  }

  /// Newest first.
  List<TelemetryEvent> recent({int limit = 200}) =>
      _events.reversed.take(limit).toList();

  int get length => _events.length;

  bool get isFull => _events.length >= capacity;

  /// Oldest first, as kept. A view: it changes as events are added.
  List<TelemetryEvent> get events => UnmodifiableListView(_events);

  /// The highest `seq` this buffer holds or held. [Telemetry] numbers the
  /// events of a new session from here, so `seq` keeps growing across
  /// reloads for as long as the stored events survive.
  int get lastSeq => _lastSeq;

  void _trim() {
    final extra = _events.length - capacity;
    if (extra > 0) _events.removeRange(0, extra);
  }
}
