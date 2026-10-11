import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_heartbeat_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_enrollment.dart';
import 'package:izi_kiosco/domain/models/monitoring_heartbeat_response.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';

/// The monitoring service (`izi-ms-monitoreo`) through the gateway, which
/// mounts it under `/monitoreo`. Kiosk routes carry the kiosk token like
/// every other call of [DioClient].
///
/// Ingest routes (`/monitoreo/ingesta/*`) carry the device token instead,
/// on a client of their own: the kiosk's iZi token has no business there.
class MonitoringRepositoryHttp extends MonitoringRepository {
  static const String enrollmentPath = "/monitoreo/kiosco/enrolamiento";
  static const String heartbeatPath = "/monitoreo/ingesta/heartbeat";
  static const String deviceTokenHeader = "X-Device-Token";

  /// The gateway has no timeout of its own for these calls; without one a
  /// stalled request would hold the retries back forever.
  static const Duration timeout = Duration(seconds: 20);

  final DioClient _dioClient;
  final Dio? _givenIngestDio;

  // Created on first use, like [DioClient]: the API URL comes from the
  // loaded `.env`.
  late final Dio _ingestDio = _givenIngestDio ??
      Dio(BaseOptions(
        baseUrl: dotenv.env[EnvKeys.apiUrl] ?? "",
        connectTimeout: timeout,
        sendTimeout: timeout,
        receiveTimeout: timeout,
        responseType: ResponseType.json,
      ));

  MonitoringRepositoryHttp({DioClient? dioClient, Dio? ingestDio})
      : _dioClient = dioClient ?? DioClient(),
        _givenIngestDio = ingestDio;

  @override
  Future<MonitoringEnrollment> enroll(MonitoringEnrollmentDto dto) async {
    try {
      final response = await _dioClient.post(
          uri: enrollmentPath,
          body: dto.toJson(),
          options: Options(
              responseType: ResponseType.json,
              sendTimeout: timeout,
              receiveTimeout: timeout));
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw MonitoringException('http_$status',
            statusCode: status, code: errorCodeOf(response.data));
      }
      final enrollment = MonitoringEnrollment.tryParse(response.data);
      if (enrollment == null) {
        throw MonitoringException('invalid_response', statusCode: status);
      }
      return enrollment;
    } on MonitoringException {
      rethrow;
    } on DioException catch (e) {
      throw fromDio(e);
    } catch (_) {
      throw const MonitoringException('error');
    }
  }

  @override
  Future<MonitoringHeartbeatResponse> heartbeat(MonitoringHeartbeatDto dto,
      {required String deviceToken}) async {
    try {
      final response = await _ingestDio.post(heartbeatPath,
          data: dto.toJson(),
          options: Options(headers: {deviceTokenHeader: deviceToken}));
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw MonitoringException('http_$status',
            statusCode: status, code: errorCodeOf(response.data));
      }
      return MonitoringHeartbeatResponse.parse(response.data);
    } on MonitoringException {
      rethrow;
    } on DioException catch (e) {
      throw fromDio(e);
    } catch (_) {
      throw const MonitoringException('error');
    }
  }

  static MonitoringException fromDio(DioException e) {
    final status = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const MonitoringException('timeout');
      case DioExceptionType.connectionError:
        return const MonitoringException('unreachable');
      case DioExceptionType.cancel:
        return const MonitoringException('cancelled');
      case DioExceptionType.badResponse:
        return MonitoringException('http_${status ?? 0}',
            statusCode: status, code: errorCodeOf(e.response?.data));
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        // On web a refused or CORS-blocked request lands here, without a status.
        if (status != null) {
          return MonitoringException('http_$status',
              statusCode: status, code: errorCodeOf(e.response?.data));
        }
        return const MonitoringException('unreachable');
    }
  }

  /// The service's `{"error": "<code>"}`, kept short: it goes to telemetry.
  static String? errorCodeOf(Object? data) {
    if (data is! Map) return null;
    final code = data['error'];
    if (code is! String || code.isEmpty) return null;
    return code.length > 60 ? code.substring(0, 60) : code;
  }
}
