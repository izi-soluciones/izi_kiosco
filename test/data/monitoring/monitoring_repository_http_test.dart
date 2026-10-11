import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

const _dto = MonitoringEnrollmentDto(
  installationId: '0b7c2a8e-4d1f-4a9b-8c3e-5f6a7b8c9d0e',
  app: MonitoringApp(version: '2.3.1+45', flavor: 'izify', platform: 'web'),
  deviceName: 'KIOSKO-01',
  contribuyenteNombre: 'Gasaje',
  sucursalNombre: 'Casa Matriz',
  pais: 'CO',
);

void main() {
  setUpAll(registerDioFallbacks);

  late MockDioClient dio;
  late MonitoringRepositoryHttp repository;

  setUp(() {
    dio = MockDioClient();
    repository = MonitoringRepositoryHttp(dioClient: dio);
  });

  void answer(Future<Response<dynamic>> Function() reply) => when(() => dio.post(
        uri: any(named: 'uri'),
        body: any(named: 'body'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenAnswer((_) => reply());

  void reject(DioException error) => when(() => dio.post(
        uri: any(named: 'uri'),
        body: any(named: 'body'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
      )).thenThrow(error);

  DioException dioError(DioExceptionType type, {int? status, Object? data}) => DioException(
        requestOptions: RequestOptions(path: MonitoringRepositoryHttp.enrollmentPath),
        type: type,
        response: status == null
            ? null
            : Response(
                requestOptions: RequestOptions(path: MonitoringRepositoryHttp.enrollmentPath),
                statusCode: status,
                data: data),
      );

  Future<MonitoringException> failure() async {
    try {
      await repository.enroll(_dto);
    } on MonitoringException catch (e) {
      return e;
    }
    throw TestFailure('enroll did not fail');
  }

  test('posts the contract body to the gateway enrollment route, with timeouts', () async {
    answer(() async => dioResponse(
        {'deviceId': 'd1', 'applianceId': 'a1', 'deviceToken': 'izd_abc'},
        statusCode: 201));

    final enrollment = await repository.enroll(_dto);

    expect(enrollment.deviceId, 'd1');
    expect(enrollment.applianceId, 'a1');
    expect(enrollment.deviceToken, 'izd_abc');
    final captured = verify(() => dio.post(
          uri: captureAny(named: 'uri'),
          body: captureAny(named: 'body'),
          queryParameters: any(named: 'queryParameters'),
          options: captureAny(named: 'options'),
        )).captured;
    expect(captured[0], '/monitoreo/kiosco/enrolamiento');
    expect(captured[1], {
      'schema': 1,
      'installationId': '0b7c2a8e-4d1f-4a9b-8c3e-5f6a7b8c9d0e',
      'kind': 'kiosk',
      'app': {'version': '2.3.1+45', 'flavor': 'izify', 'platform': 'web'},
      'deviceName': 'KIOSKO-01',
      'business': {'contribuyenteNombre': 'Gasaje', 'sucursalNombre': 'Casa Matriz', 'pais': 'CO'},
    });
    final options = captured[2] as Options;
    // No-auth is not set: the interceptor adds the kiosk token.
    expect(options.headers?.containsKey('no-auth') ?? false, isFalse);
    expect(options.receiveTimeout, MonitoringRepositoryHttp.timeout);
    expect(options.sendTimeout, MonitoringRepositoryHttp.timeout);
  });

  test('an answer without the token is not an enrollment', () async {
    answer(() async => dioResponse({'deviceId': 'd1', 'applianceId': 'a1'}));
    final e = await failure();
    expect(e.cause, 'invalid_response');
  });

  test('a non-2xx answer that Dio did not reject carries its status and code', () async {
    answer(() async => dioResponse({'error': 'gateway_key_invalid'}, statusCode: 401));
    final e = await failure();
    expect(e.cause, 'http_401');
    expect(e.statusCode, 401);
    expect(e.code, 'gateway_key_invalid');
  });

  test('a rejected request carries its status and the service code', () async {
    reject(dioError(DioExceptionType.badResponse, status: 503, data: {'error': 'mongo_down'}));
    final e = await failure();
    expect(e.cause, 'http_503');
    expect(e.code, 'mongo_down');
  });

  test('network failures are named in one word', () async {
    reject(dioError(DioExceptionType.receiveTimeout));
    expect((await failure()).cause, 'timeout');
    reject(dioError(DioExceptionType.connectionTimeout));
    expect((await failure()).cause, 'timeout');
    reject(dioError(DioExceptionType.connectionError));
    expect((await failure()).cause, 'unreachable');
    // Web: a refused or CORS-blocked XHR has no status.
    reject(dioError(DioExceptionType.unknown));
    expect((await failure()).cause, 'unreachable');
  });

  test('an unexpected error is still a MonitoringException', () async {
    when(() => dio.post(
          uri: any(named: 'uri'),
          body: any(named: 'body'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenThrow(StateError('boom'));
    expect((await failure()).cause, 'error');
  });

  test('a long service code is cut for telemetry', () {
    expect(MonitoringRepositoryHttp.errorCodeOf({'error': 'x' * 100})!.length, 60);
    expect(MonitoringRepositoryHttp.errorCodeOf('<html>'), isNull);
  });
}
