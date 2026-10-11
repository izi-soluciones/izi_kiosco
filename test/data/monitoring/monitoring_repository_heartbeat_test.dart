import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_heartbeat_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_heartbeat_response.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';

import '../../helpers/mocks.dart';

/// The gateway, answering what the test sets, and remembering each request.
class _Gateway implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object? body = const {'ok': true};
  Object? error;

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (error != null) throw error!;
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

final _dto = MonitoringHeartbeatDto(
  installationId: '0b7c2a8e-4d1f-4a9b-8c3e-5f6a7b8c9d0e',
  sentAt: DateTime.utc(2026, 10, 12, 14, 3),
  bootId: '6e1f8a3c-9b2d-4c7e-a5f0-1d2e3f4a5b6c',
  uptimeSec: 3600,
  app: const MonitoringApp(version: '2.3.1+45', flavor: 'izify', platform: 'web'),
  state: const {'mode': 'idle', 'pos': {'status': 'ok', 'notReadyReason': 'izd_leaked'}},
  counters: const {'windowStartAt': '2026-10-12T14:02:00.000Z', 'orders': 1},
);

void main() {
  late _Gateway gateway;
  late MonitoringRepositoryHttp repository;

  setUp(() {
    gateway = _Gateway();
    final ingest = Dio(BaseOptions(baseUrl: 'http://gateway.test'))..httpClientAdapter = gateway;
    repository = MonitoringRepositoryHttp(dioClient: MockDioClient(), ingestDio: ingest);
  });

  Future<MonitoringException> failure() async {
    try {
      await repository.heartbeat(_dto, deviceToken: 'izd_secret');
    } on MonitoringException catch (e) {
      return e;
    }
    throw TestFailure('the heartbeat did not fail');
  }

  test('posts the body to the ingest route with the device token, not the kiosk token', () async {
    gateway.body = {
      'ok': true,
      'serverTime': '2026-10-12T14:03:01.000Z',
      'nextInSec': 10,
      'ackSeq': 1234,
      'commands': [
        {'id': 'c1', 'type': 'reload_app', 'args': {}, 'expiresAt': '2026-10-12T14:13:00.000Z'},
        {'type': 'no id'},
      ],
      'config': {},
    };
    final response = await repository.heartbeat(_dto, deviceToken: 'izd_secret');

    final request = gateway.requests.single;
    expect(request.method, 'POST');
    expect(request.path, MonitoringRepositoryHttp.heartbeatPath);
    expect(request.headers['X-Device-Token'], 'izd_secret');
    expect(request.headers.containsKey('X-Public-Token'), isFalse);
    final body = request.data as Map;
    expect(body['schema'], 1);
    expect(body['kind'], 'kiosk');
    expect(body['sentAt'], '2026-10-12T14:03:00.000Z');
    expect(body['uptimeSec'], 3600);
    expect(body['counters'], {'windowStartAt': '2026-10-12T14:02:00.000Z', 'orders': 1});
    expect(jsonEncode(body), isNot(contains('izd_')), reason: 'the body is redacted');

    expect(response.nextInSec, 10);
    expect(response.ackSeq, 1234);
    expect(response.serverTime, DateTime.utc(2026, 10, 12, 14, 3, 1));
    expect(response.commands.single.id, 'c1');
    expect(response.commands.single.type, 'reload_app');
  });

  test('a revoked token is a 401 the kiosk recognises', () async {
    gateway
      ..status = 401
      ..body = {'error': 'device_token_invalid'};
    final error = await failure();
    expect(error.statusCode, 401);
    expect(error.code, MonitoringException.deviceTokenInvalid);
    expect(error.isTokenInvalid, isTrue);
  });

  test('other failures are not a revoked token', () async {
    gateway
      ..status = 401
      ..body = {'error': 'gateway_key_invalid'};
    expect((await failure()).isTokenInvalid, isFalse);

    gateway
      ..status = 503
      ..body = 'down';
    final error = await failure();
    expect(error.cause, 'http_503');
    expect(error.isTokenInvalid, isFalse);
  });

  test('network failures are named in one word', () async {
    gateway.error = DioException(
        requestOptions: RequestOptions(path: MonitoringRepositoryHttp.heartbeatPath),
        type: DioExceptionType.connectionError);
    expect((await failure()).cause, 'unreachable');
  });

  test('an odd 2xx body still counts as accepted', () async {
    gateway.body = 'OK';
    final response = await repository.heartbeat(_dto, deviceToken: 'izd_secret');
    expect(response.nextInSec, isNull);
    expect(response.commands, isEmpty);
  });

  group('response parsing', () {
    test('tolerates odd values', () {
      final response = MonitoringHeartbeatResponse.parse({
        'nextInSec': 'soon',
        'ackSeq': 12.0,
        'commands': 'none',
        'config': [1],
      });
      expect(response.nextInSec, isNull);
      expect(response.ackSeq, 12);
      expect(response.commands, isEmpty);
      expect(response.config, isEmpty);
    });

    test('a command expires at its time', () {
      final command = MonitoringCommand.tryParse(
          {'id': 'c1', 'type': 'reload_app', 'expiresAt': '2026-10-12T14:10:00.000Z'})!;
      expect(command.isExpired(DateTime.utc(2026, 10, 12, 14, 9)), isFalse);
      expect(command.isExpired(DateTime.utc(2026, 10, 12, 14, 10)), isTrue);
      expect(MonitoringCommand.tryParse({'id': 'c2', 'type': 'reload_app'})!
          .isExpired(DateTime.utc(2030)), isFalse);
    });
  });
}
