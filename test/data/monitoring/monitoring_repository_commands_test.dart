import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/domain/dto/monitoring_command_result_dto.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

/// The gateway's ingest routes, answering what the test sets.
class _Gateway implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object? body = const {'ok': true};

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(registerDioFallbacks);

  late _Gateway gateway;
  late MockDioClient dio;
  late MonitoringRepositoryHttp repository;

  setUp(() {
    gateway = _Gateway();
    dio = MockDioClient();
    final ingest = Dio(BaseOptions(baseUrl: 'http://gateway.test'))..httpClientAdapter = gateway;
    repository = MonitoringRepositoryHttp(dioClient: dio, ingestDio: ingest);
  });

  group('enrollment codes', () {
    test('POST /monitoreo/kiosco/codigos-enrolamiento {for}, with the device token', () async {
      when(() => dio.post(
            uri: any(named: 'uri'),
            body: any(named: 'body'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          dioResponse({'code': 'K7Q-4MZ-9TD', 'expiresAt': '2026-10-12T14:30:00.000Z'}));

      final code = await repository.requestEnrollmentCode('terminal', deviceToken: 'izd_tok');

      expect(code.code, 'K7Q-4MZ-9TD');
      expect(code.expiresAt, DateTime.utc(2026, 10, 12, 14, 30));
      final call = verify(() => dio.post(
            uri: captureAny(named: 'uri'),
            body: captureAny(named: 'body'),
            queryParameters: any(named: 'queryParameters'),
            options: captureAny(named: 'options'),
          )).captured;
      expect(call[0], '/monitoreo/kiosco/codigos-enrolamiento');
      expect(call[1], {'for': 'terminal'});
      expect((call[2] as Options).headers, {'X-Device-Token': 'izd_tok'});
    });

    test('an answer without a code is an invalid response', () async {
      when(() => dio.post(
            uri: any(named: 'uri'),
            body: any(named: 'body'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse({'ok': true}));
      expect(() => repository.requestEnrollmentCode('agent', deviceToken: 'izd_tok'),
          throwsA(isA<MonitoringException>().having((e) => e.cause, 'cause', 'invalid_response')));
    });
  });

  group('command results', () {
    final result = MonitoringCommandResultDto(
        commandId: '65f0c0ffee',
        type: 'repair_pos',
        status: MonitoringCommandStatus.rejected,
        data: const {'reason': 'busy'},
        recordedAt: DateTime.utc(2026, 10, 12, 14));

    test('POST /monitoreo/ingesta/comandos/:id/resultado with the contract body', () async {
      await repository.reportCommandResult(result, deviceToken: 'izd_tok');
      final request = gateway.requests.single;
      expect(request.path, '/monitoreo/ingesta/comandos/65f0c0ffee/resultado');
      expect(request.headers['X-Device-Token'], 'izd_tok');
      expect(request.data, {'status': 'rejected', 'data': {'reason': 'busy'}});
    });

    test('a command no longer open is final; a rejected token is not', () async {
      gateway
        ..status = 409
        ..body = {'error': 'command_not_open'};
      final e = await repository
          .reportCommandResult(result, deviceToken: 'izd_tok')
          .then<MonitoringException?>((_) => null, onError: (e) => e as MonitoringException);
      expect(e?.code, 'command_not_open');
      expect(e?.isFinal, isTrue);
      expect(const MonitoringException('http_401', statusCode: 401).isFinal, isFalse);
      expect(const MonitoringException('http_429', statusCode: 429).isFinal, isFalse);
      expect(const MonitoringException('unreachable').isFinal, isFalse);
    });
  });

  group('diagnostics', () {
    test('POST /monitoreo/ingesta/diagnosticos as JSON with the commandId', () async {
      gateway
        ..status = 201
        ..body = {'ok': true, 'id': 'diag1', 'size': 2048, 'expiresAt': '2026-10-26T14:00:00Z'};
      final receipt = await repository.uploadDiagnostics({'kiosk': {'a': 1}},
          commandId: 'cmd1', deviceToken: 'izd_tok');
      expect(receipt.id, 'diag1');
      expect(receipt.size, 2048);
      final request = gateway.requests.single;
      expect(request.path, '/monitoreo/ingesta/diagnosticos');
      expect(request.headers['X-Device-Token'], 'izd_tok');
      expect(request.data, {'kiosk': {'a': 1}, 'commandId': 'cmd1'});
    });
  });

  group('apiBaseUrl', () {
    test('the gateway URL ending in a slash, as the terminal and the agent want it', () {
      expect(MonitoringRepositoryHttp.apiBaseUrl('https://api.app.izisoluciones.com'),
          'https://api.app.izisoluciones.com/');
      expect(MonitoringRepositoryHttp.apiBaseUrl(' http://192.168.0.4:7281/ '),
          'http://192.168.0.4:7281/');
    });

    test('nothing usable: null', () {
      for (final raw in ['', 'api.app.izisoluciones.com', 'ftp://x.test', '   ']) {
        expect(MonitoringRepositoryHttp.apiBaseUrl(raw), isNull, reason: raw);
      }
    });
  });
}
