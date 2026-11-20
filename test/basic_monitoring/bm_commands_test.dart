import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_api.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_commands.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime.utc(2026, 11, 20, 10);
const _token = 'izd_abcdefghijklmnop1234';

class _Report {
  final String id;
  final Map<String, dynamic> body;
  final String? deviceToken;
  _Report(this.id, this.body, this.deviceToken);
}

class _Harness {
  final BmStore store;
  final reports = <_Report>[];
  final delays = <Duration>[];
  final events = <String>[];
  DateTime clock = _now;
  List<BmReport> script = [];
  late final BmCommands commands;

  _Harness(this.store) {
    commands = BmCommands(
      store: store,
      report: (id, body, {deviceToken}) async {
        reports.add(_Report(id, body, deviceToken));
        events.add('report');
        return script.isEmpty ? BmReport.ok : script.removeAt(0);
      },
      now: () => clock,
      delay: (d) async {
        delays.add(d);
        clock = clock.add(d);
      },
    );
  }
}

Future<_Harness> _harness() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return _Harness(BmStore(prefs));
}

BmCommand _cmd(String id, String type, {Map<String, dynamic>? args, DateTime? expiresAt, bool noExpiry = false}) {
  return BmCommand(
    id: id,
    type: type,
    args: args ?? <String, dynamic>{},
    expiresAt: noExpiry ? null : (expiresAt ?? _now.add(const Duration(minutes: 5))),
  );
}

