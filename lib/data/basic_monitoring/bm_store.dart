import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

const _kInstallationId = 'bm.installationId';
const _kDeviceToken = 'bm.deviceToken';
const _kDeviceId = 'bm.deviceId';
const _kApplianceId = 'bm.applianceId';
const _kOwner = 'bm.owner';
const _kCounters = 'bm.counters';
const _kWindowStart = 'bm.windowStart';
const _kCommands = 'bm.commands';

class BmStore {
  final SharedPreferences _prefs;

  BmStore(this._prefs);

  String installationId() {
    final existing = _prefs.getString(_kInstallationId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuidV4();
    _prefs.setString(_kInstallationId, id);
    return id;
  }

  String? get deviceToken => _prefs.getString(_kDeviceToken);

  String? get owner => _prefs.getString(_kOwner);

  Future<void> saveEnrollment({
    required String deviceToken,
    required String deviceId,
    required String applianceId,
    required String owner,
  }) async {
    await _prefs.setString(_kDeviceToken, deviceToken);
    await _prefs.setString(_kDeviceId, deviceId);
    await _prefs.setString(_kApplianceId, applianceId);
    await _prefs.setString(_kOwner, owner);
  }

  Future<void> replaceDeviceToken(String token) async {
    await _prefs.setString(_kDeviceToken, token);
  }

  Future<void> clearEnrollment() async {
    await _prefs.remove(_kDeviceToken);
    await _prefs.remove(_kDeviceId);
    await _prefs.remove(_kApplianceId);
    await _prefs.remove(_kOwner);
  }

  Map<String, int> pendingCounters() {
    final raw = _prefs.getString(_kCounters);
    if (raw == null) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      final out = <String, int>{};
      decoded.forEach((k, v) {
        if (v is int) out[k.toString()] = v;
      });
      return out;
    } catch (_) {
      return <String, int>{};
    }
  }

  String windowStartAt(DateTime now) {
    final existing = _prefs.getString(_kWindowStart);
    if (existing != null && existing.isNotEmpty) return existing;
    final start = now.toUtc().toIso8601String();
    _prefs.setString(_kWindowStart, start);
    return start;
  }

  Future<void> addCounter(String name, int delta) async {
    final counters = pendingCounters();
    counters[name] = (counters[name] ?? 0) + delta;
    await _prefs.setString(_kCounters, jsonEncode(counters));
  }

  Future<void> commitWindow(DateTime now) async {
    await _prefs.remove(_kCounters);
    await _prefs.setString(_kWindowStart, now.toUtc().toIso8601String());
  }

  Map<String, DateTime> _commands() {
    final raw = _prefs.getString(_kCommands);
    if (raw == null) return <String, DateTime>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, DateTime>{};
      final out = <String, DateTime>{};
      decoded.forEach((k, v) {
        final at = v is String ? DateTime.tryParse(v) : null;
        if (at != null) out[k.toString()] = at;
      });
      return out;
    } catch (_) {
      return <String, DateTime>{};
    }
  }

  bool seenCommand(String id) => _commands().containsKey(id);

  Future<void> markCommand(String id, DateTime at) async {
    final limit = at.subtract(const Duration(days: 7));
    final commands = _commands()..removeWhere((_, seenAt) => seenAt.isBefore(limit));
    commands[id] = at;
    await _prefs.setString(
      _kCommands,
      jsonEncode(commands.map((k, v) => MapEntry(k, v.toUtc().toIso8601String()))),
    );
  }

  static String _uuidV4() {
    final random = Random.secure();
    final b = List<int>.generate(16, (_) => random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
