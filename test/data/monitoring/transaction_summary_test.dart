import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/transaction_summary.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';

void main() {
  late DateTime now;
  final start = DateTime.utc(2026, 10, 12, 14);

  TransactionSummary card() => TransactionSummary(
      method: TxMethod.card,
      chargeId: 'CHG-1',
      amount: 15000,
      currency: 'COP',
      comandaId: 'comanda-1',
      now: () => now);

  setUp(() {
    now = start;
    Telemetry.install(Telemetry());
  });

  List<TelemetryEvent> summaries() =>
      Telemetry.recent().reversed.where((e) => e.type == 'tx.summary').toList();

  group('the data', () {
    test('carries every field of the contract', () {
      final tx = card()..sent(reference: 'KOS-1');
      now = now.add(const Duration(milliseconds: 800));
      tx.acknowledged();
      now = now.add(const Duration(seconds: 14));
      tx.verdict(via: 'ws');
      tx.facturaId = 'factura-1';

      expect(tx.finish(TxStatus.approved), {
        'chargeId': 'CHG-1',
        'reference': 'KOS-1',
        'amount': 15000,
        'currency': 'COP',
        'method': 'card',
        'status': 'approved',
        'verdictVia': 'ws',
        'comandaId': 'comanda-1',
        'facturaId': 'factura-1',
        'msToAck': 800,
        'msToVerdict': 14800,
        'attempts': 1,
      });
    });

    test('a transaction is summed up once', () {
      final tx = card()..sent(reference: 'KOS-1');
      expect(tx.finish(TxStatus.declined), isNotNull);
      expect(tx.finish(TxStatus.approved), isNull);
      expect(tx.reported, isTrue);
    });

    test('unknown timings and ids stay null, never 0', () {
      final data = TransactionSummary(method: TxMethod.qr, now: () => now).finish(TxStatus.error)!;
      expect(data['msToAck'], isNull);
      expect(data['msToVerdict'], isNull);
      expect(data['verdictVia'], isNull);
      expect(data['reference'], isNull);
      expect(data['attempts'], 0, reason: 'nothing reached the customer');
    });

    test('the first verdict is the one kept', () {
      final tx = card()..sent(reference: 'KOS-1');
      now = now.add(const Duration(seconds: 3));
      tx.verdict(via: 'poll');
      now = now.add(const Duration(seconds: 3));
      tx.verdict(via: 'ws');
      final data = tx.finish(TxStatus.approved)!;
      expect(data['verdictVia'], 'poll');
      expect(data['msToVerdict'], 3000);
    });

    test('a new attempt counts and times from its own sending', () {
      final tx = TransactionSummary(method: TxMethod.card, attempts: 1, now: () => now)
        ..sent(reference: 'KOS-2');
      now = now.add(const Duration(seconds: 2));
      tx.verdict(via: 'ws');
      final data = tx.finish(TxStatus.approved)!;
      expect(data['attempts'], 2);
      expect(data['reference'], 'KOS-2');
      expect(data['msToVerdict'], 2000);
    });

    test('a clock set back never makes a negative duration', () {
      final tx = card()..sent();
      now = now.subtract(const Duration(minutes: 1));
      tx.verdict();
      expect(tx.finish(TxStatus.approved)!['msToVerdict'], 0);
    });
  });

  group('verdictVia', () {
    test('only the words of the contract', () {
      expect(TxVerdictVia.of('ws'), 'ws');
      expect(TxVerdictVia.of('poll'), 'poll');
      expect(TxVerdictVia.of('timeout'), 'timeout');
      expect(TxVerdictVia.of('not_found'), 'poll', reason: 'heard by polling');
      expect(TxVerdictVia.of('socket'), isNull);
      expect(TxVerdictVia.of(null), isNull);
    });
  });

  group('settle', () {
    test('is reported when the transaction ends without a status of its own', () {
      final tx = card()..settle(TxStatus.approved);
      expect(tx.reported, isFalse);
      expect(tx.report(), isTrue);
      expect(summaries().single.data['status'], 'approved');
    });

    test('the first outcome noted stays', () {
      final tx = card()
        ..settle(TxStatus.approved)
        ..settle(TxStatus.cancelled);
      expect(tx.settled, TxStatus.approved);
    });

    test('nothing to report without an outcome', () {
      expect(card().report(), isFalse);
      expect(summaries(), isEmpty);
    });
  });

  group('report', () {
    test('records one tx.summary with the charge on the event', () {
      final tx = card()..sent(reference: 'KOS-1');
      expect(tx.report(TxStatus.approved), isTrue);
      expect(tx.report(TxStatus.approved), isFalse);

      final event = summaries().single;
      expect(event.chargeId, 'CHG-1');
      expect(event.reference, 'KOS-1');
      expect(event.level, TelemetryLevel.info);
      expect(event.data['method'], 'card');
    });

    test('the level says who has to look', () {
      expect(TransactionSummary.levelOf(TxStatus.approved), TelemetryLevel.info);
      expect(TransactionSummary.levelOf(TxStatus.declined), TelemetryLevel.info);
      expect(TransactionSummary.levelOf(TxStatus.cancelled), TelemetryLevel.info);
      expect(TransactionSummary.levelOf(TxStatus.timeout), TelemetryLevel.warning);
      expect(TransactionSummary.levelOf(TxStatus.error), TelemetryLevel.warning);
      expect(TransactionSummary.levelOf(TxStatus.unregistered), TelemetryLevel.error);
    });

    test('the ids the monitoring keys transactions by survive the redactor', () {
      final reference = 'KOS-${start.millisecondsSinceEpoch}-AB12';
      TransactionSummary(method: TxMethod.card, chargeId: 'CHG-1760277600000-QWERTY', now: () => now)
        ..sent(reference: reference)
        ..report(TxStatus.timeout);
      final data = summaries().single.data;
      expect(data['chargeId'], 'CHG-1760277600000-QWERTY');
      expect(data['reference'], reference);
      expect(jsonEncode(data), isNot(contains('[redactado]')));
    });

    test('feeds the counters of a QR payment, not of a card one', () {
      final counters = KioskCounters();
      Telemetry.install(Telemetry(observers: [counters.observe]));
      TransactionSummary(method: TxMethod.qr, now: () => now)
        ..sent()
        ..report(TxStatus.approved);
      card().report(TxStatus.approved);
      expect(counters[KioskCounters.chargesStarted], 1);
      expect(counters[KioskCounters.chargesApproved], 1);
    });
  });

  group('reportInterim', () {
    test('says how it stands, and the outcome reported later goes over it', () {
      final tx = card()..sent(reference: 'KOS-1');
      expect(tx.reportInterim(TxStatus.timeout), isTrue);
      expect(tx.interim, isTrue);
      expect(tx.reported, isFalse);
      expect(tx.reportInterim(TxStatus.timeout), isFalse, reason: 'once');

      now = now.add(const Duration(seconds: 3));
      tx.verdict(via: 'poll');
      expect(tx.report(TxStatus.declined), isTrue);
      expect(tx.report(TxStatus.error), isFalse, reason: 'the outcome stays');

      final events = summaries();
      expect([for (final e in events) e.data['status']], ['timeout', 'declined']);
      expect(events.first.level, TelemetryLevel.warning);
      expect(events.first.data['msToVerdict'], isNull);
      expect(events.last.data['msToVerdict'], 3000);
      expect(events.last.chargeId, events.first.chargeId, reason: 'the monitoring keeps the latest');
    });

    test('an outcome settled afterwards is reported right away: nobody waits for iZi', () {
      final tx = card()..sent(reference: 'KOS-1');
      tx.verdict(via: 'ws');
      tx.reportInterim(TxStatus.timeout);
      tx.settle(TxStatus.approved);
      expect(tx.reported, isTrue);
      expect([for (final e in summaries()) e.data['status']], ['timeout', 'approved']);
    });

    test('nothing once reported', () {
      final tx = card()..report(TxStatus.approved);
      expect(tx.reportInterim(TxStatus.timeout), isFalse);
      expect(summaries(), hasLength(1));
    });
  });

  group('from a stored card charge', () {
    test('takes what the row keeps', () {
      final cp = CardPayment(
          response: 'Sin confirmar (timeout)',
          cardNumber: '****',
          date: '2026-10-12',
          hour: '14:00',
          reference: 'KOS-9',
          amount: '15000.00',
          currency: 'COP',
          chargeId: 'CHG-9',
          attempts: 2,
          comandaId: 'comanda-9');
      final data = TransactionSummary.ofCardPayment(cp, now: () => now).finish(TxStatus.approved)!;
      expect(data['chargeId'], 'CHG-9');
      expect(data['reference'], 'KOS-9');
      expect(data['amount'], 15000);
      expect(data['currency'], 'COP');
      expect(data['method'], 'card');
      expect(data['comandaId'], 'comanda-9');
      expect(data['attempts'], 2);
    });

    test('an older row: one attempt when it has a reference, no amount when unreadable', () {
      final cp = CardPayment(
          response: 'Aprobada', cardNumber: '****', date: '2026-10-12', hour: '14:00',
          reference: 'KOS-9', amount: 'n/a');
      final data = TransactionSummary.ofCardPayment(cp).finish(TxStatus.approved)!;
      expect(data['attempts'], 1);
      expect(data['amount'], isNull);
    });

    test('the attempts and the order survive the row being stored', () {
      final cp = CardPayment(
          response: 'x', cardNumber: '****', date: 'd', hour: 'h', attempts: 3, comandaId: 'c-1');
      final back = CardPayment.fromJsonStorage(jsonDecode(jsonEncode(cp.toJson())));
      expect(back.attempts, 3);
      expect(back.comandaId, 'c-1');
      final old = CardPayment.fromJsonStorage({'respuesta': 'x', 'fecha': 'd', 'hora': 'h'});
      expect(old.attempts, isNull);
      expect(old.comandaId, isNull);
    });
  });

  test('currency of the country', () {
    expect(TransactionSummary.currencyOf('BO'), 'BOB');
    expect(TransactionSummary.currencyOf('co'), 'COP');
    expect(TransactionSummary.currencyOf('PE'), isNull);
    expect(TransactionSummary.currencyOf(null), isNull);
  });
}
