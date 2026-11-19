import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/domain/dto/monitoring_command_result_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_events_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_heartbeat_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_enrollment.dart';
import 'package:izi_kiosco/domain/models/monitoring_enrollment_code.dart';
import 'package:izi_kiosco/domain/models/monitoring_events_response.dart';
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
  static const String eventsPath = "/monitoreo/ingesta/eventos";
  static const String codesPath = "/monitoreo/kiosco/codigos-enrolamiento";
  static const String diagnosticsPath = "/monitoreo/ingesta/diagnosticos";
  static const String deviceTokenHeader = "X-Device-Token";

  static String commandResultPath(String commandId) =>
      "/monitoreo/ingesta/comandos/${Uri.encodeComponent(commandId)}/resultado";

  /// The gateway has no timeout of its own for these calls; without one a
  /// stalled request would hold the retries back forever.
  static const Duration timeout = Duration(seconds: 20);

  /// A diagnostics report is up to 2 MB: more time to send it.
  static const Duration diagnosticsTimeout = Duration(seconds: 60);

  /// The gateway the kiosk talks to, as the terminal and the PC agent need
  /// it to enroll (`apiBaseUrl`, contracts §3.3): the `.env` `API_URL`
  /// ending in `/`. Null without one.
  static String? apiBaseUrl([String? raw]) {
    final value =
        (raw ?? (dotenv.isInitialized ? dotenv.maybeGet(EnvKeys.apiUrl) : null))?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return value.endsWith('/') ? value : '$value/';
  }

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
  Future<MonitoringEnrollment> enroll(MonitoringEnrollmentDto dto) => _send(
      () => _dioClient.post(
          uri: enrollmentPath,
          body: dto.toJson(),
          options: Options(
              responseType: ResponseType.json, sendTimeout: timeout, receiveTimeout: timeout)),
      (response) => MonitoringEnrollment.tryParse(response.data) ?? _invalid(response));

  @override
  Future<MonitoringHeartbeatResponse> heartbeat(MonitoringHeartbeatDto dto,
          {required String deviceToken}) =>
      _send(
          () => _ingestDio.post(heartbeatPath,
              data: dto.toJson(), options: Options(headers: {deviceTokenHeader: deviceToken})),
          (response) => MonitoringHeartbeatResponse.parse(response.data));

  @override
  Future<MonitoringEventsResponse> uploadEvents(MonitoringEventsDto dto,
          {required String deviceToken}) =>
      _send(
          () => _ingestDio.post(eventsPath,
              data: dto.toJson(), options: Options(headers: {deviceTokenHeader: deviceToken})),
          (response) => MonitoringEventsResponse.tryParse(response.data) ?? _invalid(response));

  @override
  Future<MonitoringEnrollmentCode> requestEnrollmentCode(String forKind,
          {required String deviceToken}) =>
      _send(
          () => _dioClient.post(
              uri: codesPath,
              body: {'for': forKind},
              options: Options(
                  responseType: ResponseType.json,
                  sendTimeout: timeout,
                  receiveTimeout: timeout,
                  headers: {deviceTokenHeader: deviceToken})),
          (response) => MonitoringEnrollmentCode.tryParse(response.data) ?? _invalid(response));

  @override
  Future<void> reportCommandResult(MonitoringCommandResultDto result,
          {required String deviceToken}) =>
      _send(
          () => _ingestDio.post(commandResultPath(result.commandId),
              data: result.toJson(), options: Options(headers: {deviceTokenHeader: deviceToken})),
          (_) {});

  @override
  Future<MonitoringDiagnosticReceipt> uploadDiagnostics(Map<String, Object?> report,
          {String? commandId, required String deviceToken}) =>
      _send(
          () => _ingestDio.post(diagnosticsPath,
              data: {...report, if (commandId != null) 'commandId': commandId},
              options: Options(
                  headers: {deviceTokenHeader: deviceToken},
                  sendTimeout: diagnosticsTimeout,
                  receiveTimeout: timeout)),
          (response) => MonitoringDiagnosticReceipt.parse(response.data));

  /// Runs [request] and, when it answers a 2xx, [read]s the answer.
  /// Anything else, [read] failing included, becomes a
  /// [MonitoringException]: the only thing these calls throw.
  static Future<T> _send<T>(
      Future<Response> Function() request, T Function(Response response) read) async {
    try {
      final response = await request();
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw MonitoringException('http_$status',
            statusCode: status, code: errorCodeOf(response.data));
      }
      return read(response);
    } on MonitoringException {
      rethrow;
    } on DioException catch (e) {
      throw fromDio(e);
    } catch (_) {
      throw const MonitoringException('error');
    }
  }

  /// A 2xx whose body is not what the contract says.
  static Never _invalid(Response response) =>
      throw MonitoringException('invalid_response', statusCode: response.statusCode);

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
  /// The gateway's `{"bloqueadoPago": true}` has no `error`: it is
  /// [MonitoringException.paymentBlocked].
  static String? errorCodeOf(Object? data) {
    if (data is! Map) return null;
    if (data['bloqueadoPago'] == true && data['error'] == null) {
      return MonitoringException.paymentBlocked;
    }
    final code = data['error'];
    if (code is! String || code.isEmpty) return null;
    return code.length > 60 ? code.substring(0, 60) : code;
  }
}
