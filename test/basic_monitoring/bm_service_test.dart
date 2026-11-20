import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_activity.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_agent_link.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_api.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_atc_link.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_commands.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_service.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTimer implements Timer {
  _FakeTimer(this.duration, this.callback);
  final Duration duration;
  final void Function() callback;
  bool cancelled = false;
  bool fired = false;

  @override
  bool get isActive => !cancelled && !fired;

  @override
  int get tick => fired ? 1 : 0;

  @override
  void cancel() => cancelled = true;

  void fire() {
    fired = true;
    callback();
  }
}

class _FakeApi extends BmApi {
  _FakeApi() : super(apiUrl: 'https://api.test');

  final calls = <String>[];
  Future<BmEnrollment> Function() onEnroll = () async => BmEnrollment(deviceId: 'd', applianceId: 'a', deviceToken: 'izd_abcdefghijklmnop1234');
  Future<BmHeartbeatResponse> Function() onHeartbeat =
      () async => BmHeartbeatResponse(serverTime: DateTime.utc(2026, 11, 20), nextInSec: 60, commands: []);
  Future<void> Function(String id, Map<String, dynamic> body) onResult = (_, __) async {};
  Future<String> Function() onIssue = () async => 'K7Q-4MZ-9TD';
  final enrollArgs = <Map<String, dynamic>>[];
  final heartbeatArgs = <Map<String, dynamic>>[];
  final resultTokens = <String>[];
  final issueArgs = <Map<String, dynamic>>[];

  @override
  Future<BmEnrollment> enroll({required String publicToken, String? sucursal, required Map<String, dynamic> body}) {
    calls.add('enroll');
    enrollArgs.add({'publicToken': publicToken, 'sucursal': sucursal, 'body': body});
    return onEnroll();
  }

  @override
  Future<BmHeartbeatResponse> heartbeat({required String deviceToken, required Map<String, dynamic> body}) {
    calls.add('heartbeat');
    heartbeatArgs.add({'deviceToken': deviceToken, 'body': body});
    return onHeartbeat();
  }

  @override
  Future<void> commandResult({required String deviceToken, required String id, required Map<String, dynamic> body}) {
    calls.add('result');
    resultTokens.add(deviceToken);
    return onResult(id, body);
  }

  @override
  Future<String> issueAgentCode({required String publicToken, required String deviceToken, String? sucursal}) {
    calls.add('issue');
    issueArgs.add({'publicToken': publicToken, 'deviceToken': deviceToken, 'sucursal': sucursal});
    return onIssue();
  }
}

class _FakeAtc extends BmAtcLink {
  _FakeAtc() : super(serverUrl: 'http://127.0.0.1:1');
  int checkCalls = 0;
  Completer<void>? gate;
  int pendingChecks = 0;
  int pendingFailures = 0;

  @override
  Future<void> check() async {
    checkCalls++;
    await gate?.future;
  }

  @override
  int takeChecks() {
    final v = pendingChecks;
    pendingChecks = 0;
    return v;
  }

  @override
  int takeFailures() {
    final v = pendingFailures;
    pendingFailures = 0;
    return v;
  }

  @override
  Map<String, dynamic> posState({required String provider}) => {'provider': provider, 'status': 'ok', 'lastOkAt': null};
}

class _FakeAgent extends BmAgentLink {
  _FakeAgent(Future<String?> Function() issueCode) : super(issueCode: issueCode, apiBaseUrl: 'https://api.test');
  int ticks = 0;
  late Future<String?> Function() issue;

  @override
  Future<void> tick() async {
    ticks++;
  }

  @override
  Map<String, dynamic> agentState() => {'reachable': true, 'enrolled': true};
}

class _FakeCommands extends BmCommands {
  _FakeCommands(BmStore store, BmReportFn report) : super(store: store, report: report);
  final handled = <List<String>>[];
  final servers = <DateTime>[];
  Future<void> Function()? block;

  @override
  Future<void> handle(List<BmCommand> commands, DateTime serverTime) async {
    handled.add(commands.map((c) => c.id).toList());
    servers.add(serverTime);
    await block?.call();
  }
}

class _ThrowOnceStore extends BmStore {
  _ThrowOnceStore(super.prefs);
  bool thrown = false;

