import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Who this kiosk is for the monitoring service, as last enrolled.
class MonitoringEnrollmentRecord {
  final String deviceToken;
  final String? deviceId;
  final String? applianceId;

  /// The iZi contribuyente and device the token was issued for. A token of
  /// another contribuyente is useless: the kiosk enrolls again.
  final int? contribuyenteId;
  final int? dispositivoId;

  const MonitoringEnrollmentRecord(
      {required this.deviceToken,
      this.deviceId,
      this.applianceId,
      this.contribuyenteId,
      this.dispositivoId});

  bool isFor({required int contribuyenteId, required int dispositivoId}) =>
      this.contribuyenteId == contribuyenteId && this.dispositivoId == dispositivoId;
}

/// Where the kiosk keeps its monitoring identity. On web SharedPreferences is
/// the browser's localStorage: clearing it makes this kiosk a new device
/// (contracts §1), which support then retires.
class MonitoringStore {
  static const String installationIdKey = 'monitoring.installationId';
  static const String deviceTokenKey = 'monitoring.deviceToken';
  static const String deviceIdKey = 'monitoring.deviceId';
  static const String applianceIdKey = 'monitoring.applianceId';
  static const String contribuyenteKey = 'monitoring.contribuyenteId';
  static const String dispositivoKey = 'monitoring.dispositivoId';

  String? _installationId;

  /// This installation's id, created once and kept. When the storage cannot
  /// be read or written, the id lives in memory for this session.
  Future<String> installationId() async {
    final known = _installationId;
    if (known != null) return known;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(installationIdKey);
      if (saved != null && isUuidV4(saved)) return _installationId = saved;
      final created = newUuidV4();
      _installationId = created;
      await prefs.setString(installationIdKey, created);
      return created;
    } catch (_) {
      return _installationId ??= newUuidV4();
    }
  }

  Future<MonitoringEnrollmentRecord?> enrollment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(deviceTokenKey);
      if (token == null || token.isEmpty) return null;
      return MonitoringEnrollmentRecord(
        deviceToken: token,
        deviceId: prefs.getString(deviceIdKey),
        applianceId: prefs.getString(applianceIdKey),
        contribuyenteId: prefs.getInt(contribuyenteKey),
        dispositivoId: prefs.getInt(dispositivoKey),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveEnrollment(MonitoringEnrollmentRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(deviceTokenKey, record.deviceToken);
      await _setOrRemove(prefs, deviceIdKey, record.deviceId);
      await _setOrRemove(prefs, applianceIdKey, record.applianceId);
      await _setOrRemoveInt(prefs, contribuyenteKey, record.contribuyenteId);
      await _setOrRemoveInt(prefs, dispositivoKey, record.dispositivoId);
    } catch (_) {
      // Storage full or blocked: the kiosk enrolls again on its next launch.
    }
  }

  /// Forgets the device token (revoked, or issued for someone else). The
  /// installation id stays: the next enrollment updates the same device.
  Future<void> clearEnrollment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in [deviceTokenKey, deviceIdKey, applianceIdKey, contribuyenteKey, dispositivoKey]) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  static Future<void> _setOrRemove(SharedPreferences prefs, String key, String? value) =>
      value == null ? prefs.remove(key) : prefs.setString(key, value);

  static Future<void> _setOrRemoveInt(SharedPreferences prefs, String key, int? value) =>
      value == null ? prefs.remove(key) : prefs.setInt(key, value);

  static final Random _random = Random.secure();

  static final RegExp _uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  static bool isUuidV4(String value) => _uuidV4.hasMatch(value);

  /// A random (version 4) UUID.
  static String newUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
        '-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
