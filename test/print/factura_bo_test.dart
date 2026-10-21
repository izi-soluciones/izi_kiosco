import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy_factory.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';

import 'fixture_http_overrides.dart';

List<String> _filas(List<IziPrintItem> items) => [
      for (final i in items)
        if (i is IziPrintRow) i.values.map((c) => c.text).join('|'),
    ];

List<String> _textos(List<IziPrintItem> items) => [
      for (final i in items)
        if (i is IziPrintText) i.text,
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> fixture;
  late Contribuyente contribuyente;
  late Sucursal sucursal;

  setUpAll(() async {
    await dotenv.load(fileName: 'assets/.env.stg');
    fixture = jsonDecode(File('test/print/fixtures/bo.json').readAsStringSync())
        as Map<String, dynamic>;
    HttpOverrides.global = FixtureHttpOverrides(Uint8List(0));
    contribuyente = Contribuyente.fromJson(
        Map<String, dynamic>.from(fixture['contribuyente'] as Map));
    sucursal = Sucursal.fromJson(
        Map<String, dynamic>.from(fixture['sucursal'] as Map));
  });

  Future<List<IziPrintItem>> ticket(Map<String, dynamic> json,
      {Sucursal? suc}) {
    final invoice = Invoice.fromJson(json);
    final taxes = TaxesStrategyFactory.taxes(contribuyente);
    if (suc != null) {
      return PrintTemplate.printInvoiceCompact(contribuyente, suc, invoice,
          taxesStrategy: taxes);
    }
    return PrintTemplate.printInvoice(contribuyente, sucursal, invoice,
        taxesStrategy: taxes);
  }

  Map<String, dynamic> facturaDolares() => {
        ...Map<String, dynamic>.from(fixture['facturaEmitida'] as Map),
        'monto': 200,
        'descuentos': 20,
        'montoTotal': 180,
        'giftCards': 36.31,
        'montoImpuesto': 1392.0,
        'descuentosImpuesto': 139.2,
        'montoTotalImpuesto': 1252.8,
        'giftCardsImpuesto': 252.71,
        'customFactura': {
          ...Map<String, dynamic>.from(
              (fixture['facturaEmitida'] as Map)['customFactura'] as Map),
          'moneda': {'id': 151, 'nombre': 'DOLAR', 'simbolo': 'USD'},
          'exRate': 6.96,
        },
      };

  test('factura del incluido en dolares: pie en bolivianos con gift card', () async {
    final filas = _filas(await ticket(facturaDolares()));

    expect(filas, containsAllInOrder([
      'SUBTOTAL|1392.00',
      'DESCUENTO|139.20',
      'TOTAL|1252.80',
      'MONTO GIFT-CARD|252.71',
      'IMPORTE BASE DE CREDITO FISCAL|1000.09',
      'TOTAL A PAGAR|1000.09',
    ]));
  });

  test('factura del incluido en dolares: Son del mismo monto que TOTAL A PAGAR con el cero', () async {
    final textos = _textos(await ticket(facturaDolares()));

    expect(textos.where((t) => t.startsWith('SON:')), [
      'SON:  Un mil 09/100 Bolivianos',
    ]);
  });

  test('encabezado de la tabla dice Desc.', () async {
    final filas = _filas(await ticket(facturaDolares()));

    expect(filas, contains('Cant.|Detalle|Precio U.|Desc.|Subtotal'));
    expect(filas.where((f) => f.contains('Desc U')), isEmpty);
  });

  test('ticket compacto: IMPORTE Bs en bolivianos', () async {
    final compacta = Sucursal.fromJson({
      ...Map<String, dynamic>.from(fixture['sucursal'] as Map),
      'config': {
        ...Map<String, dynamic>.from(
            (fixture['sucursal'] as Map)['config'] as Map? ?? {}),
        'tipoFacturaVentas': 'compacto',
      },
    });
    final textos = _textos(await ticket(facturaDolares(), suc: compacta));

    expect(textos, contains('IMPORTE Bs: 1252.8'));
  });

  test('factura en dolares: linea MONEDA (TIPO DE CAMBIO)', () async {
    final textos = _textos(await ticket(facturaDolares()));

    expect(textos, contains('MONEDA (TIPO DE CAMBIO): USD (6.96)'));
  });

  test('factura en bolivianos: sin linea MONEDA', () async {
    final json = facturaDolares();
    (json['customFactura'] as Map)['exRate'] = 1;
    final textos = _textos(await ticket(json));

    expect(textos.where((t) => t.startsWith('MONEDA')), isEmpty);
  });
}
