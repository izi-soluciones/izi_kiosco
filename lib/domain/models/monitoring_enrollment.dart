/// What the monitoring service answers when this kiosk enrolls
/// (`POST /monitoreo/kiosco/enrolamiento`).
///
/// [deviceToken] (`izd_...`) is returned only once: it is what the kiosk
/// presents as `X-Device-Token` from then on. Never log it.
class MonitoringEnrollment {
  final String deviceId;
  final String applianceId;
  final String deviceToken;

  const MonitoringEnrollment(
      {required this.deviceId,
      required this.applianceId,
      required this.deviceToken});

  /// Null when the answer lacks any of the three values: a half enrollment
  /// is no enrollment.
  static MonitoringEnrollment? tryParse(Object? json) {
    if (json is! Map) return null;
    final deviceId = json['deviceId'];
    final applianceId = json['applianceId'];
    final deviceToken = json['deviceToken'];
    if (deviceId is! String || deviceId.isEmpty) return null;
    if (applianceId is! String || applianceId.isEmpty) return null;
    if (deviceToken is! String || deviceToken.isEmpty) return null;
    return MonitoringEnrollment(
        deviceId: deviceId, applianceId: applianceId, deviceToken: deviceToken);
  }
}
