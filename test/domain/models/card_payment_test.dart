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

  test('fromJsonATC lee los campos que manda el servidor para una aprobada real', () {
    // Respuesta real del servidor POS para una aprobada (campo data de /v2/ctl)
    final cardPayment = CardPayment.fromJsonATC({
      "ipcaja": "192.168.0.101",
      "codigo_autorizacion": "413715",
      "monto_compra": "000000003000",
      "numero_recibo": "000009",
      "rrn": "629414000009",
      "terminal_id": "08185801",
      "fecha_transac": "1021",
      "hora_transac": "1456",
      "cod_respuesta": "00",
      "tipo_cuenta": "01",
      "numero_cuotas": "00",
      "ult_4_digitos": "4167",
      "mensaje_error": "0000000",
      "bin_tarjeta": "407400"
    });

    expect(cardPayment.response, '413715');
    expect(cardPayment.date, '1021');
    expect(cardPayment.hour, '1456');
    // Enmascarada para que la pantalla de errores de tarjeta, que corta los
    // últimos 4 de una tarjeta de más de 4 caracteres, la siga mostrando
    expect(cardPayment.cardNumber, '****4167');
    expect(cardPayment.cardNumber!.substring(cardPayment.cardNumber!.length - 4),
        '4167');
  });

  test('fromJsonATC sigue leyendo los nombres viejos', () {
    final cardPayment = CardPayment.fromJsonATC({
      "mensaje": "APROBADA",
      "pan": "407400******4167",
      "fecha": "2026-10-21",
      "hora": "14:56"
    });

    expect(cardPayment.response, 'APROBADA');
    expect(cardPayment.cardNumber, '407400******4167');
    expect(cardPayment.date, '2026-10-21');
    expect(cardPayment.hour, '14:56');
  });
}
