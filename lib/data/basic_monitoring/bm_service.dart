import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bm_activity.dart';
import 'bm_agent_link.dart';
import 'bm_api.dart';
import 'bm_atc_link.dart';
import 'bm_backoff.dart';
import 'bm_commands.dart';
import 'bm_store.dart';
import 'bm_web_signals.dart';

class BmContext {
  final String? publicToken;
  final int contribuyente;
  final int dispositivo;
  final String? sucursal;
  final String deviceName;
  final String flavor;
  final String version;
  final String platform;
  final String? country;
  final String provider;
  final String apiUrl;
  final String atcServerUrl;

  BmContext({
    this.publicToken,
    required this.contribuyente,
    required this.dispositivo,
    this.sucursal,
    required this.deviceName,
    required this.flavor,
    required this.version,
    required this.platform,
    this.country,
    required this.provider,
    required this.apiUrl,
    required this.atcServerUrl,
  });

  String get owner => '$contribuyente:$dispositivo';

  String get key => [
        publicToken,
        contribuyente,
        dispositivo,
        sucursal,
        deviceName,
        flavor,
        version,
        platform,
        country,
        provider,
        apiUrl,
        atcServerUrl,
      ].join('\u0000');
}

class BmService {
  static BmService instance = BmService();

  BmService({
    BmApi Function(BmContext ctx)? apiFactory,
    Future<BmStore> Function()? storeFactory,
    BmAtcLink Function(BmContext ctx)? atcFactory,
    BmAgentLink Function(BmContext ctx, Future<String?> Function() issueCode)? agentFactory,
    BmCommands Function(BmStore store, BmReportFn report)? commandsFactory,
    DateTime Function()? now,
    Timer Function(Duration duration, void Function() callback)? timer,
    bool? isWeb,
    BmActivity? activity,
  })  : _apiFactory = apiFactory ?? ((ctx) => BmApi(apiUrl: ctx.apiUrl)),
        _storeFactory = storeFactory ?? (() async => BmStore(await SharedPreferences.getInstance())),
        _atcFactory = atcFactory ?? ((ctx) => BmAtcLink(serverUrl: ctx.atcServerUrl)),
        _agentFactory = agentFactory ??
            ((ctx, issueCode) => BmAgentLink(issueCode: issueCode, apiBaseUrl: ctx.apiUrl)),
        _commandsFactory = commandsFactory ?? ((store, report) => BmCommands(store: store, report: report)),
        _now = now ?? DateTime.now,
        _timer = timer ?? Timer.new,
        _isWeb = isWeb ?? kIsWeb,
        _activity = activity ?? BmActivity.instance {
    _startedAt = _now();
    _bootId = _uuidV4();
  }

  static const _atcEvery = Duration(seconds: 30);
  static const _agentEvery = Duration(seconds: 60);
  static const _rejectedWait = Duration(minutes: 30);

  final BmApi Function(BmContext) _apiFactory;
  final Future<BmStore> Function() _storeFactory;
  final BmAtcLink Function(BmContext) _atcFactory;
  final BmAgentLink Function(BmContext, Future<String?> Function()) _agentFactory;
  final BmCommands Function(BmStore, BmReportFn) _commandsFactory;
  final DateTime Function() _now;
  final Timer Function(Duration, void Function()) _timer;
  final bool _isWeb;
  final BmActivity _activity;
  late final DateTime _startedAt;
  late final String _bootId;

  int _gen = 0;
  BmContext? _ctx;
  BmStore? _store;
  BmApi? _api;
  BmAtcLink? _atc;
  BmAgentLink? _agent;
  BmCommands? _commands;
  Timer? _mainTimer;
  Timer? _atcTimer;
  Timer? _agentTimer;
  Future<void>? _atcFirst;
  int _failures = 0;
  String? _lastLogged;
  bool _loggedOff = false;

  void start(BmContext? ctx) {
    try {
      if (ctx == null || ctx.publicToken == null || ctx.publicToken!.isEmpty) {
        stop();
        if (!_loggedOff) {
          _loggedOff = true;
          developer.log('monitoreo apagado: sin contexto o sin token público', name: 'monitoreo');
        }
        return;
      }
      _loggedOff = false;
      if (_ctx != null && _ctx!.key == ctx.key) return;
      stop();
      _ctx = ctx;
      final gen = ++_gen;
      unawaited(_boot(ctx, gen).catchError((Object e) {
        _logState('boot_error', 'monitoreo: fallo al arrancar (${e.runtimeType})');
      }));
    } catch (e) {
      developer.log('monitoreo: start falló (${e.runtimeType})', name: 'monitoreo');
    }
  }

  void stop() {
    try {
      _gen++;
      _ctx = null;
      _cancelAll();
      _store = null;
      _api = null;
      _atc = null;
      _agent = null;
      _commands = null;
      _atcFirst = null;
      _failures = 0;
      _lastLogged = null;
    } catch (e) {
      developer.log('monitoreo: stop falló (${e.runtimeType})', name: 'monitoreo');
    }
  }

