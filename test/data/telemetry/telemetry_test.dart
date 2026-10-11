import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/telemetry/pos_telemetry.dart';
import 'package:izi_kiosco/data/telemetry/send_budget.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_buffer.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';
import 'package:izi_kiosco/data/telemetry/tracked_http_client.dart';

class RecordingSink implements TelemetrySink {
  final List<({TelemetryEvent event, bool log, bool issue})> received = [];
  Map<String, Object?> context = const {};

  @override
  void onEvent(TelemetryEvent event, {required bool sendLog, required bool sendIssue}) =>
      received.add((event: event, log: sendLog, issue: sendIssue));

  @override
  void setContext(Map<String, Object?> context) => this.context = context;
}

void main() {
  group('TelemetryRedactor', () {
    test('drops the value of every key that names a secret', () {
      final out = TelemetryRedactor.redact({
        'token': 'abc',
        'mqttPassword': 'P',
        'mqttClientId': 'CAJA1',
        'pin': '4826',
        'Authorization': 'Bearer x',
        'cardNumber': '4111111111111111',
        'commerceId': '22000001',
        'cajaId': '1',
        'authCode': '123456',
        'signature': 'deadbeef',
        'nested': {'secretKey': 'x', 'ok': 1},
      });
      for (final key in out.keys.where((k) => k != 'nested')) {
        expect(out[key], TelemetryRedactor.mask, reason: key);
      }
      expect(out['nested'], {'secretKey': TelemetryRedactor.mask, 'ok': 1});
    });

    test('keeps what diagnosis needs', () {
      final data = {
        'company': 'Gasaje',
        'cardType': 'CREDITO',
        'cardBrand': 'VISA',
        'paired': true,
        'pairedKioskHash': 'a1b2c3',
        'address': '192.168.0.18:8081',
        'amount': '150000.00',
        'quotas': 3,
        'reference': 'KOS-1727600000000-AB12',
        'ms': 4012,
      };
      expect(TelemetryRedactor.redact(data), data);
    });

    test('scrubs card numbers, bearer tokens and URL queries inside text', () {
      expect(TelemetryRedactor.scrub('tarjeta 4111 1111 1111 1111 rechazada'),
          'tarjeta ${TelemetryRedactor.mask} rechazada');
      expect(TelemetryRedactor.scrub('pan=5500-0000-0000-0004'),
          'pan=${TelemetryRedactor.mask}');
      expect(TelemetryRedactor.scrub('header Bearer tok-123 sent'),
          'header Bearer ${TelemetryRedactor.mask} sent');
      expect(
          TelemetryRedactor.scrub(
              'WebSocketChannelException: ws://10.0.0.5:8081/payment-updates?token=s3cret failed'),
          'WebSocketChannelException: ws://10.0.0.5:8081/payment-updates?${TelemetryRedactor.mask} failed');
      expect(TelemetryRedactor.scrub('retry with token=abc&x=1'),
          'retry with token=${TelemetryRedactor.mask}&x=1');
    });

    test('keeps kiosk references, which carry a 13-digit timestamp', () {
      expect(TelemetryRedactor.scrub('Ref. KOS-1727600000000-AB12'),
          'Ref. KOS-1727600000000-AB12');
      expect(TelemetryRedactor.scrub('CHG-1727600000000-x1y2z3'),
          'CHG-1727600000000-x1y2z3');
    });

    test('shortens long text', () {
      final out = TelemetryRedactor.scrub('x' * 1000);
      expect(out.length, TelemetryRedactor.maxStringLength + 1);
    });
  });

  group('SendBudget', () {
    test('caps issues per day and per kind, and starts again the next day', () {
      var now = DateTime(2026, 9, 29, 10);
      final budget = SendBudget(maxIssuesPerDay: 4, maxPerIssuePerDay: 2, now: () => now);
      expect([for (var i = 0; i < 3; i++) budget.allowIssue('a')], [true, true, false]);
      expect(budget.allowIssue('b'), isTrue);
      expect(budget.allowIssue('c'), isTrue);
      expect(budget.allowIssue('d'), isFalse, reason: '4 a day');
      now = DateTime(2026, 9, 30, 0, 1);
      expect(budget.allowIssue('a'), isTrue);
    });

    test('caps logs of one type per hour, each type on its own', () {
      var now = DateTime(2026, 9, 29, 10, 5);
      final budget = SendBudget(maxLogsPerTypePerHour: 2, now: () => now);
      expect([for (var i = 0; i < 3; i++) budget.allowLog('pos.health_failed')],
          [true, true, false]);
      expect(budget.allowLog('charge.start'), isTrue);
      now = DateTime(2026, 9, 29, 11);
      expect(budget.allowLog('pos.health_failed'), isTrue);
    });
  });

  group('TelemetryBuffer', () {
    test('keeps the last events, newest first, and survives a reload', () async {
      final store = MemoryTelemetryStore();
      final buffer = TelemetryBuffer(store: store, capacity: 3, saveDelay: Duration.zero);
      final telemetry = Telemetry(buffer: buffer);
      for (var i = 0; i < 5; i++) {
        telemetry.record('e$i');
      }
      expect(buffer.recent().map((e) => e.type), ['e4', 'e3', 'e2']);
      await buffer.flush();

      final reloaded = TelemetryBuffer(store: store, capacity: 3);
      await reloaded.restore();
      expect(reloaded.recent().map((e) => e.type), ['e4', 'e3', 'e2']);
    });

    test('a broken store leaves the buffer empty instead of failing', () async {
      final buffer = TelemetryBuffer(store: MemoryTelemetryStore()..saved = ['{nope', '[]']);
      await buffer.restore();
      expect(buffer.length, 0);
    });
  });

  group('Telemetry', () {
    test('redacts before keeping or sending, and respects the budget', () {
      final sink = RecordingSink();
      final telemetry = Telemetry(
          sink: sink, budget: SendBudget(maxLogsPerTypePerHour: 1, maxIssuesPerDay: 1));
      telemetry.record('charge.result',
          chargeId: 'CHG-1', reference: 'KOS-1', data: {'token': 't', 'status': 'unknown'}, issue: true);
      telemetry.record('charge.result', data: {'status': 'unknown'}, issue: true);

      expect(telemetry.buffer.recent().last.data['token'], TelemetryRedactor.mask);
      expect(sink.received.map((r) => (r.log, r.issue)), [(true, true), (false, false)]);
      expect(sink.received.first.event.chargeId, 'CHG-1');
    });

    test('context is merged, and null removes a key', () {
      final sink = RecordingSink();
      final telemetry = Telemetry(sink: sink);
      telemetry.updateContext({'contribuyente.id': 106489, 'dispositivo.id': 110});
      telemetry.updateContext({'dispositivo.id': null, 'sucursal.id': 7});
      expect(sink.context, {'contribuyente.id': 106489, 'sucursal.id': 7});
    });
  });

  group('posFailureCause', () {
    test('names the cause of a failed call', () {
      expect(posFailureCause(IzifyPosException('x', cause: TimeoutException('t'))), 'timeout');
      expect(
          posFailureCause(IzifyPosException('x',
              cause: const SocketException('refused', osError: OSError('refused', 111)))),
          'refused');
      expect(
          posFailureCause(IzifyPosException('x',
              cause: const SocketException('no route', osError: OSError('no route', 113)))),
          'unreachable');
      expect(posFailureCause(IzifyPosException('x', cause: http.ClientException('XMLHttpRequest error.'))),
          'browser_blocked');
      expect(posFailureCause(const IzifyPosException('x', statusCode: 503)), 'http_503');
      expect(posFailureCause(const IzifyPosException('x', code: 'NOT_READY')), 'NOT_READY');
    });
  });

  group('PosLinkTracker', () {
    setUp(() => Telemetry.install(Telemetry()));

    List<String> types() => Telemetry.recent(limit: 1000).reversed.map((e) => e.type).toList();

    test('records failures, then samples them, then the recovery', () async {
      final tracker = PosLinkTracker('test');
      const address = IzifyPosAddress('10.0.0.5');
      for (var i = 0; i < 25; i++) {
        await tracker.failed(
            address: address, rid: 'r$i', ms: 4000, error: IzifyPosException('x', cause: TimeoutException('t')));
      }
      final failures = types().where((t) => t == 'pos.health_failed').length;
      expect(failures, PosLinkTracker.detailedFailures + 1, reason: 'the first 10, then #20');
      tracker.answered(address: address, ms: 30);
      final recovered = Telemetry.recent().first;
      expect(recovered.type, 'pos.health_recovered');
      expect(recovered.data['failures'], 25);
      expect(recovered.data['source'], 'test');
      expect(tracker.consecutiveFailures, 0);
    });

    test('records when the terminal stops and starts being ready', () {
      final tracker = PosLinkTracker('test');
      const address = IzifyPosAddress('10.0.0.5');
      tracker.answered(address: address, ms: 10);
      tracker.answered(address: address, ms: 10, notReadyReason: 'Sin internet');
      tracker.answered(address: address, ms: 10, notReadyReason: 'Sin internet');
      tracker.answered(address: address, ms: 10);
      expect(types(), ['pos.not_ready', 'pos.ready']);
    });
  });

  group('TrackedHttpClient', () {
    setUp(() => Telemetry.install(Telemetry()));

    test('counts open requests and reports one that settles late', () async {
      final release = Completer<void>();
      final client = TrackedHttpClient(
        MockClient((req) async {
          await release.future;
          return http.Response('{}', 200);
        }),
        lateAfter: const Duration(milliseconds: 20),
      );
      final pending = client.get(Uri.parse('http://10.0.0.5:8081/payment-status/KOS-1?token=x'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(TrackedHttpClient.inFlight, 1);
      expect(TrackedHttpClient.oldestInFlightMs, greaterThanOrEqualTo(20));
      release.complete();
      await pending;
      expect(TrackedHttpClient.inFlight, 0);
      final late = Telemetry.recent().single;
      expect(late.type, 'http.late_settle');
      expect(late.data['path'], '/payment-status/KOS-1');
      expect(late.data['outcome'], '200');
      expect(late.data.toString(), isNot(contains('token')));
    });
  });

  group('IzifyPosClient telemetry fields', () {
    test('/health carries the request id when given', () async {
      Uri? seen;
      final client = IzifyPosClient(
          httpClient: MockClient((req) async {
        seen = req.url;
        return http.Response(jsonEncode({'status': 'OK', 'paired': true}), 200);
      }));
      await client.health(const IzifyPosAddress('10.0.0.5'), rid: 'abc123');
      expect(seen?.queryParameters['rid'], 'abc123');
      await client.health(const IzifyPosAddress('10.0.0.5'));
      expect(seen?.hasQuery, isFalse);
    });

    test('/pay sends the charge id unsigned, outside the signature', () async {
      Map<String, dynamic>? body;
      final client = IzifyPosClient(
          httpClient: MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'success': true}), 202);
      }));
      await client.pay(const IzifyPosAddress('10.0.0.5'),
          token: 't', amount: '10.00', currency: 'COP', reference: 'KOS-1',
          cardType: 'DEBITO', quotas: 0, chargeId: 'CHG-1');
      expect(body?['correlationId'], 'CHG-1');
      expect(body?['signature'],
          IzifyPosClient.sign(token: 't', amount: '10.00', currency: 'COP', reference: 'KOS-1'));
    });

    test('a failed call keeps what the platform said', () async {
      final client = IzifyPosClient(
          httpClient: MockClient((req) async => throw http.ClientException('XMLHttpRequest error.')));
      final error = await client
          .health(const IzifyPosAddress('10.0.0.5'))
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(error, isA<IzifyPosException>());
      expect((error as IzifyPosException).cause, isA<http.ClientException>());
    });

    test('/diagnostics: null on a terminal too old to have it', () async {
      final client = IzifyPosClient(
          httpClient: MockClient((req) async => req.url.path == '/diagnostics'
              ? http.Response('Not Found', 404)
              : http.Response('', 500)));
      expect(await client.diagnostics(const IzifyPosAddress('10.0.0.5'), token: 't'), isNull);
    });

    test('/diagnostics: the terminal record, asked with the pairing token', () async {
      String? auth;
      final client = IzifyPosClient(
          httpClient: MockClient((req) async {
        auth = req.headers['Authorization'];
        return http.Response(jsonEncode({'events': [], 'device': {'batteryPct': 80}}), 200);
      }));
      final data = await client.diagnostics(const IzifyPosAddress('10.0.0.5'), token: 't');
      expect(auth, 'Bearer t');
      expect(data?['device'], {'batteryPct': 80});
    });
  });
}
