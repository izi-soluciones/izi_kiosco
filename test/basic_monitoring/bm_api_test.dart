import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_api.dart';

class _Call {
  final RequestOptions options;
  final dynamic body;
  _Call(this.options, this.body);

  String? header(String name) {
    for (final e in options.headers.entries) {
      if (e.key.toLowerCase() == name.toLowerCase()) return e.value?.toString();
    }
    return null;
  }
}

class _FakeAdapter implements HttpClientAdapter {
  final calls = <_Call>[];
  final Future<ResponseBody> Function(RequestOptions) responder;

  _FakeAdapter(this.responder);

  factory _FakeAdapter.json(int status, Object? body, {String contentType = 'application/json'}) {
    return _FakeAdapter((_) async => ResponseBody.fromString(
          body is String ? body : jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [contentType],
          },
        ));
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    dynamic body;
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      final text = utf8.decode(bytes);
      try {
        body = jsonDecode(text);
      } catch (_) {
        body = text;
      }
    }
    calls.add(_Call(options, body));
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

BmApi _api(_FakeAdapter adapter, {String apiUrl = 'https://api.test/'}) {
  final dio = Dio()..httpClientAdapter = adapter;
  return BmApi(apiUrl: apiUrl, dio: dio);
}

Future<BmApiException> _failure(Future<void> Function() run) async {
  try {
    await run();
  } on BmApiException catch (e) {
    return e;
  }
  fail('no lanzó BmApiException');
}

const _hb = {'schema': 1};