void main() {
  test('id fuera de [A-Za-z0-9_-] se descarta sin reportar', () async {
    final h = await _harness();
    await h.commands.handle([_cmd('a/b', 'reload_app'), _cmd('a b', 'reload_app'), _cmd('', 'reload_app'), _cmd('ñ', 'reload_app')], _now);
    expect(h.reports, isEmpty);
    expect(h.store.seenCommand('a/b'), isFalse);
  });

  test('id ya visto no se ejecuta ni se reporta otra vez', () async {
    final h = await _harness();
    await h.commands.handle([_cmd('c1', 'reload_app')], _now);
    await h.commands.handle([_cmd('c1', 'reload_app')], _now);
    expect(h.reports, hasLength(1));
  });

  test('vencido según serverTime al recibirlo es rejected expired', () async {
    final h = await _harness();
    await h.commands.handle([_cmd('c1', 'rotate_token', args: {'deviceToken': _token}, expiresAt: _now.subtract(const Duration(seconds: 1)))], _now);
    expect(h.reports.single.body['status'], 'rejected');
    expect(h.reports.single.body['data'], {'reason': 'expired'});
    expect(h.store.deviceToken, isNull);
  });

  test('sin expiresAt es rejected invalid_command', () async {
    final h = await _harness();
    await h.commands.handle([_cmd('c1', 'rotate_token', args: {'deviceToken': _token}, noExpiry: true)], _now);
    expect(h.reports.single.body['status'], 'rejected');
    expect(h.reports.single.body['data'], {'reason': 'invalid_command'});
    expect(h.store.deviceToken, isNull);
  });

  test('todo rechazo lleva el motivo en detail y en data.reason', () async {
    final h = await _harness();
    await h.commands.handle([
      _cmd('c1', 'reload_app'),
      _cmd('c2', 'x', noExpiry: true),
      _cmd('c3', 'x', expiresAt: _now),
      _cmd('c4', 'rotate_token', args: {'deviceToken': 'malo'}),
    ], _now);
    expect(h.reports, hasLength(4));
    for (final r in h.reports) {
      expect(r.body['status'], 'rejected');
      expect(r.body['detail'], isA<String>());
      expect((r.body['data'] as Map)['reason'], r.body['detail']);
    }
    expect(h.reports.map((r) => r.body['detail']), ['unsupported', 'invalid_command', 'expired', 'invalid_command']);
  });

  test('final_ no se reintenta', () async {
    final h = await _harness();
    h.script = [BmReport.final_];
    await h.commands.handle([_cmd('c1', 'reload_app')], _now);
    await h.commands.idle;
    expect(h.reports, hasLength(1));
    expect(h.delays, isEmpty);
  });

  test('retry se reintenta con backoff y handle no espera los reintentos', () async {
    final h = await _harness();
    h.script = [BmReport.retry, BmReport.retry, BmReport.ok];
    await h.commands.handle([_cmd('c1', 'reload_app')], _now);
    expect(h.reports, hasLength(1));
    await h.commands.idle;
    expect(h.reports, hasLength(3));
    expect(h.delays, hasLength(2));
    expect(h.delays.first >= const Duration(seconds: 30), isTrue);
    expect(h.delays.every((d) => d <= const Duration(minutes: 30)), isTrue);
  });

  test('retry se abandona a las 24 h de recibido', () async {
    final h = await _harness();
    h.script = List.filled(10000, BmReport.retry);
    await h.commands.handle([_cmd('c1', 'reload_app')], _now);
    await h.commands.idle;
    expect(h.clock.difference(_now) >= const Duration(hours: 24), isTrue);
    expect(h.clock.difference(_now) < const Duration(hours: 24, minutes: 31), isTrue);
    final count = h.reports.length;
    expect(count, greaterThan(40));
    expect(count, lessThan(120));
  });

  test('un reporte que lanza se trata como retry', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BmStore(await SharedPreferences.getInstance());
    var calls = 0;
    final c = BmCommands(
      store: store,
      report: (id, body, {deviceToken}) async {
        calls++;
        if (calls == 1) throw StateError('red');
        return BmReport.ok;
      },
      now: () => _now,
      delay: (_) async {},
    );
    await c.handle([_cmd('c1', 'reload_app')], _now);
    await c.idle;
    expect(calls, 2);
  });

  group('rotate_token', () {
    test('token válido: primero replaceDeviceToken y después report con el token nuevo', () async {
      final h = await _harness();
      await h.store.saveEnrollment(deviceToken: 'izd_viejo', deviceId: 'd', applianceId: 'a', owner: 'o');
      String? storedAtReport;
      final c = BmCommands(
        store: h.store,
        report: (id, body, {deviceToken}) async {
          storedAtReport = h.store.deviceToken;
          h.reports.add(_Report(id, body, deviceToken));
          return BmReport.ok;
        },
      );
      await c.handle([_cmd('c1', 'rotate_token', args: {'deviceToken': _token})], _now);
      expect(storedAtReport, _token);
      expect(h.store.deviceToken, _token);
      expect(h.reports.single.deviceToken, _token);
      expect(h.reports.single.body['status'], 'succeeded');
    });

    test('inválido: rejected invalid_command y el token no cambia', () async {
      final h = await _harness();
      await h.store.saveEnrollment(deviceToken: 'izd_viejo', deviceId: 'd', applianceId: 'a', owner: 'o');
      for (final bad in <Object?>['izd_corto', 'xyz_abcdefghijklmnop1234', 5, null, 'izd_${'a' * 129}', 'izd_abcdefghijklmnop12 4']) {
        await h.commands.handle([_cmd('c${bad.hashCode}', 'rotate_token', args: {'deviceToken': bad})], _now);
      }
      expect(h.reports, hasLength(6));
      expect(h.reports.every((r) => r.body['status'] == 'rejected' && r.body['detail'] == 'invalid_command' && r.deviceToken == null), isTrue);
      expect(h.store.deviceToken, 'izd_viejo');
    });
  });

  test('reload_app, repair_pos, upload_diagnostics y desconocidos son rejected unsupported y ninguna otra acción', () async {
    final h = await _harness();
    await h.store.saveEnrollment(deviceToken: 'izd_viejo', deviceId: 'd', applianceId: 'a', owner: 'o');
    await h.commands.handle([
      _cmd('c1', 'reload_app'),
      _cmd('c2', 'repair_pos'),
      _cmd('c3', 'upload_diagnostics'),
      _cmd('c4', 'reboot_pc'),
    ], _now);
    expect(h.reports.map((r) => r.body['detail']), everyElement('unsupported'));
    expect(h.reports.map((r) => r.body['status']), everyElement('rejected'));
    expect(h.reports.map((r) => r.id), ['c1', 'c2', 'c3', 'c4']);
    expect(h.store.deviceToken, 'izd_viejo');
  });

  test('cada id se marca antes de ejecutarlo y se atiende en orden', () async {
    final h = await _harness();
    var seenDuringReport = false;
    final c = BmCommands(
      store: h.store,
      report: (id, body, {deviceToken}) async {
        seenDuringReport = h.store.seenCommand(id);
        h.reports.add(_Report(id, body, deviceToken));
        return BmReport.ok;
      },
    );
    await c.handle([_cmd('a', 'x'), _cmd('b', 'x')], _now);
    expect(seenDuringReport, isTrue);
    expect(h.reports.map((r) => r.id), ['a', 'b']);
  });
}
