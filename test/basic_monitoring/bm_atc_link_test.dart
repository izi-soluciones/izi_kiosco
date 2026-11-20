import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_atc_link.dart';

typedef _Handler = Future<ResponseBody> Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  _Handler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

DioException _err(RequestOptions o, DioExceptionType type) => DioException(requestOptions: o, type: type);

void main() {
  late _FakeAdapter adapter;
  late Dio dio;
  late DateTime clock;
  late BmAtcLink link;

  setUp(() {
    clock = DateTime.utc(2026, 11, 20, 12);
    adapter = _FakeAdapter((o) async => _json({'connection': true}));
    dio = Dio()..httpClientAdapter = adapter;
    link = BmAtcLink(serverUrl: 'http://localhost:3000', dio: dio, now: () => clock);
  });

  test('check mientras otro está en vuelo no hace una segunda petición', () async {
    final gate = Completer<ResponseBody>();
    adapter.handler = (o) => gate.future;
    final first = link.check();
    final second = link.check();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(adapter.requests.length, 1);
    gate.complete(_json({'connection': true}));
    await Future.wait([first, second]);
    expect(adapter.requests.length, 1);
    expect(link.takeChecks(), 1);
  });

  test('la petición va a /verify-connection con los dos timeouts en 3 s', () async {
    await link.check();
    final o = adapter.requests.single;
    expect(o.uri.toString(), 'http://localhost:3000/verify-connection');
    expect(o.method, 'GET');
    expect(o.connectTimeout, const Duration(seconds: 3));
    expect(o.receiveTimeout, const Duration(seconds: 3));
    expect(o.cancelToken, isNotNull);
  });

  test('ok: status ok, consecutiveFailures 0, lastOkAt seteado y address localhost:3000', () async {
    await link.check();
    final s = link.posState(provider: 'atc');
    expect(s['provider'], 'atc');
    expect(s['status'], 'ok');
    expect(s['consecutiveFailures'], 0);
    expect(s['lastOkAt'], '2026-11-20T12:00:00.000Z');
    expect(s['address'], 'localhost:3000');
    expect(s['lastCause'], isNull);
  });

  test('tres fallas seguidas: status down', () async {
    adapter.handler = (o) async => _json({'connection': false});
    await link.check();
    expect(link.posState(provider: 'atc')['status'], 'degraded');
    await link.check();
    expect(link.posState(provider: 'atc')['status'], 'degraded');
    await link.check();
    final s = link.posState(provider: 'atc');
    expect(s['status'], 'down');
    expect(s['consecutiveFailures'], 3);
  });

  test('una falla y luego ok dentro de 5 min: status degraded', () async {
    adapter.handler = (o) async => _json({'connection': false});
    await link.check();
    clock = clock.add(const Duration(minutes: 1));
    adapter.handler = (o) async => _json({'connection': true});
    await link.check();
    var s = link.posState(provider: 'atc');
    expect(s['status'], 'degraded');
    expect(s['consecutiveFailures'], 0);
    clock = clock.add(const Duration(minutes: 5));
    s = link.posState(provider: 'atc');
    expect(s['status'], 'ok');
  });

  group('causas', () {
    Future<String?> causeOf(_Handler h) async {
      adapter.handler = h;
      await link.check();
      return link.posState(provider: 'atc')['lastCause'] as String?;
    }

    test('timeout', () async {
      expect(await causeOf((o) async => throw _err(o, DioExceptionType.receiveTimeout)), 'timeout');
    });
    test('connectionTimeout', () async {
      expect(await causeOf((o) async => throw _err(o, DioExceptionType.connectionTimeout)), 'timeout');
    });
    test('500', () async {
      expect(await causeOf((o) async => _json({'error': 'x'}, status: 500)), 'http_500');
    });
    test('error de conexión', () async {
      expect(await causeOf((o) async => throw _err(o, DioExceptionType.connectionError)), 'unreachable');
    });
    test('connection false', () async {
      expect(await causeOf((o) async => _json({'connection': false})), 'no_answer');
    });
    test('cuerpo sin connection', () async {
      expect(await causeOf((o) async => _json({'otra': 1})), 'no_answer');
    });
  });

  test('latencyMsP50 es la mediana de las últimas 20', () async {
    final delays = [100, 10, 20, 30, 40];
    var i = 0;
    adapter.handler = (o) async {
      clock = clock.add(Duration(milliseconds: delays[i++]));
      return _json({'connection': true});
    };
    for (var n = 0; n < delays.length; n++) {
      await link.check();
    }
    expect(link.posState(provider: 'atc')['latencyMsP50'], 30);

    adapter.handler = (o) async {
      clock = clock.add(const Duration(milliseconds: 500));
      return _json({'connection': true});
    };
    for (var n = 0; n < 20; n++) {
      await link.check();
    }
    expect(link.posState(provider: 'atc')['latencyMsP50'], 500);
  });

  test('provider none: status not_configured, sin address', () async {
    await link.check();
    final s = link.posState(provider: 'none');
    expect(s['provider'], 'none');
    expect(s['status'], 'not_configured');
    expect(s.containsKey('address'), isFalse);
  });

  test('takeChecks/takeFailures devuelven deltas y vuelven a 0', () async {
    await link.check();
    adapter.handler = (o) async => _json({'connection': false});
    await link.check();
    await link.check();
    expect(link.takeChecks(), 3);
    expect(link.takeFailures(), 2);
    expect(link.takeChecks(), 0);
    expect(link.takeFailures(), 0);
  });

  test('check nunca lanza', () async {
    adapter.handler = (o) async => throw StateError('boom');
    await link.check();
    expect(link.posState(provider: 'atc')['lastCause'], 'unreachable');
  });
}
