import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';

void main() {
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