  @override
  Map<String, int> pendingCounters() {
    if (!thrown) {
      thrown = true;
      throw StateError('prefs');
    }
    return super.pendingCounters();
  }
}

class _H {
  late BmStore store;
  final api = _FakeApi();
  final atc = _FakeAtc();
  _FakeAgent? agent;
  Future<String?> Function()? agentIssue;
  _FakeCommands? commands;
  BmReportFn? report;
  final timers = <_FakeTimer>[];
  DateTime clock = DateTime.utc(2026, 11, 20, 10);
  late BmService service;
  final activity = BmActivity();

  List<_FakeTimer> get pending => timers.where((t) => t.isActive).toList();

  Future<void> init({bool web = false, Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    store = BmStore(await SharedPreferences.getInstance());
    service = BmService(
      apiFactory: (_) => api,
      storeFactory: () async => store,
      atcFactory: (_) => atc,
      agentFactory: (ctx, issue) {
        agentIssue = issue;
        return agent = _FakeAgent(issue);
      },
      commandsFactory: (s, r) {
        report = r;
        return commands = _FakeCommands(s, r);
      },
      now: () => clock,
      timer: (d, cb) {
        final t = _FakeTimer(d, cb);
        timers.add(t);
        return t;
      },
      isWeb: web,
      activity: activity,
    );
  }
}

BmContext _ctx({String? publicToken = 'pub', int contribuyente = 1, int dispositivo = 2, String? sucursal = 'S1', String provider = 'atc'}) {
  return BmContext(
    publicToken: publicToken,
    contribuyente: contribuyente,
    dispositivo: dispositivo,
    sucursal: sucursal,
    deviceName: 'KIOSKO-01',
    flavor: 'bk',
    version: '2.3.1+45',
    platform: 'web',
    country: 'CO',
    provider: provider,
    apiUrl: 'https://api.test/',
    atcServerUrl: 'http://127.0.0.1:3000',
  );
}

Future<void> _settle() => pumpEventQueue(times: 50);

void main() {
  test('start con ctx null o sin publicToken: cero peticiones y ningún temporizador', () async {
    final h = _H();
    await h.init();
    h.service.start(null);
    h.service.start(null);
    h.service.start(_ctx(publicToken: null));
    h.service.start(_ctx(publicToken: ''));
    await _settle();
    expect(h.api.calls, isEmpty);
    expect(h.timers, isEmpty);
  });

  test('start vuelve aunque el registro no responda nunca', () async {
    final h = _H();
    await h.init();
    h.api.onEnroll = () => Completer<BmEnrollment>().future;
    final sw = Stopwatch()..start();
    h.service.start(_ctx());
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(50));
    await _settle();
    expect(h.api.calls, ['enroll']);
  });

  test('sin token: registra y guarda owner; después manda heartbeat con X-Device-Token', () async {
    final h = _H();
    await h.init();
    h.service.start(_ctx());
    await _settle();
    expect(h.api.calls, ['enroll']);
    final args = h.api.enrollArgs.single;
    expect(args['publicToken'], 'pub');
    expect(args['sucursal'], 'S1');
    final body = args['body'] as Map<String, dynamic>;
    expect(body['schema'], 1);
    expect(body['kind'], 'kiosk');
    expect(body['installationId'], h.store.installationId());
    expect(body['deviceName'], 'KIOSKO-01');
    expect(body['business'], {'pais': 'CO'});
    expect(body['app'], {'version': '2.3.1+45', 'flavor': 'bk', 'platform': 'web'});
    expect(h.store.owner, '1:2');
    expect(h.store.deviceToken, 'izd_abcdefghijklmnop1234');
    h.pending.single.fire();
    await _settle();
    expect(h.api.calls, ['enroll', 'heartbeat']);
    expect(h.api.heartbeatArgs.single['deviceToken'], 'izd_abcdefghijklmnop1234');
  });

  test('el registro manda Izi-Sucursal siempre que se conoce y null si falta', () async {
    final h = _H();
    await h.init();
    h.service.start(_ctx(sucursal: null));
    await _settle();
    expect(h.api.enrollArgs.single['sucursal'], isNull);
  });

