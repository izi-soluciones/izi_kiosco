import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_agent_link.dart';

typedef _Handler = Future<ResponseBody> Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  _Handler handler;
  final requests = <RequestOptions>[];

  List<RequestOptions> get enrolls => requests.where((r) => r.uri.path == '/enroll').toList();

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

Map<String, dynamic> _health(String status, {bool enrolled = false}) => {
      'schema': 1,
      'kind': 'agent',
      'enrolled': enrolled,
      'status': status,
    };

void main() {
  late _FakeAdapter adapter;
  late Dio dio;
  late DateTime clock;
  late int issued;
  late String? code;
  late BmAgentLink link;
  late Map<String, ResponseBody Function()> routes;

  setUp(() {
    clock = DateTime.utc(2026, 11, 20, 12);
    issued = 0;
    code = 'K7Q-4MZ-9TD';
    routes = {
      '/health': () => _json(_health('not_enrolled')),
      '/enroll': () => _json({'enrolled': true}),
    };
    adapter = _FakeAdapter((o) async => routes[o.uri.path]!());
    dio = Dio()..httpClientAdapter = adapter;
    link = BmAgentLink(
      dio: dio,
      apiBaseUrl: 'https://api.izify.app',
      issueCode: () async {
        issued++;
        return code;
      },
      now: () => clock,
      backoff: (failures) => const Duration(seconds: 30),
    );
  });

  test('agente que no responde: reachable false y no pide código', () async {
    adapter.handler = (o) async => throw DioException(requestOptions: o, type: DioExceptionType.connectionError);
    expect(link.agentState(), {'reachable': false});
    await link.tick();
    expect(link.agentState(), {'reachable': false});
    expect(issued, 0);
    expect(adapter.enrolls, isEmpty);
  });

  test('GET /health con los dos timeouts en 3 s y CancelToken', () async {
    await link.tick();
    final o = adapter.requests.first;
    expect(o.uri.toString(), 'http://127.0.0.1:47800/health');
    expect(o.method, 'GET');
    expect(o.connectTimeout, const Duration(seconds: 3));
    expect(o.receiveTimeout, const Duration(seconds: 3));
    expect(o.cancelToken, isNotNull);
  });

  for (final status in ['enrolling', 'token_unreadable', 'starting', 'ok', 'token_invalid']) {
    test('status $status no pide código', () async {
      routes['/health'] = () => _json(_health(status));
      await link.tick();
      expect(issued, 0);
      expect(adapter.enrolls, isEmpty);
    });
  }

  test('enrolled:true no pide código', () async {
    routes['/health'] = () => _json(_health('ok', enrolled: true));
    await link.tick();
    expect(issued, 0);
    expect(link.agentState(), {'reachable': true, 'enrolled': true});
  });

  test('status not_enrolled pide un código y hace POST /enroll', () async {
    await link.tick();
    expect(issued, 1);
    final o = adapter.enrolls.single;
    expect(o.uri.toString(), 'http://127.0.0.1:47800/enroll');
    expect(o.method, 'POST');
    expect(o.data, {'code': 'K7Q-4MZ-9TD', 'apiBaseUrl': 'https://api.izify.app/'});
    expect(o.headers['Content-Type'], startsWith('application/json'));
    expect(link.agentState(), {'reachable': true, 'enrolled': true});
  });

  test('apiBaseUrl con barra final no se duplica', () async {
    link = BmAgentLink(dio: dio, apiBaseUrl: 'https://api.izify.app/', issueCode: () async => 'X');
    await link.tick();
    expect(adapter.enrolls.single.data['apiBaseUrl'], 'https://api.izify.app/');
  });

  for (final c in [
    [409, 'enrollment_in_progress'],
    [429, 'rate_limited'],
    [502, 'upstream_unavailable'],
    [400, 'enrollment_code_invalid'],
  ]) {
    test('falla de /enroll ${c[0]} ${c[1]}: backoff, sin código nuevo antes', () async {
      routes['/enroll'] = () => _json({'error': c[1]}, status: c[0] as int);
      await link.tick();
      expect(issued, 1);
      expect(link.agentState()['enrolled'], isNot(true));
      clock = clock.add(const Duration(seconds: 29));
      await link.tick();
      expect(issued, 1);
      expect(adapter.enrolls.length, 1);
      clock = clock.add(const Duration(seconds: 2));
      await link.tick();
      expect(issued, 2);
      expect(adapter.enrolls.length, 2);
    });
  }

  for (final c in [
    [409, 'api_base_url_mismatch'],
    [403, 'origin_not_allowed'],
  ]) {
    test('${c[0]} ${c[1]}: no vuelve a pedir código antes de 30 min', () async {
      routes['/enroll'] = () => _json({'error': c[1]}, status: c[0] as int);
      await link.tick();
      expect(issued, 1);
      clock = clock.add(const Duration(minutes: 29, seconds: 59));
      await link.tick();
      expect(issued, 1);
      clock = clock.add(const Duration(seconds: 2));
      await link.tick();
      expect(issued, 2);
    });
  }

  test('issueCode devuelve null: no llama a /enroll', () async {
    code = null;
    await link.tick();
    expect(issued, 1);
    expect(adapter.enrolls, isEmpty);
  });

  test('issueCode que lanza: backoff y tick no lanza', () async {
    link = BmAgentLink(
      dio: dio,
      apiBaseUrl: 'https://api.izify.app',
      issueCode: () async {
        issued++;
        throw StateError('boom');
      },
      now: () => clock,
      backoff: (failures) => const Duration(seconds: 30),
    );
    await link.tick();
    await link.tick();
    expect(issued, 1);
    expect(adapter.enrolls, isEmpty);
  });

  test('issueCode que nunca responde: el timeout libera el enlace y no hay /enroll', () {
    FakeAsync().run((async) {
      link = BmAgentLink(
        dio: dio,
        apiBaseUrl: 'https://api.izify.app',
        issueCode: () {
          issued++;
          return Completer<String?>().future;
        },
        now: () => clock,
        backoff: (failures) => const Duration(seconds: 30),
      );
      link.tick();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 31));
      expect(issued, 1);
      clock = clock.add(const Duration(seconds: 31));
      final before = adapter.requests.length;
      link.tick();
      async.elapse(const Duration(seconds: 1));
      expect(adapter.requests.length, before + 1);
      expect(adapter.enrolls, isEmpty);
      expect(issued, 2);
    });
  });

  test('tick mientras otro está en vuelo no hace una segunda petición', () async {
    final gate = Completer<ResponseBody>();
    adapter.handler = (o) => gate.future;
    final first = link.tick();
    final second = link.tick();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(adapter.requests.length, 1);
    gate.complete(_json(_health('ok', enrolled: true)));
    await Future.wait([first, second]);
    expect(adapter.requests.length, 1);
  });

  test('el backoff por defecto crece de 30 s a 30 min', () async {
    link = BmAgentLink(dio: dio, apiBaseUrl: 'https://api.izify.app', issueCode: () async => 'X', now: () => clock);
    routes['/enroll'] = () => _json({'error': 'upstream_unavailable'}, status: 502);
    await link.tick();
    clock = clock.add(const Duration(seconds: 25));
    await link.tick();
    expect(adapter.enrolls.length, 1);
    clock = clock.add(const Duration(seconds: 12));
    await link.tick();
    expect(adapter.enrolls.length, 2);
    // Tras la segunda falla la espera mínima es 48 s (60 s con jitter -20 %).
    clock = clock.add(const Duration(seconds: 40));
    await link.tick();
    expect(adapter.enrolls.length, 2);
  });
}
