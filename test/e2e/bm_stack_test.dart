// Prueba de punta a punta del monitoreo básico contra el stack local del epic 86e3p0423
// (MeshCentral, izi-ms-monitoreo, gateway izi-ms-auth). La web no puede iniciar sesión en local
// (no hay backbone): el módulo se ejercita con este arnés, sin la app.
//
// Corre fuera de la suite normal (tag e2e, omitida por dart_test.yaml). Con --coverage el VM service
// queda abierto y el arnés lee de ahí las líneas de log del módulo (developer.log, nombre `monitoreo`).
//
//   flutter test --coverage --coverage-path=/tmp/bm_e2e.lcov -t e2e --run-skipped test/e2e \
//     --dart-define=BM_E2E_API_URL=http://127.0.0.1:7281 \
//     --dart-define=BM_E2E_PUBLIC_TOKEN=<JWT firmado con JWT_SECRET_PUBLIC del gateway local> \
//     --dart-define=BM_E2E_MS_URL=http://127.0.0.1:7110 --dart-define=BM_E2E_SERVICE_KEY=<SERVICE_KEY>
//
// Opcionales: BM_E2E_AGENT=1 (hay un agente real en 127.0.0.1:47800), BM_E2E_MS_DOWN_CMD y
// BM_E2E_MS_UP_CMD (comandos de shell que detienen y levantan el ms), BM_E2E_TIME_SCALE (los
// temporizadores del servicio se dividen por este factor, 10 por defecto).
@Tags(['e2e'])
@Timeout(Duration(minutes: 5))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_agent_link.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_service.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _apiUrl = String.fromEnvironment('BM_E2E_API_URL');
const _publicToken = String.fromEnvironment('BM_E2E_PUBLIC_TOKEN');
const _msUrl = String.fromEnvironment('BM_E2E_MS_URL');
const _serviceKey = String.fromEnvironment('BM_E2E_SERVICE_KEY');
const _withAgent = String.fromEnvironment('BM_E2E_AGENT') == '1';
const _msDownCmd = String.fromEnvironment('BM_E2E_MS_DOWN_CMD');
const _msUpCmd = String.fromEnvironment('BM_E2E_MS_UP_CMD');
const _timeScale = int.fromEnvironment('BM_E2E_TIME_SCALE', defaultValue: 10);

class _Logs {
  final lines = <String>[];
  WebSocket? _ws;

  Future<bool> attach() async {
    final info = await developer.Service.getInfo();
    final uri = info.serverUri;
    if (uri == null) return false;
    final ws = _ws = await WebSocket.connect(uri.replace(scheme: 'ws', path: '${uri.path}ws').toString());
    ws.listen((raw) {
      final msg = jsonDecode(raw as String);
      if (msg is! Map || msg['method'] != 'streamNotify') return;
      final event = msg['params']?['event'];
      if (event is! Map || event['kind'] != 'Logging') return;
      final record = event['logRecord'];
      if (record is! Map || record['loggerName']?['valueAsString'] != 'monitoreo') return;
      lines.add(record['message']['valueAsString'] as String);
    });
    ws.add(jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'streamListen', 'params': {'streamId': 'Logging'}}));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<void> close() async => _ws?.close();

  int count(String needle) => lines.where((l) => l.contains(needle)).length;
}

class _Ms {
  final _dio = Dio(BaseOptions(baseUrl: '$_msUrl/api/v1', validateStatus: (_) => true));
  Options get _opts => Options(headers: {
        'X-Service-Key': _serviceKey,
        'X-Staff-Email': 'dev.admin@izisoluciones.com',
        'X-Staff-Role': 'admin',
      });

  Future<dynamic> get(String path) async => (await _dio.get<dynamic>(path, options: _opts)).data;

  Future<Response<dynamic>> send(String method, String path, Map<String, dynamic> body) =>
      _dio.request<dynamic>(path, data: body, options: _opts.copyWith(method: method));
}