  test('con token y owner iguales va directo al heartbeat, sin registrar', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.service.start(_ctx());
    await _settle();
    expect(h.api.calls, ['heartbeat']);
    expect(h.api.heartbeatArgs.single['deviceToken'], 'izd_existenteexistente1');
  });

  test('owner distinto (otro dispositivo o contribuyente): borra el token y se registra de nuevo', () async {
    for (final ctx in [_ctx(dispositivo: 9), _ctx(contribuyente: 9)]) {
      final h = _H();
      await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
      h.service.start(ctx);
      await _settle();
      expect(h.api.calls, ['enroll']);
      expect(h.store.owner, ctx.owner);
      expect(h.store.deviceToken, 'izd_abcdefghijklmnop1234');
    }
  });

  test('token sin owner se descarta y se registra de nuevo', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1'});
    h.service.start(_ctx());
    await _settle();
    expect(h.api.calls, ['enroll']);
  });

  test('gateway 503 / 404 / red caída en el registro: reintenta con bmBackoff, una petición por espera y no lanza', () async {
    final errors = [
      BmApiException(BmFailure.transient, status: 503),
      BmApiException(BmFailure.transient, status: 404),
      BmApiException(BmFailure.transient),
    ];
    final h = _H();
    await h.init();
    var i = 0;
    h.api.onEnroll = () async => throw errors[i++ % errors.length];
    h.service.start(_ctx());
    await _settle();
    expect(h.api.calls, ['enroll']);
    for (var n = 0; n < 3; n++) {
      final t = h.pending.single;
      expect(t.duration >= const Duration(seconds: 30), isTrue);
      expect(t.duration <= const Duration(minutes: 30), isTrue);
      await _settle();
      expect(h.api.calls, hasLength(n + 1));
      t.fire();
      await _settle();
      expect(h.api.calls, hasLength(n + 2));
    }
    expect(h.store.deviceToken, isNull);
  });

  test('el backoff del registro crece con los fallos', () async {
    final h = _H();
    await h.init();
    h.api.onEnroll = () async => throw BmApiException(BmFailure.transient, status: 503);
    h.service.start(_ctx());
    await _settle();
    final first = h.pending.single.duration;
    for (var n = 0; n < 6; n++) {
      h.pending.single.fire();
      await _settle();
    }
    expect(h.pending.single.duration > first, isTrue);
  });

  test('401 device_token_invalid en heartbeat: clearEnrollment y nuevo registro tras backoff, no inmediato', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.api.onHeartbeat = () async => throw BmApiException(BmFailure.tokenInvalid, status: 401, code: 'device_token_invalid');
    h.service.start(_ctx());
    await _settle();
    expect(h.api.calls, ['heartbeat']);
    expect(h.store.deviceToken, isNull);
    expect(h.store.owner, isNull);
    final t = h.pending.single;
    expect(t.duration >= const Duration(seconds: 30), isTrue);
    t.fire();
    await _settle();
    expect(h.api.calls, ['heartbeat', 'enroll']);
  });

  test('2xx: commitWindow, programa nextInSec y pasa los comandos a handle con serverTime', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    await h.store.addCounter('posHealthChecks', 4);
    final server = DateTime.utc(2026, 11, 20, 10, 0, 1);
    h.api.onHeartbeat = () async => BmHeartbeatResponse(
          serverTime: server,
          nextInSec: 10,
          commands: [BmCommand(id: 'c1', type: 'reload_app', args: {}, expiresAt: server)],
        );
    h.service.start(_ctx());
    await _settle();
    final sent = (h.api.heartbeatArgs.single['body'] as Map)['counters'] as Map;
    expect(sent['posHealthChecks'], 4);
    expect(h.store.pendingCounters(), <String, int>{});
    expect(h.store.windowStartAt(h.clock), h.clock.toIso8601String());
    expect(h.pending.single.duration, const Duration(seconds: 10));
    expect(h.commands!.handled, [
      ['c1']
    ]);
    expect(h.commands!.servers.single, server);
  });

  test('transient en heartbeat no hace commitWindow y reintenta con backoff', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    await h.store.addCounter('posHealthChecks', 4);
    h.api.onHeartbeat = () async => throw BmApiException(BmFailure.transient, status: 503);
    h.service.start(_ctx());
    await _settle();
    expect(h.store.pendingCounters(), {'posHealthChecks': 4});
    expect(h.pending.single.duration >= const Duration(seconds: 30), isTrue);
    expect(h.api.calls, ['heartbeat']);
  });

  test('rejected (400/411/413/415): espera 30 min y no reintenta antes', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.api.onHeartbeat = () async => throw BmApiException(BmFailure.rejected, status: 400, code: 'validation_error');
    h.service.start(_ctx());
    await _settle();
    expect(h.pending.single.duration, const Duration(minutes: 30));
    await _settle();
    expect(h.api.calls, ['heartbeat']);
    expect(h.store.deviceToken, isNotNull);
  });

  test('rejected en el registro también espera 30 min', () async {
    final h = _H();
    await h.init();
    h.api.onEnroll = () async => throw BmApiException(BmFailure.rejected, status: 400, code: 'validation_error');
    h.service.start(_ctx());
    await _settle();
    expect(h.pending.single.duration, const Duration(minutes: 30));
  });

  test('stop: cancela temporizadores y no hay más peticiones, y no vuelve a armar nada', () async {
    final h = _H();
    await h.init();
    h.service.start(_ctx());
    await _settle();
    final t = h.pending.single;
    h.service.stop();
    expect(t.cancelled, isTrue);
    t.fire();
    await _settle();
    expect(h.api.calls, ['enroll']);
    expect(h.pending, isEmpty);
  });

  test('stop con una petición en vuelo: al completar no arma nada', () async {
    final h = _H();
    await h.init();
    final gate = Completer<BmEnrollment>();
    h.api.onEnroll = () => gate.future;
    h.service.start(_ctx());
    await _settle();
    h.service.stop();
    gate.complete(BmEnrollment(deviceId: 'd', applianceId: 'a', deviceToken: 'izd_abcdefghijklmnop1234'));
    await _settle();
    expect(h.pending, isEmpty);
    expect(h.store.deviceToken, isNull);
  });

  test('start dos veces con el mismo contexto: un solo bucle y una sola petición en vuelo', () async {
    final h = _H();
    await h.init();
    h.api.onEnroll = () => Completer<BmEnrollment>().future;
    h.service.start(_ctx());
    h.service.start(_ctx());
    await _settle();
    h.service.start(_ctx());
    await _settle();
    expect(h.api.calls, ['enroll']);
  });

  test('start con otro contexto: detiene el anterior y arranca con el nuevo', () async {
    final h = _H();
    await h.init();
    h.service.start(_ctx());
    await _settle();
    final old = h.pending.single;
    h.service.start(_ctx(dispositivo: 7));
    await _settle();
    expect(old.cancelled, isTrue);
    expect(h.store.owner, '1:7');
    expect(h.api.calls.where((c) => c == 'enroll'), hasLength(2));
  });

  test('otro apiUrl o atcServerUrl cuenta como otro contexto', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.service.start(_ctx());
    await _settle();
    final other = BmContext(
      publicToken: 'pub',
      contribuyente: 1,
      dispositivo: 2,
      sucursal: 'S1',
      deviceName: 'KIOSKO-01',
      flavor: 'bk',
      version: '2.3.1+45',
      platform: 'web',
      country: 'CO',
      provider: 'atc',
      apiUrl: 'https://otra.test/',
      atcServerUrl: 'http://127.0.0.1:3000',
    );
    h.service.start(other);
    await _settle();
    expect(h.api.calls, ['heartbeat', 'heartbeat']);
  });

  test('los comandos se manejan fuera del ciclo del heartbeat', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    final server = DateTime.utc(2026, 11, 20);
    h.api.onHeartbeat = () async => BmHeartbeatResponse(
          serverTime: server,
          nextInSec: 10,
          commands: [BmCommand(id: 'c1', type: 'x', args: {}, expiresAt: server)],
        );
    h.service.start(_ctx());
    await _settle();
    h.commands!.block = () => Completer<void>().future;
    h.pending.single.fire();
    await _settle();
    expect(h.api.calls, ['heartbeat', 'heartbeat']);
    expect(h.pending.single.duration, const Duration(seconds: 10));
  });

  test('un handle de comandos que lanza no rompe el ciclo', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    final server = DateTime.utc(2026, 11, 20);
    h.api.onHeartbeat = () async => BmHeartbeatResponse(
          serverTime: server,
          nextInSec: 10,
          commands: [BmCommand(id: 'c1', type: 'x', args: {}, expiresAt: server)],
        );
    h.service.start(_ctx());
    await _settle();
    h.commands!.block = () async => throw StateError('x');
    h.pending.single.fire();
    await _settle();
    expect(h.pending.single.duration, const Duration(seconds: 10));
  });

  test('el heartbeat lleva la forma del contrato y no lleva tokens ni Authorization', () async {
    final h = _H();
    await h.init(web: true, prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.service.start(_ctx());
    await _settle();
    final body = h.api.heartbeatArgs.single['body'] as Map<String, dynamic>;
    final text = jsonEncode(body);
    expect(text.contains('izd_'), isFalse);
    expect(text.contains('eyJ'), isFalse);
    expect(text.toLowerCase().contains('authorization'), isFalse);
    expect(body['schema'], 1);
    expect(body['kind'], 'kiosk');
    expect(body['installationId'], h.store.installationId());
    expect(body['sentAt'], endsWith('Z'));
    expect(body['bootId'], isA<String>());
    expect(body['uptimeSec'], 0);
    expect(body['app'], {'version': '2.3.1+45', 'flavor': 'bk', 'platform': 'web'});
    final state = body['state'] as Map;
    expect(state['mode'], 'idle');
    expect(state['chargeInProgress'], false);
    expect(state['pos']['provider'], 'atc');
    expect(state['agent'], {'reachable': true, 'enrolled': true});
    final counters = body['counters'] as Map;
    expect(counters['windowStartAt'], isA<String>());
    expect(counters['posHealthChecks'], 0);
    expect(counters['posHealthFailures'], 0);
    expect(text.contains('null'), isFalse);
  });

  test('con proveedor none no hay chequeo ATC ni espera, y pos es not_configured', () async {
    final h = _H();
    await h.init(web: true, prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.service.start(_ctx(provider: 'none'));
    await _settle();
    expect(h.atc.checkCalls, 0);
    expect(h.api.calls, ['heartbeat']);
    final state = (h.api.heartbeatArgs.single['body'] as Map)['state'] as Map;
    expect(state['pos']['status'], 'not_configured');
  });

  test('el primer heartbeat espera al primer chequeo ATC y suma sus contadores', () async {
    final h = _H();
    await h.init(web: true, prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.atc.gate = Completer<void>();
    h.atc.pendingChecks = 1;
    h.atc.pendingFailures = 1;
    h.service.start(_ctx());
    await _settle();
    expect(h.atc.checkCalls, 1);
    expect(h.api.calls, isEmpty);
    h.atc.gate!.complete();
    await _settle();
    expect(h.api.calls, ['heartbeat']);
    final counters = (h.api.heartbeatArgs.single['body'] as Map)['counters'] as Map;
    expect(counters['posHealthChecks'], 1);
    expect(counters['posHealthFailures'], 1);
  });

  test('ATC cada 30 s y agente cada 60 s solo en web y registrado', () async {
    final h = _H();
    await h.init(web: true, prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.service.start(_ctx());
    await _settle();
    expect(h.pending.map((t) => t.duration), containsAll([const Duration(seconds: 30), const Duration(seconds: 60)]));
    expect(h.agent!.ticks, 1);
    final atcTimer = h.pending.firstWhere((t) => t.duration == const Duration(seconds: 30));
    atcTimer.fire();
    await _settle();
    expect(h.atc.checkCalls, 2);
    h.service.stop();
    expect(h.pending, isEmpty);

    final h2 = _H();
    await h2.init(web: false, prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h2.service.start(_ctx());
    await _settle();
    expect(h2.atc.checkCalls, 0);
    expect(h2.agent, isNull);
  });

  test('sin registrar no hay chequeos ATC ni del agente', () async {
    final h = _H();
    await h.init(web: true);
    h.api.onEnroll = () async => throw BmApiException(BmFailure.transient, status: 503);
    h.service.start(_ctx());
    await _settle();
    expect(h.atc.checkCalls, 0);
    expect(h.agent, isNull);
  });

  test('issueCode: null sin token o sin token público, sin red; con ambos pide el código', () async {
    final h = _H();
    await h.init(web: true, prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.service.start(_ctx());
    await _settle();
    expect(await h.agentIssue!(), 'K7Q-4MZ-9TD');
    expect(h.api.issueArgs.single, {'publicToken': 'pub', 'deviceToken': 'izd_existenteexistente1', 'sucursal': 'S1'});
    await h.store.clearEnrollment();
    final before = h.api.calls.length;
    expect(await h.agentIssue!(), isNull);
    expect(h.api.calls.length, before);
  });

  test('issueCode deja propagar las excepciones', () async {
    final h = _H();
    await h.init(web: true, prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.api.onIssue = () async => throw BmApiException(BmFailure.transient, status: 503);
    h.service.start(_ctx());
    await _settle();
    await expectLater(h.agentIssue!(), throwsA(isA<BmApiException>()));
  });

  test('report: ok, 404 y 409 son final_, lo demás retry, y usa el deviceToken indicado', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.service.start(_ctx());
    await _settle();
    final report = h.report!;
    expect(await report('c1', {}), BmReport.ok);
    expect(h.api.resultTokens.last, 'izd_existenteexistente1');
    expect(await report('c1', {}, deviceToken: 'izd_nuevonuevonuevo123'), BmReport.ok);
    expect(h.api.resultTokens.last, 'izd_nuevonuevonuevo123');
    for (final status in [404, 409]) {
      h.api.onResult = (_, __) async => throw BmApiException(BmFailure.transient, status: status);
      expect(await report('c1', {}), BmReport.final_);
    }
    for (final status in [500, 503, 429, null]) {
      h.api.onResult = (_, __) async => throw BmApiException(BmFailure.transient, status: status);
      expect(await report('c1', {}), BmReport.retry);
    }
    h.api.onResult = (_, __) async => throw StateError('x');
    expect(await report('c1', {}), BmReport.retry);
  });

  test('registro OK seguido de 401 en cada heartbeat: la espera crece, no se queda en 1 min', () async {
    final h = _H();
    await h.init();
    h.api.onHeartbeat = () async => throw BmApiException(BmFailure.tokenInvalid, status: 401, code: 'device_token_invalid');
    h.service.start(_ctx());
    await _settle();
    h.pending.single.fire();
    await _settle();
    final waits = <Duration>[h.pending.single.duration];
    for (var n = 0; n < 6; n++) {
      h.pending.single.fire();
      await _settle();
      h.pending.single.fire();
      await _settle();
      waits.add(h.pending.single.duration);
    }
    expect(waits.last >= const Duration(minutes: 10), isTrue, reason: '$waits');
    expect(h.api.calls.where((c) => c == 'enroll').length, greaterThan(6));
  });

  test('heartbeat 2xx reinicia el conteo de fallos', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    var fail = true;
    h.api.onHeartbeat = () async {
      if (fail) throw BmApiException(BmFailure.transient, status: 503);
      return BmHeartbeatResponse(serverTime: DateTime.utc(2026, 11, 20), nextInSec: 60, commands: []);
    };
    h.service.start(_ctx());
    await _settle();
    for (var n = 0; n < 5; n++) {
      h.pending.single.fire();
      await _settle();
    }
    expect(h.pending.single.duration >= const Duration(minutes: 10), isTrue);
    fail = false;
    h.pending.single.fire();
    await _settle();
    fail = true;
    h.pending.single.fire();
    await _settle();
    expect(h.pending.single.duration <= const Duration(seconds: 72), isTrue);
  });

  test('el heartbeat lleva state.screen cuando BmActivity lo conoce', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    h.activity.screenChanged('makeOrder');
    h.service.start(_ctx());
    await _settle();
    final state = (h.api.heartbeatArgs.single['body'] as Map)['state'] as Map;
    expect(state['screen'], 'makeOrder');
    expect(state['mode'], 'ordering');
  });

  test('un fallo inesperado en el primer heartbeat con token guardado deja un reintento armado', () async {
    final h = _H();
    await h.init(prefs: {'bm.deviceToken': 'izd_existenteexistente1', 'bm.owner': '1:2'});
    final prefs = await SharedPreferences.getInstance();
    h.store = _ThrowOnceStore(prefs);
    h.service.start(_ctx());
    await _settle();
    expect(h.api.calls, isEmpty);
    expect(h.pending.single.duration >= const Duration(seconds: 30), isTrue);
    h.pending.single.fire();
    await _settle();
    expect(h.api.calls, ['heartbeat']);
  });
}
