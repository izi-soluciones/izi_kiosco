import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';

TelemetryEvent _event(String type, [Map<String, Object?> data = const {}]) => TelemetryEvent(
    seq: 1, ts: DateTime.utc(2026), upMs: 0, type: type, level: TelemetryLevel.info, data: data);

void main() {
  late DateTime now;
  late MemoryCountersStore store;
  late KioskCounters counters;
  final start = DateTime.utc(2026, 10, 12, 14);

  setUp(() {
    now = start;
    store = MemoryCountersStore();
    counters = KioskCounters(store: store, now: () => now);
  });

  group('window', () {
    test('every contract counter is sent, 0 included, with the window start', () {
      counters.add(KioskCounters.orders);
      final json = counters.snapshot().toJson();
      expect(json['windowStartAt'], '2026-10-12T14:00:00.000Z');
      expect(json.keys.skip(1), KioskCounters.names);
      expect(json['orders'], 1);
      expect(json['chargesStarted'], 0);
    });

    test('a heartbeat that fails leaves them growing in the same window', () {
      counters.add(KioskCounters.orders);
      final first = counters.snapshot();
      // No 2xx: nothing is acknowledged.
      now = now.add(const Duration(minutes: 1));
      counters.add(KioskCounters.orders);
      final second = counters.snapshot();
      expect(second.windowStartAt, first.windowStartAt);
      expect(second.values[KioskCounters.orders], 2);
    });

    test('an accepted heartbeat takes off what it carried and starts the next window', () {
      counters.add(KioskCounters.chargesStarted, 3);
      counters.add(KioskCounters.chargesApproved, 2);
      now = now.add(const Duration(minutes: 1));
      final sent = counters.snapshot();

      counters.acknowledge(sent);
      final next = counters.snapshot();
      expect(next.windowStartAt, sent.takenAt);
      expect(next.values, isEmpty);
      expect(counters.snapshot().toJson()['chargesStarted'], 0);
    });

    test('what was counted while the heartbeat was on its way stays for the next one', () {
      counters.add(KioskCounters.posHealthChecks, 2);
      now = now.add(const Duration(minutes: 1));
      final sent = counters.snapshot();
      counters.add(KioskCounters.posHealthChecks);
      counters.add(KioskCounters.orders);

      counters.acknowledge(sent);
      expect(counters[KioskCounters.posHealthChecks], 1);
      expect(counters[KioskCounters.orders], 1);
      expect(counters.windowStartAt, sent.takenAt);
    });

    test('acknowledging an old window twice changes nothing', () {
      counters.add(KioskCounters.orders, 2);
      now = now.add(const Duration(minutes: 1));
      final sent = counters.snapshot();
      counters.acknowledge(sent);
      counters.add(KioskCounters.orders);
      final windowStart = counters.windowStartAt;

      counters.acknowledge(sent);
      expect(counters[KioskCounters.orders], 1);
      expect(counters.windowStartAt, windowStart);
    });

    test('the next window always starts later, even within the same instant', () {
      final sent = counters.snapshot();
      counters.acknowledge(sent);
      expect(counters.windowStartAt.isAfter(start), isTrue);
    });

    test('nothing negative or zero is added', () {
      counters.add(KioskCounters.orders, 0);
      counters.add(KioskCounters.orders, -3);
      expect(counters[KioskCounters.orders], 0);
    });
  });

  group('kept on the device', () {
    test('what an earlier session left unsent comes back with its window', () async {
      store.saved = jsonEncode({
        'windowStartAt': '2026-10-12T13:00:00.000Z',
        'values': {'orders': 4, 'chargesStarted': 1},
      });
      counters.add(KioskCounters.orders);
      await counters.restore();
      expect(counters[KioskCounters.orders], 5);
      expect(counters[KioskCounters.chargesStarted], 1);
      expect(counters.windowStartAt, DateTime.utc(2026, 10, 12, 13));
    });

    test('a save before the restore does not write over what was left unsent', () async {
      store.saved = jsonEncode({'windowStartAt': '2026-10-12T13:00:00.000Z', 'values': {'orders': 4}});
      counters = KioskCounters(
          store: store, now: () => now, saveDelay: const Duration(milliseconds: 10));
      // The first health check counts within seconds of the start, long
      // before the first heartbeat restores.
      counters.add(KioskCounters.posHealthChecks);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final saved = jsonDecode(store.saved!) as Map;
      expect(saved['windowStartAt'], '2026-10-12T13:00:00.000Z');
      expect(saved['values'], {'orders': 4, 'posHealthChecks': 1});

      await counters.restore();
      expect(counters[KioskCounters.orders], 4);
      expect(counters[KioskCounters.posHealthChecks], 1);
      expect(counters.windowStartAt, DateTime.utc(2026, 10, 12, 13));
    });

    test('restores only once', () async {
      store.saved = jsonEncode({'windowStartAt': '2026-10-12T13:00:00.000Z', 'values': {'orders': 4}});
      await counters.restore();
      await counters.restore();
      expect(counters[KioskCounters.orders], 4);
    });

    test('an unreadable store starts over', () async {
      store.saved = 'not json';
      await counters.restore();
      expect(counters.snapshot().values, isEmpty);
      expect(counters.windowStartAt, start);
    });

    test('flush saves the window and the values', () async {
      counters.add(KioskCounters.printsOk, 2);
      await counters.flush();
      final saved = jsonDecode(store.saved!) as Map;
      expect(saved['windowStartAt'], '2026-10-12T14:00:00.000Z');
      expect(saved['values'], {'printsOk': 2});
    });
  });

  group('from the events the payment flow records', () {
    List<String> of(String type, [Map<String, Object?> data = const {}]) =>
        KioskCounters.countersFor(_event(type, data));

    test('charges started, and those the terminal could not take', () {
      expect(of('charge.start'), [KioskCounters.chargesStarted]);
      expect(of('charge.start', {'provider': 'atc'}), [KioskCounters.chargesStarted]);
      expect(of('charge.not_started'), [KioskCounters.chargesStarted, KioskCounters.chargesError]);
    });

    test('each verdict', () {
      expect(of('charge.result', {'status': 'success'}), [KioskCounters.chargesApproved]);
      expect(of('charge.result', {'status': 'error'}), [KioskCounters.chargesDeclined]);
      expect(of('charge.result', {'status': 'cancelled'}), [KioskCounters.chargesDeclined]);
      expect(of('charge.result', {'status': 'pending'}), [KioskCounters.chargesTimeout]);
      expect(of('charge.result', {'status': 'unreachable'}), [KioskCounters.chargesTimeout]);
      expect(of('charge.timeout', {'status': 'unknown'}), [KioskCounters.chargesTimeout]);
      expect(of('charge.result', {'status': 'notFound'}), [KioskCounters.chargesError]);
      expect(of('charge.result', {'status': 'no_session'}), [KioskCounters.chargesError]);
      expect(of('charge.result', {'status': 'failed', 'provider': 'linkser'}),
          [KioskCounters.chargesError]);
    });

    test('charged and not registered: once, not on every retry of the recovery', () {
      expect(of('charge.register_failed', {'error': 'x'}), [KioskCounters.chargesUnregistered]);
      expect(of('charge.register_failed', {'recovered': false}), isEmpty);
      expect(of('charge.register_failed', {'recovered': true}),
          [KioskCounters.chargesApproved, KioskCounters.chargesUnregistered]);
      expect(of('charge.registered_late', {'recovered': true}), [KioskCounters.chargesApproved]);
      expect(of('charge.registered_late', {'recovered': false}), isEmpty);
    });

    test('charges a reload cut off and the recovery settled', () {
      expect(of('charge.recovered', {'status': 'ERROR'}), [KioskCounters.chargesDeclined]);
      expect(of('charge.recovered', {'status': 'not_found'}), [KioskCounters.chargesTimeout]);
    });

    test('prints, and nothing for the rest', () {
      expect(of('print.ok'), [KioskCounters.printsOk]);
      expect(of('print.failed'), [KioskCounters.printsFailed]);
      expect(of('charge.pay_ack'), isEmpty);
      expect(of('pos.health_failed'), isEmpty);
    });

    test('Telemetry tells the counters of every event it records', () {
      Telemetry.install(Telemetry(observers: [counters.observe]));
      Telemetry.event('charge.start', chargeId: 'CHG-1');
      Telemetry.event('charge.result', data: {'status': 'success'});
      Telemetry.event('web.visibility');
      expect(counters[KioskCounters.chargesStarted], 1);
      expect(counters[KioskCounters.chargesApproved], 1);
    });

    test('an observer that throws does not stop the recording', () {
      Telemetry.install(Telemetry(observers: [(_) => throw StateError('boom')]));
      final event = Telemetry.instance.record('charge.start');
      expect(event, isNotNull);
      expect(Telemetry.recent().single.type, 'charge.start');
    });
  });
}
