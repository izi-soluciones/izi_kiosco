import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';
import 'package:izi_kiosco/domain/dto/monitoring_events_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_events_response.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';

import '../../helpers/mocks.dart';

/// The gateway, answering what the test sets, and remembering each request.
class _Gateway implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object? body;
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

TelemetryEvent _event(int seq,
        {TelemetryLevel level = TelemetryLevel.info, Map<String, Object?> data = const {}}) =>
    TelemetryEvent(
        seq: seq,
        ts: DateTime.utc(2026, 10, 12, 14, 3).toLocal(),
        upMs: 1200,
        type: 'charge.start',
        level: level,
        chargeId: 'CHG-1',
        reference: 'KOS-1760277780000-1',
        data: data);

const _stream = '3f0c2a8e-4d1f-4a9b-8c3e-5f6a7b8c9d0e';

void main() {
  group('MonitoringEventsDto', () {
    test('the contract body: every event, ts in UTC, levels info|warn|error', () {
      final dto = MonitoringEventsDto(
        installationId: '0b7c2a8e-4d1f-4a9b-8c3e-5f6a7b8c9d0e',
        stream: _stream,
        events: [
          for (var i = 1; i <= 30; i++) _event(i),
          _event(31, level: TelemetryLevel.warning),
          _event(32, level: TelemetryLevel.error),
          _event(33, level: TelemetryLevel.debug),
        ],
      );
      final body = dto.toJson();
      expect(body['schema'], 1);
      expect(body['stream'], _stream);
      final events = (body['events'] as List).cast<Map>();
      expect(events, hasLength(33), reason: 'not cut to 20 like a redacted list');
      expect(events.first, {
        'seq': 1,
        'ts': '2026-10-12T14:03:00.000Z',
        'upMs': 1200,
        'type': 'charge.start',
        'level': 'info',
        'chargeId': 'CHG-1',
        'reference': 'KOS-1760277780000-1',
        'data': {},
      });
      expect(events.skip(30).map((e) => e['level']), ['warn', 'error', 'info']);
    });

    test('each event is redacted again', () {
      final json = MonitoringEventsDto.eventJson(
          _event(1, data: {'token': 'abc', 'detail': 'card 4111 1111 1111 1111'}));
      final data = json['data'] as Map;
      expect(data['token'], TelemetryRedactor.mask);
      expect(data['detail'], 'card ${TelemetryRedactor.mask}');
    });
  });

  group('MonitoringRepositoryHttp.uploadEvents', () {
    late _Gateway gateway;
    late MonitoringRepositoryHttp repository;
    final dto = MonitoringEventsDto(
        installationId: '0b7c2a8e-4d1f-4a9b-8c3e-5f6a7b8c9d0e', stream: _stream, events: [_event(7)]);

    setUp(() {
      gateway = _Gateway();
      final ingest = Dio(BaseOptions(baseUrl: 'http://gateway.test'))..httpClientAdapter = gateway;
      repository = MonitoringRepositoryHttp(dioClient: MockDioClient(), ingestDio: ingest);
    });

    Future<MonitoringException> failure() async {
      try {
        await repository.uploadEvents(dto, deviceToken: 'izd_secret');
      } on MonitoringException catch (e) {
        return e;
      }
      throw TestFailure('the upload did not fail');
    }

    test('posts the batch to the ingest route with the device token', () async {
      gateway.body = {'ackSeq': 7, 'stream': _stream, 'accepted': 1, 'duplicates': 0, 'rejected': 0};
      final answer = await repository.uploadEvents(dto, deviceToken: 'izd_secret');

      final request = gateway.requests.single;
      expect(request.method, 'POST');
      expect(request.path, MonitoringRepositoryHttp.eventsPath);
      expect(request.path, '/monitoreo/ingesta/eventos');
      expect(request.headers[MonitoringRepositoryHttp.deviceTokenHeader], 'izd_secret');
      expect(request.headers.containsKey('X-Public-Token'), isFalse);
      expect((request.data as Map)['events'], hasLength(1));
      expect((answer.ackSeq, answer.stream), (7, _stream));
    });

    test('an answer without ackSeq or stream acknowledges nothing', () async {
      gateway.body = {'ok': true};
      expect((await failure()).cause, 'invalid_response');
      expect(MonitoringEventsResponse.tryParse({'ackSeq': -1, 'stream': 's'}), isNull);
      expect(MonitoringEventsResponse.tryParse({'ackSeq': 3.0, 'stream': 's'})!.ackSeq, 3);
    });

    test('a revoked token and a batch too big are told apart', () async {
      gateway.status = 401;
      gateway.body = {'error': 'device_token_invalid'};
      expect((await failure()).isTokenInvalid, isTrue);
      gateway.status = 413;
      gateway.body = {'error': 'payload_too_large'};
      final tooLarge = await failure();
      expect(tooLarge.isTooLarge, isTrue);
      expect(tooLarge.cause, 'http_413');
    });

    test('no network is unreachable', () async {
      gateway.error = DioException(
          requestOptions: RequestOptions(path: '/'), type: DioExceptionType.connectionError);
      expect((await failure()).cause, 'unreachable');
    });
  });
}