Future<T> _until<T>(String what, Future<T?> Function() probe, {Duration timeout = const Duration(seconds: 90)}) async {
  final end = DateTime.now().add(timeout);
  Object? last;
  while (DateTime.now().isBefore(end)) {
    try {
      final v = await probe();
      if (v != null) return v;
    } catch (e) {
      last = e;
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw TestFailure('timeout esperando: $what${last != null ? ' (último error: $last)' : ''}');
}

Future<void> _sh(String cmd) async {
  final r = await Process.run('sh', ['-c', cmd]);
  if (r.exitCode != 0) throw TestFailure('comando falló (${r.exitCode}): ${r.stderr}');
}

void main() {
  final enabled = _apiUrl.isNotEmpty && _publicToken.isNotEmpty;
  final hasMs = _msUrl.isNotEmpty && _serviceKey.isNotEmpty;
  final logs = _Logs();
  final ms = _Ms();
  late HttpServer atcStub;
  late SharedPreferences prefs;
  late BmStore store;
  String? deviceId() => prefs.getString('bm.deviceId');
  late BmService service;
  late BmContext ctx;
  var logsAttached = false;

  Future<Map<String, dynamic>?> findKiosk() async {
    final res = await ms.get('/staff/flota?contribuyente=${ctx.contribuyente}');
    final items = res is Map ? (res['items'] ?? res['appliances'] ?? res['data']) : res;
    if (items is! List) return null;
    for (final a in items) {
      for (final m in (a['members'] ?? a['miembros'] ?? a['dispositivos'] ?? const []) as List) {
        if (m['deviceId'] == deviceId()) return {'appliance': a, 'member': m};
      }
    }
    return null;
  }

  setUpAll(() async {
    if (!enabled) return;
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = BmStore(prefs);
    logsAttached = await logs.attach();
    atcStub = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    atcStub.listen((req) {
      req.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'connection': true}))
        ..close();
    });
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(_publicToken.split('.')[1])))) as Map;
    ctx = BmContext(
      publicToken: _publicToken,
      contribuyente: (payload['contribuyente'] as num).toInt(),
      dispositivo: (payload['dispositivo'] as num).toInt(),
      sucursal: '1',
      deviceName: 'E2E-ARNES',
      flavor: 'izify',
      version: '0.0.0-e2e+1',
      platform: 'web',
      country: 'BO',
      provider: 'atc',
      apiUrl: _apiUrl,
      atcServerUrl: 'http://127.0.0.1:${atcStub.port}',
    );
    // kIsWeb es false en la VM: isWeb activa los enlaces ATC y agente. El Origin que el navegador pone
    // solo en el POST /enroll del agente se agrega con un interceptor (sin él, 403 origin_not_allowed).
    service = BmService(
      storeFactory: () async => store,
      isWeb: true,
      timer: (d, cb) => Timer(Duration(milliseconds: d.inMilliseconds ~/ _timeScale), cb),
      agentFactory: (c, issueCode) => BmAgentLink(
        dio: Dio()..interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
              o.headers['Origin'] = 'http://localhost';
              h.next(o);
            })),
        issueCode: issueCode,
        apiBaseUrl: c.apiUrl,
        backoff: (f) => Duration(milliseconds: 30000 ~/ _timeScale),
      ),
    );
  });

  tearDownAll(() async {
    if (!enabled) return;
    service.stop();
    await atcStub.close(force: true);
    await logs.close();
  });

  const skipReason = 'definir BM_E2E_API_URL y BM_E2E_PUBLIC_TOKEN con --dart-define';

  test('paso 2: registro y heartbeats, el kiosco aparece en línea con pos.provider y agent', () async {
    service.start(ctx);
    await _until('token de dispositivo guardado', () async => store.deviceToken);
    expect(store.owner, ctx.owner);
    await _until('heartbeat aceptado en el log', () async => logs.count('heartbeat aceptado') > 0 ? true : null,
        timeout: const Duration(seconds: 20));
    if (!logsAttached) markTestSkipped('sin VM service: ejecutar con --coverage para leer el log');
    expect(logs.count('kiosco registrado'), 1);
    if (!hasMs) return;
    final found = await _until('kiosco en la flota del ms', findKiosk, timeout: const Duration(seconds: 30));
    expect((found['member'] as Map)['kind'], 'kiosk');
    final id = deviceId();
    final detail = await ms.get('/staff/dispositivos/$id');
    // ignore: avoid_print
    print('DISPOSITIVO ${jsonEncode(detail)}');
    final state = (detail as Map)['latestState'] as Map;
    expect((detail['health'] as Map)['status'], 'online');
    expect((state['pos'] as Map)['provider'], 'atc');
    expect((state['pos'] as Map)['status'], 'ok');
    expect(state['agent'], isA<Map>());
    // El primer heartbeat sale antes del primer tick del enlace con el agente: reachable puede ser false.
    // ignore: avoid_print
    print('AGENT EN EL PRIMER HEARTBEAT ${jsonEncode(state['agent'])}');
    final first = (detail['lastHeartbeat'] as Map)['receivedAt'];
    final next = await _until('segundo heartbeat en el ms', () async {
      final d = await ms.get('/staff/dispositivos/$id') as Map;
      return (d['lastHeartbeat'] as Map)['receivedAt'] != first ? d : null;
    }, timeout: const Duration(seconds: 30));
    expect(((next['lastHeartbeat'] as Map)['uptimeSec'] as num) > 0, isTrue);
    final agent = (next['latestState'] as Map)['agent'] as Map;
    // ignore: avoid_print
    print('AGENT EN EL SEGUNDO HEARTBEAT ${jsonEncode(agent)}');
    expect(agent['reachable'], _withAgent);
  }, skip: enabled ? false : skipReason);

  test('paso 3: el agente real queda enrolado en el mismo kiosco instalado', () async {
    final url = Uri.parse('http://127.0.0.1:47800/health');
    final health = await _until('/health del agente', () async {
      final r = await Dio().getUri<dynamic>(url, options: Options(validateStatus: (_) => true));
      return r.statusCode == 200 ? r.data : null;
    }, timeout: const Duration(seconds: 15));
    // ignore: avoid_print
    print('AGENT /health inicial ${jsonEncode(health)}');
    await _until('agente enrolado por el kiosco', () async {
      final r = await Dio().getUri<dynamic>(url, options: Options(validateStatus: (_) => true));
      return r.data is Map && r.data['enrolled'] == true ? r.data : null;
    });
    if (!hasMs) return;
    final id = deviceId();
    final found = await _until('agente en el mismo appliance', () async {
      final f = await findKiosk();
      final members = ((f?['appliance'] as Map?)?['members'] ?? (f?['appliance'] as Map?)?['miembros'] ?? const []) as List;
      // ignore: avoid_print
      print('MIEMBROS ${jsonEncode(members)}');
      return members.any((m) => m['kind'] == 'agent') ? f : null;
    }, timeout: const Duration(seconds: 120));
    // ignore: avoid_print
    print('APPLIANCE ${jsonEncode(found!['appliance'])} kiosk=$id');
    final members = ((found['appliance'] as Map)['members'] as List).map((m) => m['kind']).toList();
    expect(members, containsAll(['kiosk', 'agent']));
  }, skip: enabled && _withAgent ? false : 'requiere BM_E2E_AGENT=1 y un agente corriendo');

  test('paso 4a: ms detenido, el arnés no lanza y el log tiene una línea por cambio de estado', () async {
    await _sh(_msDownCmd);
    final before = logs.count('no disponible');
    await _until('línea de fallo en el log', () async => logs.count('no disponible') > before ? true : null,
        timeout: const Duration(seconds: 40));
    await Future<void>.delayed(const Duration(seconds: 15));
    expect(logs.count('no disponible') - before, 1, reason: 'una línea por cambio de estado, no una por intento');
    final ok = logs.count('heartbeat aceptado');
    await _sh(_msUpCmd);
    await _until('heartbeat aceptado otra vez', () async => logs.count('heartbeat aceptado') > ok ? true : null,
        timeout: const Duration(seconds: 120));
    // ignore: avoid_print
    print('LOG ${jsonEncode(logs.lines)}');
  }, skip: enabled && _msDownCmd.isNotEmpty && _msUpCmd.isNotEmpty ? false : 'requiere BM_E2E_MS_DOWN_CMD y BM_E2E_MS_UP_CMD',
      timeout: const Timeout(Duration(minutes: 5)));

  test('paso 4b: reload_app desde la consola es rechazado unsupported y no toca nada', () async {
    final id = deviceId();
    final res = await ms.send('POST', '/staff/dispositivos/$id/comandos',
        {'type': 'reload_app', 'args': <String, dynamic>{}, 'reason': 'prueba e2e monitoreo basico'});
    // ignore: avoid_print
    print('CREAR COMANDO ${res.statusCode} ${jsonEncode(res.data)}');
    expect(res.statusCode, inInclusiveRange(200, 299));
    final done = await _until<Map>('comando resuelto', () async {
      final list = await ms.get('/staff/dispositivos/$id/comandos');
      final items = (list is Map ? (list['items'] ?? list['data'] ?? list['comandos']) : list) as List;
      final c = items.firstWhere((x) => x['type'] == 'reload_app', orElse: () => null);
      return c != null && c['status'] != 'pending' && c['status'] != 'delivered' ? c as Map : null;
    }, timeout: const Duration(seconds: 60));
    // ignore: avoid_print
    print('COMANDO ${jsonEncode(done)}');
    expect(done['status'], 'rejected');
    expect(jsonEncode(done), contains('unsupported'));
    expect(store.deviceToken, isNotNull);
  }, skip: enabled && hasMs ? false : 'requiere BM_E2E_MS_URL y BM_E2E_SERVICE_KEY', timeout: const Timeout(Duration(minutes: 2)));

  test('paso 4c: dispositivo retirado, el kiosco se registra solo de nuevo', () async {
    final id = deviceId();
    final oldToken = store.deviceToken;
    final res = await ms.send('PATCH', '/staff/dispositivos/$id', {'retired': true});
    // ignore: avoid_print
    print('RETIRAR ${res.statusCode} ${jsonEncode(res.data)}');
    expect(res.statusCode, inInclusiveRange(200, 299));
    final enrolled = logs.count('kiosco registrado');
    await _until('registro nuevo', () async => logs.count('kiosco registrado') > enrolled && store.deviceToken != oldToken ? true : null,
        timeout: const Duration(seconds: 90));
    // ignore: avoid_print
    print('LOG ${jsonEncode(logs.lines)}');
    final after = await ms.get('/staff/dispositivos/$id');
    // ignore: avoid_print
    print('DISPOSITIVO TRAS REENROLAR ${jsonEncode(after)}');
    expect(jsonEncode(after), isNot(contains('"retired":true')));
  }, skip: enabled && hasMs ? false : 'requiere BM_E2E_MS_URL y BM_E2E_SERVICE_KEY', timeout: const Timeout(Duration(minutes: 3)));
}
