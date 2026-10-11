import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_heartbeat_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_enrollment.dart';
import 'package:izi_kiosco/domain/models/monitoring_heartbeat_response.dart';

abstract class MonitoringRepository {
  /// Enrolls this kiosk installation in the monitoring service. Enrolling
  /// the same installation again revokes its previous device token.
  ///
  /// Throws [MonitoringException].
  Future<MonitoringEnrollment> enroll(MonitoringEnrollmentDto dto);

  /// Reports this kiosk's state and counters, with its [deviceToken]
  /// (`X-Device-Token`). Answers with what the service wants next.
  ///
  /// Throws [MonitoringException]: a revoked or unknown token is a 401 with
  /// code [MonitoringException.deviceTokenInvalid].
  Future<MonitoringHeartbeatResponse> heartbeat(MonitoringHeartbeatDto dto,
      {required String deviceToken});
}

/// Why a call to the monitoring service failed.
class MonitoringException implements Exception {
  /// The service no longer accepts the device token (contracts §2).
  static const String deviceTokenInvalid = 'device_token_invalid';

  /// One word, stable for telemetry: `timeout`, `unreachable`, `http_<status>`,
  /// `invalid_response`, `cancelled` or `error`.
  final String cause;

  /// The HTTP status, when the service answered.
  final int? statusCode;

  /// The service's `error` code (`device_token_invalid`...), when it gave one.
  final String? code;

  const MonitoringException(this.cause, {this.statusCode, this.code});

  /// The token was revoked or is unknown: the kiosk has to enroll again.
  bool get isTokenInvalid => statusCode == 401 && code == deviceTokenInvalid;

  @override
  String toString() =>
      'MonitoringException($cause${code == null ? '' : ', $code'})';
}