  void _cancelAll() {
    _mainTimer?.cancel();
    _atcTimer?.cancel();
    _agentTimer?.cancel();
    _mainTimer = null;
    _atcTimer = null;
    _agentTimer = null;
  }

  bool _alive(int gen) => gen == _gen;

  void _logState(String key, String message) {
    if (_lastLogged == key) return;
    _lastLogged = key;
    developer.log(message, name: 'monitoreo');
  }

  Future<void> _boot(BmContext ctx, int gen) async {
    final store = await _storeFactory();
    if (!_alive(gen)) return;
    final api = _apiFactory(ctx);
    _store = store;
    _api = api;
    _commands = _commandsFactory(store, (id, body, {deviceToken}) => _report(gen, id, body, deviceToken));

    if (store.owner != ctx.owner && (store.deviceToken != null || store.owner != null)) {
      await store.clearEnrollment();
      if (!_alive(gen)) return;
    }
    if (store.deviceToken == null) {
      await _enroll(ctx, gen);
    } else {
      _startLinks(ctx, gen);
      await _heartbeat(ctx, gen);
    }
  }

  Future<BmReport> _report(int gen, String id, Map<String, dynamic> body, String? deviceToken) async {
    final token = deviceToken ?? _store?.deviceToken;
    final api = _api;
    if (!_alive(gen) || token == null || api == null) return BmReport.retry;
    try {
      await api.commandResult(deviceToken: token, id: id, body: body);
      return BmReport.ok;
    } on BmApiException catch (e) {
      return (e.status == 404 || e.status == 409) ? BmReport.final_ : BmReport.retry;
    } catch (_) {
      return BmReport.retry;
    }
  }

  void _schedule(int gen, Duration wait, Future<void> Function() action) {
    if (!_alive(gen)) return;
    _mainTimer?.cancel();
    _mainTimer = _timer(wait, () {
      if (!_alive(gen)) return;
      final ctx = _ctx;
      if (ctx == null) return;
      unawaited(action().catchError((Object e) {
        _logState('cycle_error', 'monitoreo: fallo inesperado (${e.runtimeType})');
        _failures++;
        _schedule(gen, bmBackoff(_failures), action);
      }));
    });
  }

  Future<void> _enroll(BmContext ctx, int gen) async {
    final store = _store!;
    final api = _api!;
    try {
      final result = await api.enroll(
        publicToken: ctx.publicToken!,
        sucursal: ctx.sucursal,
        body: {
          'schema': 1,
          'installationId': store.installationId(),
          'kind': 'kiosk',
          'app': {'version': ctx.version, 'flavor': ctx.flavor, 'platform': ctx.platform},
          'deviceName': ctx.deviceName,
          'business': {if (ctx.country != null) 'pais': ctx.country},
        },
      );
      if (!_alive(gen)) return;
      await store.saveEnrollment(
        deviceToken: result.deviceToken,
        deviceId: result.deviceId,
        applianceId: result.applianceId,
        owner: ctx.owner,
      );
      if (!_alive(gen)) return;
      _failures = 0;
      _logState('enrolled', 'monitoreo: kiosco registrado');
      _startLinks(ctx, gen);
      _schedule(gen, Duration.zero, () => _heartbeat(ctx, gen));
    } catch (error) {
      if (!_alive(gen)) return;
      final e = error is BmApiException ? error : BmApiException(BmFailure.transient);
      if (e.kind == BmFailure.rejected) {
        _logState('enroll_rejected', 'monitoreo: registro rechazado (${e.status} ${e.code})');
        _schedule(gen, _rejectedWait, () => _enroll(ctx, gen));
      } else {
        _failures++;
        _logState('enroll_failed', 'monitoreo: registro no disponible, se reintenta (${e.status ?? 'red'})');
        _schedule(gen, bmBackoff(_failures), () => _enroll(ctx, gen));
      }
    }
  }