void main() {
  test('enroll manda POST /monitoreo/kiosco/enrolamiento con X-Public-Token e Izi-Sucursal y sin Authorization', () async {
    final adapter = _FakeAdapter.json(200, {'deviceId': 'd1', 'applianceId': 'a1', 'deviceToken': 'izd_x'});
    final res = await _api(adapter).enroll(publicToken: 'pub', sucursal: 'S1', body: {'schema': 1, 'kind': 'kiosk'});
    final call = adapter.calls.single;
    expect(call.options.method, 'POST');
    expect(call.options.uri.toString(), 'https://api.test/monitoreo/kiosco/enrolamiento');
    expect(call.header('X-Public-Token'), 'pub');
    expect(call.header('Izi-Sucursal'), 'S1');
    expect(call.header('Authorization'), isNull);
    expect(call.body, {'schema': 1, 'kind': 'kiosk'});
    expect(res.deviceId, 'd1');
    expect(res.applianceId, 'a1');
    expect(res.deviceToken, 'izd_x');
  });

  test('enroll sin sucursal no manda Izi-Sucursal', () async {
    final adapter = _FakeAdapter.json(200, {'deviceId': 'd1', 'applianceId': 'a1', 'deviceToken': 't'});
    await _api(adapter, apiUrl: 'https://api.test').enroll(publicToken: 'pub', body: _hb);
    expect(adapter.calls.single.header('Izi-Sucursal'), isNull);
    expect(adapter.calls.single.options.uri.toString(), 'https://api.test/monitoreo/kiosco/enrolamiento');
  });

  test('enroll con 2xx sin deviceToken es transient', () async {
    final adapter = _FakeAdapter.json(200, {'deviceId': 'd1'});
    final e = await _failure(() => _api(adapter).enroll(publicToken: 'pub', body: _hb));
    expect(e.kind, BmFailure.transient);
  });

  test('issueAgentCode manda {"for":"agent"} con X-Public-Token y X-Device-Token y devuelve code', () async {
    final adapter = _FakeAdapter.json(200, {'code': 'K7Q-4MZ-9TD', 'expiresAt': '2026-11-20T10:30:00Z'});
    final code = await _api(adapter).issueAgentCode(publicToken: 'pub', deviceToken: 'izd_x', sucursal: 'S1');
    final call = adapter.calls.single;
    expect(call.options.uri.toString(), 'https://api.test/monitoreo/kiosco/codigos-enrolamiento');
    expect(call.body, {'for': 'agent'});
    expect(call.header('X-Public-Token'), 'pub');
    expect(call.header('X-Device-Token'), 'izd_x');
    expect(call.header('Izi-Sucursal'), 'S1');
    expect(code, 'K7Q-4MZ-9TD');
  });

  test('heartbeat manda X-Device-Token y nunca X-Public-Token', () async {
    final adapter = _FakeAdapter.json(200, {'ok': true, 'serverTime': '2026-11-20T10:00:00Z', 'nextInSec': 60, 'commands': []});
    await _api(adapter).heartbeat(deviceToken: 'izd_x', body: {'schema': 1});
    final call = adapter.calls.single;
    expect(call.options.uri.toString(), 'https://api.test/monitoreo/ingesta/heartbeat');
    expect(call.header('X-Device-Token'), 'izd_x');
    expect(call.header('X-Public-Token'), isNull);
    expect(call.body, {'schema': 1});
  });

  test('heartbeat lee serverTime, commands y nextInSec', () async {
    final adapter = _FakeAdapter.json(200, {
      'ok': true,
      'serverTime': '2026-11-20T10:00:00.000Z',
      'nextInSec': 10,
      'commands': [
        {'id': 'c1', 'type': 'reload_app', 'args': {'a': 1}, 'expiresAt': '2026-11-20T10:10:00.000Z'},
        {'id': 'c2', 'type': 'repair_pos'},
        {'type': 'sin_id'},
      ],
    });
    final res = await _api(adapter).heartbeat(deviceToken: 't', body: _hb);
    expect(res.serverTime, DateTime.utc(2026, 11, 20, 10));
    expect(res.nextInSec, 10);
    expect(res.commands.map((c) => c.id), ['c1', 'c2']);
    expect(res.commands[0].type, 'reload_app');
    expect(res.commands[0].args, {'a': 1});
    expect(res.commands[0].expiresAt, DateTime.utc(2026, 11, 20, 10, 10));
    expect(res.commands[1].args, <String, dynamic>{});
    expect(res.commands[1].expiresAt, isNull);
  });

  test('nextInSec falta queda en 60, 5 se acota a 10 y 99999 a 3600', () async {
    Future<int> next(Map<String, dynamic> body) async {
      final res = await _api(_FakeAdapter.json(200, body)).heartbeat(deviceToken: 't', body: _hb);
      return res.nextInSec;
    }

    expect(await next({'ok': true}), 60);
    expect(await next({'nextInSec': 5}), 10);
    expect(await next({'nextInSec': 99999}), 3600);
    expect(await next({'nextInSec': 'x'}), 60);
  });

  test('commandResult manda POST a comandos/:id/resultado con X-Device-Token', () async {
    final adapter = _FakeAdapter.json(200, {'ok': true});
    await _api(adapter).commandResult(deviceToken: 'izd_x', id: 'c 1', body: {'status': 'rejected', 'detail': 'unsupported'});
    final call = adapter.calls.single;
    expect(call.options.uri.toString(), 'https://api.test/monitoreo/ingesta/comandos/c%201/resultado');
    expect(call.header('X-Device-Token'), 'izd_x');
    expect(call.body, {'status': 'rejected', 'detail': 'unsupported'});
  });

  group('mapeo de errores', () {
    Future<BmApiException> hb(_FakeAdapter adapter) => _failure(() => _api(adapter).heartbeat(deviceToken: 't', body: _hb));

    test('401 con device_token_invalid es tokenInvalid', () async {
      final e = await hb(_FakeAdapter.json(401, {'error': 'device_token_invalid'}));
      expect(e.kind, BmFailure.tokenInvalid);
      expect(e.status, 401);
      expect(e.code, 'device_token_invalid');
    });

    test('cualquier otro 401 es transient', () async {
      for (final body in <Object?>[
        {'error': 'gateway_key_invalid'},
        {'bloqueadoPago': true},
        {'error': 'Token inválido'},
        'Unauthorized',
        ['device_token_invalid'],
      ]) {
        final e = await hb(_FakeAdapter.json(401, body, contentType: body is String ? 'text/plain' : 'application/json'));
        expect(e.kind, BmFailure.transient, reason: '$body');
        expect(e.status, 401);
      }
    });

    test('400, 411, 413 y 415 son rejected, con code si el cuerpo es un Map', () async {
      for (final status in [400, 411, 413, 415]) {
        final e = await hb(_FakeAdapter.json(status, {'error': 'validation_error'}));
        expect(e.kind, BmFailure.rejected, reason: '$status');
        expect(e.status, status);
        expect(e.code, 'validation_error');
      }
      final e = await hb(_FakeAdapter.json(400, 'texto', contentType: 'text/plain'));
      expect(e.kind, BmFailure.rejected);
      expect(e.code, isNull);
    });

    test('403 y 405 en text/plain, 404, 429 y 503 son transient', () async {
      for (final status in [403, 405, 404, 429, 503, 500, 502]) {
        final e = await hb(_FakeAdapter.json(status, 'Route not allowed', contentType: 'text/plain'));
        expect(e.kind, BmFailure.transient, reason: '$status');
        expect(e.status, status);
      }
      final e = await hb(_FakeAdapter.json(503, {'error': 'monitoreo_no_disponible'}));
      expect(e.kind, BmFailure.transient);
      expect(e.code, 'monitoreo_no_disponible');
    });

    test('timeout y error de red son transient', () async {
      for (final type in [DioExceptionType.connectionTimeout, DioExceptionType.receiveTimeout, DioExceptionType.connectionError]) {
        final adapter = _FakeAdapter((o) async => throw DioException(requestOptions: o, type: type));
        final e = await hb(adapter);
        expect(e.kind, BmFailure.transient, reason: '$type');
        expect(e.status, isNull);
      }
    });

    test('2xx con cuerpo inesperado es transient', () async {
      final e = await hb(_FakeAdapter.json(200, 'no json', contentType: 'text/plain'));
      expect(e.kind, BmFailure.transient);
    });

    test('commandResult mapea igual', () async {
      final e = await _failure(() => _api(_FakeAdapter.json(401, {'error': 'device_token_invalid'})).commandResult(deviceToken: 't', id: 'c', body: {}));
      expect(e.kind, BmFailure.tokenInvalid);
    });
  });

  test('todo POST lleva Content-Type application/json', () async {
    final adapter = _FakeAdapter.json(200, {'deviceId': 'd', 'applianceId': 'a', 'deviceToken': 't', 'code': 'C', 'ok': true});
    final api = _api(adapter);
    await api.enroll(publicToken: 'p', body: _hb);
    await api.issueAgentCode(publicToken: 'p', deviceToken: 't');
    await api.heartbeat(deviceToken: 't', body: _hb);
    await api.commandResult(deviceToken: 't', id: 'c', body: {'status': 'succeeded'});
    expect(adapter.calls, hasLength(4));
    for (final c in adapter.calls) {
      expect(c.options.method, 'POST');
      expect(c.header('Content-Type'), startsWith('application/json'));
    }
  });

  test('ninguna petición lleva Authorization ni Izi-Contribuyente', () async {
    final adapter = _FakeAdapter.json(200, {'deviceId': 'd', 'applianceId': 'a', 'deviceToken': 't', 'code': 'C', 'ok': true});
    final api = _api(adapter);
    await api.enroll(publicToken: 'p', sucursal: 's', body: _hb);
    await api.issueAgentCode(publicToken: 'p', deviceToken: 't', sucursal: 's');
    await api.heartbeat(deviceToken: 't', body: _hb);
    await api.commandResult(deviceToken: 't', id: 'c', body: {'status': 'succeeded'});
    for (final c in adapter.calls) {
      expect(c.header('Authorization'), isNull);
      expect(c.header('Izi-Contribuyente'), isNull);
    }
  });

  test('timeouts propios: conexión 10 s y recepción 15 s', () {
    final api = BmApi(apiUrl: 'https://api.test');
    expect(api.debugDio.options.connectTimeout, const Duration(seconds: 10));
    expect(api.debugDio.options.receiveTimeout, const Duration(seconds: 15));
  });
}
