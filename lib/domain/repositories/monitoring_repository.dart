import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_enrollment.dart';

abstract class MonitoringRepository {
  /// Enrolls this kiosk installation in the monitoring service. Enrolling
  /// the same installation again revokes its previous device token.
  ///
  /// Throws [MonitoringException].
  Future<MonitoringEnrollment> enroll(MonitoringEnrollmentDto dto);
}

/// Why a call to the monitoring service failed.
class MonitoringException implements Exception {
  /// One word, stable for telemetry: `timeout`, `unreachable`, `http_<status>`,
  /// `invalid_response`, `cancelled` or `error`.
  final String cause;

  /// The HTTP status, when the service answered.
  final int? statusCode;

  /// The service's `error` code (`device_token_invalid`...), when it gave one.
  final String? code;

  const MonitoringException(this.cause, {this.statusCode, this.code});

  @override
  String toString() =>
      'MonitoringException($cause${code == null ? '' : ', $code'})';
}
