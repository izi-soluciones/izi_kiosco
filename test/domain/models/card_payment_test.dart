import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';

void main() {
  group('CardPayment.fromJson', () {
    test('maps Spanish payload keys with empty-string defaults', () {
      final cp = CardPayment.fromJson(
          {'mensaje': 'Aprobada', 'pan': '****1234', 'fecha': '2024-01-01', 'hora': '10:00'});
      expect(cp.response, 'Aprobada');
      expect(cp.cardNumber, '****1234');
      expect(cp.date, '2024-01-01');
      expect(cp.hour, '10:00');
    });
    test('defaults missing keys to empty strings', () {
      final cp = CardPayment.fromJson({});
      expect(cp.response, '');
      expect(cp.cardNumber, '');
      expect(cp.date, '');
      expect(cp.hour, '');
    });
  });

  group('CardPayment.fromJsonStorage / toJson round trip', () {
    test('restores all persisted fields', () {
      final json = {
        'respuesta': 'Aprobada',
        'tarjeta': '****1',
        'fecha': '2024-01-01',
        'hora': '10:00',
        'referencia': 'ref-1',
        'monto': '12.50',
        'moneda': 'COP',
        'transactionId': 'tx-1',
        'estado': 'SUCCESS',
      };
      final cp = CardPayment.fromJsonStorage(json);
      expect(cp.reference, 'ref-1');
      expect(cp.amount, '12.50');
      expect(cp.currency, 'COP');
      expect(cp.status, 'SUCCESS');
      // toJson emits the same storage shape.
      expect(cp.toJson(), json);
    });
    test('toJson omits optional null fields', () {
      final cp = CardPayment(
          response: 'x', cardNumber: '1', date: 'd', hour: 'h');
      final json = cp.toJson();
      expect(json.containsKey('referencia'), isFalse);
      expect(json.containsKey('estado'), isFalse);
      expect(json['respuesta'], 'x');
    });

    test("a row of an older build with the account's money: what was charged is what counts", () {
      final cp = CardPayment.fromJsonStorage({
        'respuesta': 'En curso',
        'tarjeta': '****',
        'fecha': '2026-11-18',
        'hora': '10:00',
        'referencia': 'KOS-OLD',
        'moneda': 'COP',
        'monedaVenta': 'BOB',
      });
      expect(cp.currency, 'COP');
      expect(cp.chargedCurrency, 'COP');
      expect(cp.toJson().containsKey('monedaVenta'), isFalse,
          reason: 'stored again, it keeps only the money it was charged in');
      expect(cp.toJson()['moneda'], 'COP');
      expect(cp.terminalData('APROBADA')['moneda'], 'COP');
    });

    test('charged in: the money stored with it, COP for an Izify row from before it was stored', () {
      CardPayment row({String? reference, String? currency}) => CardPayment(
          response: 'x', cardNumber: '****', date: 'd', hour: 'h', reference: reference, currency: currency);
      expect(row(reference: 'KOS-1', currency: 'COP').chargedCurrency, 'COP');
      expect(row(reference: 'KOS-1').chargedCurrency, 'COP',
          reason: 'an Izify POS has only ever been asked for pesos');
      expect(row().chargedCurrency, isNull, reason: 'an ATC / Linkser row says nothing of its money');
    });
  });

  group('CardPayment.retryStatus (explicit status wins)', () {
    CardPayment withStatus(String? s) =>
        CardPayment(response: '', cardNumber: '', date: '', hour: '', status: s);

    test('SUCCESS -> success (no retry)', () {
      final cp = withStatus('SUCCESS');
      expect(cp.retryStatus, CardPaymentStatus.success);
      expect(cp.canRetry, isFalse);
      expect(cp.retryNeedsWarning, isFalse);
    });
    test('ERROR / CANCELLED -> declined (retry, no warning)', () {
      expect(withStatus('ERROR').retryStatus, CardPaymentStatus.declined);
      expect(withStatus('CANCELLED').retryStatus, CardPaymentStatus.declined);
      expect(withStatus('ERROR').canRetry, isTrue);
      expect(withStatus('ERROR').retryNeedsWarning, isFalse);
    });
    test('PENDING / UNKNOWN -> pending (retry needs warning)', () {
      expect(withStatus('PENDING').retryStatus, CardPaymentStatus.pending);
      expect(withStatus('UNKNOWN').retryStatus, CardPaymentStatus.pending);
      expect(withStatus('PENDING').retryNeedsWarning, isTrue);
    });
  });

  group('CardPayment.retryStatus (legacy text fallback)', () {
    CardPayment withResponse(String r) =>
        CardPayment(response: r, cardNumber: '', date: '', hour: '');

    test('approved text -> success', () {
      expect(withResponse('Aprobada - Error sync server').retryStatus,
          CardPaymentStatus.success);
      expect(withResponse('Aprobado').retryStatus, CardPaymentStatus.success);
    });
    test('pending / unconfirmed text -> pending', () {
      expect(withResponse('Pendiente').retryStatus, CardPaymentStatus.pending);
      expect(withResponse('Transaccion sin confirmar').retryStatus,
          CardPaymentStatus.pending);
    });
    test('rejected / cancelled text -> declined', () {
      expect(withResponse('Rechazada').retryStatus, CardPaymentStatus.declined);
      expect(withResponse('Operacion cancelada').retryStatus,
          CardPaymentStatus.declined);
    });
    test('unrecognized text -> unknown (retry with warning)', () {
      final cp = withResponse('algo raro');
      expect(cp.retryStatus, CardPaymentStatus.unknown);
      expect(cp.retryNeedsWarning, isTrue);
    });
  });
}
