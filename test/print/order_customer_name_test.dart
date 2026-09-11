import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy_factory.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Contribuyente contribuyente;
  late Sucursal sucursal;
  late PaymentObj paymentObjSinPagador;

  setUpAll(() {
    final fixture =
        jsonDecode(File('test/print/fixtures/bo.json').readAsStringSync())
            as Map<String, dynamic>;
    contribuyente = Contribuyente.fromJson(
        Map<String, dynamic>.from(fixture['contribuyente'] as Map));
    sucursal =
        Sucursal.fromJson(Map<String, dynamic>.from(fixture['sucursal'] as Map));
    final comanda =
        Comanda.fromJson(Map<String, dynamic>.from(fixture['comanda'] as Map));
    paymentObjSinPagador = PaymentObj(
      id: comanda.id,
      uuid: comanda.uuid,
      custom: {},
      amount: comanda.montoTotal ?? 0,
      isComanda: true,
      items: comanda.listaItems
          .map((e) => ItemPaymentObj(
              quantity: e.cantidad ?? 0,
              custom: e.modificadores,
              name: e.nombre))
          .toList(),
    );
  });

  Future<List<String>> lineas(
      {String? clienteNombre, PaymentObj? paymentObj}) async {
    final items = await PrintTemplate.order80(
        45, null, contribuyente, sucursal, paymentObj ?? paymentObjSinPagador,
        null,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyente),
        clienteNombre: clienteNombre);
    return items
        .whereType<IziPrintText>()
        .map((e) => e.text)
        .toList();
  }

  test('la comanda imprime el nombre capturado en el pago', () async {
    final textos = await lineas(clienteNombre: 'Camila');
    expect(textos, contains('Cliente: Camila'));
  });

  test('el nombre se imprime sin espacios sobrantes', () async {
    final textos = await lineas(clienteNombre: '  Camila  ');
    expect(textos, contains('Cliente: Camila'));
  });

  test('sin nombre no se imprime la linea de cliente', () async {
    final textos = await lineas();
    expect(textos.where((t) => t.startsWith('Cliente:')), isEmpty);
  });

  test('sin nombre cae al pagador de la comanda', () async {
    final paymentObj = PaymentObj(
      id: paymentObjSinPagador.id,
      uuid: paymentObjSinPagador.uuid,
      custom: {
        'pagadorData': {'razonSocial': 'Bello SRL'}
      },
      amount: paymentObjSinPagador.amount,
      isComanda: true,
      items: paymentObjSinPagador.items,
    );
    final textos = await lineas(paymentObj: paymentObj);
    expect(textos, contains('Cliente: Bello SRL'));
  });
}