  Future<void> _heartbeat(BmContext ctx, int gen) async {
    final store = _store;
    final api = _api;
    final token = store?.deviceToken;
    if (store == null || api == null || token == null || !_alive(gen)) return;

    final first = _atcFirst;
    if (first != null) {
      await first;
      if (!_alive(gen)) return;
    }

    final sentAt = _now();
    final counters = store.pendingCounters();
    final body = _heartbeatBody(ctx, store, sentAt, counters);
    try {
      final res = await api.heartbeat(deviceToken: token, body: body);
      if (!_alive(gen)) return;
      final after = store.pendingCounters();
      await store.commitWindow(sentAt);
      for (final e in after.entries) {
        final extra = e.value - (counters[e.key] ?? 0);
        if (extra > 0) await store.addCounter(e.key, extra);
      }
      if (!_alive(gen)) return;
      _failures = 0;
      _logState('heartbeat_ok', 'monitoreo: heartbeat aceptado');
      if (res.commands.isNotEmpty) {
        final commands = _commands;
        if (commands != null) {
          unawaited(commands.handle(res.commands, res.serverTime).catchError((Object e) {
            developer.log('monitoreo: comandos fallaron (${e.runtimeType})', name: 'monitoreo');
          }));
        }
      }
      _schedule(gen, Duration(seconds: res.nextInSec), () => _heartbeat(ctx, gen));
    } catch (error) {
      if (!_alive(gen)) return;
      final e = error is BmApiException ? error : BmApiException(BmFailure.transient);
      if (e.kind == BmFailure.tokenInvalid) {
        await store.clearEnrollment();
        if (!_alive(gen)) return;
        _stopLinks();
        _failures++;
        _logState('token_invalid', 'monitoreo: token retirado, se registra de nuevo');
        _schedule(gen, bmBackoff(_failures), () => _enroll(ctx, gen));
      } else if (e.kind == BmFailure.rejected) {
        _logState('hb_rejected', 'monitoreo: heartbeat rechazado (${e.status} ${e.code})');
        _schedule(gen, _rejectedWait, () => _heartbeat(ctx, gen));
      } else {
        _failures++;
        _logState('hb_failed', 'monitoreo: heartbeat no disponible, se reintenta (${e.status ?? 'red'})');
        _schedule(gen, bmBackoff(_failures), () => _heartbeat(ctx, gen));
      }
    }
  }

  Map<String, dynamic> _heartbeatBody(BmContext ctx, BmStore store, DateTime sentAt, Map<String, int> counters) {
    final atc = _atc;
    final agent = _agent;
    final body = <String, dynamic>{
      'schema': 1,
      'installationId': store.installationId(),
      'kind': 'kiosk',
      'sentAt': sentAt.toUtc().toIso8601String(),
      'bootId': _bootId,
      'uptimeSec': sentAt.difference(_startedAt).inSeconds,
      'app': {'version': ctx.version, 'flavor': ctx.flavor, 'platform': ctx.platform},
      'state': {
        'mode': _activity.mode,
        'online': bmOnline(),
        'visibility': bmVisibility(),
        'chargeInProgress': _activity.charging,
        'pos': atc?.posState(provider: ctx.provider) ?? {'provider': 'none', 'status': 'not_configured', 'consecutiveFailures': 0},
        'agent': agent?.agentState(),
      },
      'counters': {
        'windowStartAt': store.windowStartAt(sentAt),
        'posHealthChecks': counters['posHealthChecks'] ?? 0,
        'posHealthFailures': counters['posHealthFailures'] ?? 0,
      },
    };
    return _withoutNulls(body) as Map<String, dynamic>;
  }

  dynamic _withoutNulls(dynamic value) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) {
        if (v != null) out[k.toString()] = _withoutNulls(v);
      });
      return out;
    }
    return value;
  }

  void _startLinks(BmContext ctx, int gen) {
    _stopLinks();
    if (!_isWeb || !_alive(gen)) return;
    final store = _store!;
    final api = _api!;
    if (ctx.provider != 'none') {
      final atc = _atc = _atcFactory(ctx);
      _atcFirst = _atcCycle(atc, store, gen);
    }
    final agent = _agent = _agentFactory(ctx, () async {
      final deviceToken = store.deviceToken;
      final publicToken = ctx.publicToken;
      if (deviceToken == null || publicToken == null || publicToken.isEmpty) return null;
      return api.issueAgentCode(publicToken: publicToken, deviceToken: deviceToken, sucursal: ctx.sucursal);
    });
    _agentTick(agent, gen);
  }

  void _stopLinks() {
    _atcTimer?.cancel();
    _agentTimer?.cancel();
    _atcTimer = null;
    _agentTimer = null;
    _atcFirst = null;
    _atc = null;
    _agent = null;
  }

  Future<void> _atcCycle(BmAtcLink atc, BmStore store, int gen) async {
    try {
      await atc.check();
      if (!_alive(gen)) return;
      final checks = atc.takeChecks();
      final failures = atc.takeFailures();
      if (checks > 0) await store.addCounter('posHealthChecks', checks);
      if (failures > 0) await store.addCounter('posHealthFailures', failures);
    } catch (e) {
      developer.log('monitoreo: chequeo ATC falló (${e.runtimeType})', name: 'monitoreo');
    }
    if (!_alive(gen) || !identical(_atc, atc)) return;
    _atcTimer = _timer(_atcEvery, () {
      if (_alive(gen) && identical(_atc, atc)) unawaited(_atcCycle(atc, store, gen));
    });
  }

  void _agentTick(BmAgentLink agent, int gen) {
    unawaited(agent.tick().catchError((Object _) {}).whenComplete(() {
      if (!_alive(gen) || !identical(_agent, agent)) return;
      _agentTimer = _timer(_agentEvery, () {
        if (_alive(gen) && identical(_agent, agent)) _agentTick(agent, gen);
      });
    }));
  }

  static String _uuidV4() {
    final random = Random.secure();
    final b = List<int>.generate(16, (_) => random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
