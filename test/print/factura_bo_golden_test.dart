import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy_factory.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';

import 'fixture_http_overrides.dart';
import 'ticket_texto.dart';

/// La plantilla local de la factura de Bolivia del kiosco (la que se usa cuando la factura no trae los printItems del
/// backbone), fijada con el fixture bo.json. UPDATE_GOLDEN=1 flutter test test/print/factura_bo_golden_test.dart reescribe
/// los goldens tras un cambio deliberado.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixture = jsonDecode(File('test/print/fixtures/bo.json').readAsStringSync()) as Map<String, dynamic>;
  final contribuyente = Contribuyente.fromJson(Map<String, dynamic>.from(fixture['contribuyente'] as Map));
  final sucursal = Sucursal.fromJson(Map<String, dynamic>.from(fixture['sucursal'] as Map));
  Invoice factura(String clave) => Invoice.fromJson(Map<String, dynamic>.from(fixture[clave] as Map));
  Future<List<IziPrintItem>> ticket(Invoice invoice, {bool compacto = false}) => compacto
      ? PrintTemplate.printInvoiceCompact(contribuyente, sucursal, invoice, taxesStrategy: TaxesStrategyFactory.taxes(contribuyente))
      : PrintTemplate.printInvoice(contribuyente, sucursal, invoice, taxesStrategy: TaxesStrategyFactory.taxes(contribuyente));

  setUpAll(() {
    dotenv.testLoad(fileInput: 'BRAND_NAME=iZi');
    HttpOverrides.global = FixtureHttpOverrides(Uint8List(0));
  });

  final casos = <String, (String, bool)>{
    'factura-bo-detallada': ('facturaEmitida', false),
    'factura-bo-compacta': ('facturaEmitida', true),
    'prefactura-bo': ('prefactura', false),
    // Régimen por fuera (Ley 1733): facturas capturadas del backbone real, con el formato del anexo 3.0.
    'factura-bo-por-fuera': ('facturaPorFuera', false),
    'factura-bo-por-fuera-compacta': ('facturaPorFuera', true),
    'factura-bo-por-fuera-dolares': ('facturaPorFueraDolares', false),
    'prefactura-bo-por-fuera': ('prefacturaPorFuera', false),
    'factura-bo-por-fuera-ice': ('facturaIcePorFuera', false),
  };

  for (final caso in casos.entries) {
    test('el ticket ${caso.key} no cambió', () async {
      final actual = ticketTexto(await ticket(factura(caso.value.$1), compacto: caso.value.$2));
      final golden = File('test/print/goldens/${caso.key}.txt');
      if (Platform.environment['UPDATE_GOLDEN'] != null) {
        golden.createSync(recursive: true);
        golden.writeAsStringSync(actual);
      }
      expect(golden.existsSync(), isTrue, reason: 'falta el golden ${golden.path}');
      expect(actual, golden.readAsStringSync());
    });
  }

  Future<List<String>> pie(Map<String, dynamic> json) async =>
      (await ticket(Invoice.fromJson(json))).whereType<IziPrintRow>().where((r) => r.values.length == 2).map((r) => '${r.values[0].text} ${r.values[1].text}').toList();
  Future<List<String>> etiquetasDelPie(Map<String, dynamic> json) async =>
      (await pie(json)).map((f) => f.substring(0, f.lastIndexOf(' '))).toList();

  group('régimen por fuera', () {
    Map<String, dynamic> copia(String clave) => jsonDecode(jsonEncode(fixture[clave])) as Map<String, dynamic>;

    test('el pie es el del SIN con los totales de customFactura.totalesPorFuera', () async {
      final t = fixture['facturaPorFuera']['customFactura']['totalesPorFuera'] as Map;
      String dos(dynamic n) => (n as num).toStringAsFixed(2);
      expect(await pie(copia('facturaPorFuera')), [
        'SUBTOTAL ${dos(t['subTotalNeto'])}', 'MONTO GIFT CARD ${dos(t['montoGiftCard'])}', 'TOTAL PRECIO NETO ${dos(t['totalPrecioNeto'])}',
        'DESCUENTO ${dos(t['descuentoAdicional'])}', 'IVA ${dos(t['iva'])}', 'MONTO A PAGAR ${dos(t['montoaPagar'])}',
      ]);
    });

    test('el alquiler no tiene gift card, el boleto tampoco descuento y el ICE lleva sus totales en lugar de la gift card', () async {
      Map<String, dynamic> de(int tipo, {bool ice = false}) {
        final json = copia('facturaPorFuera')..['tipoFactura'] = tipo;
        if (ice) (json['customFactura']['totalesPorFuera'] as Map).addAll(<String, dynamic>{'montoIcePorcentual': 0, 'montoIceEspecifico': 0});
        return json;
      }
      expect(await etiquetasDelPie(de(3)), ['SUBTOTAL', 'TOTAL PRECIO NETO', 'DESCUENTO', 'IVA', 'MONTO A PAGAR']);
      expect(await etiquetasDelPie(de(30)), ['SUBTOTAL', 'TOTAL PRECIO NETO', 'IVA', 'MONTO A PAGAR']);
      expect(await etiquetasDelPie(de(6, ice: true)),
          ['SUBTOTAL', 'TOTAL ICE PORCENTUAL', 'TOTAL ICE ESPECÍFICO', 'TOTAL PRECIO NETO', 'DESCUENTO', 'IVA', 'MONTO A PAGAR']);
    });

    test('la factura ICE lleva su ICE en el subtotal de la línea y en el del pie, como el XML; la línea sin ICE queda en su neto', () async {
      // Los montos del ejemplo del anexo v0.1: línea 47,58 + 11,13 + 0,48 = 59,19 y pie 162,60 + 33,39 + 1,63 = 197,62.
      final json = copia('facturaPorFuera')..['tipoFactura'] = 6;
      (json['listaItems'] as List).first.addAll(<String, dynamic>{'subTotalNeto': 47.58, 'montoIceEspecifico': 11.13, 'montoIcePorcentual': 0.48});
      (json['customFactura']['totalesPorFuera'] as Map)
          .addAll(<String, dynamic>{'subTotalNeto': 162.6, 'montoIceEspecifico': 33.39, 'montoIcePorcentual': 1.63});
      final items = await ticket(Invoice.fromJson(json));
      final subtotales = items.whereType<IziPrintRow>().where((r) => r.values.length == 5).map((r) => r.values[4].text).skip(1).toList();
      expect(subtotales, ['59.19', '22.34']);
      expect((await pie(json)).take(3), ['SUBTOTAL 197.62', 'TOTAL ICE PORCENTUAL 1.63', 'TOTAL ICE ESPECÍFICO 33.39']);
    });

    test('el recibo sin facturación y la factura vuelta al incluido con los totales viejos siguen con el pie de siempre', () async {
      final recibo = copia('facturaPorFuera');
      (recibo['customFactura'] as Map).remove('siat');
      final vuelta = copia('facturaPorFuera');
      vuelta['customFactura']['regimenIva'] = 'incluido';
      for (final json in [recibo, vuelta]) {
        expect(await etiquetasDelPie(json), ['SUBTOTAL', 'DESCUENTO', 'TOTAL', 'MONTO GIFT-CARD', 'IMPORTE BASE DE CREDITO FISCAL', 'TOTAL A PAGAR']);
      }
    });

    test('las líneas van en HALF-UP como el XML y el «un» de 1000 a 1999 sale con el monto a pagar', () async {
      final json = copia('prefacturaPorFuera');
      json['prefactura'] = 0;
      (json['listaItems'] as List).first['precioNetoUnitario'] = 2.675;
      json['customFactura']['totalesPorFuera']['montoaPagar'] = 1500;
      final items = await ticket(Invoice.fromJson(json));
      expect(items.whereType<IziPrintRow>().where((r) => r.values.length == 5).map((r) => r.values[2].text), contains('2.68'));
      expect(items.whereType<IziPrintText>().map((t) => t.text), contains('SON:  Un mil quinientos 0/100 Bolivianos'));
    });

    test('el compacto muestra la gift card solo si la hubo', () async {
      final sinGiftCard = copia('facturaPorFuera');
      sinGiftCard['customFactura']['totalesPorFuera']['montoGiftCard'] = 0;
      final textos = (await ticket(Invoice.fromJson(sinGiftCard), compacto: true)).whereType<IziPrintText>().map((t) => t.text).where((t) => t.startsWith('MONTO'));
      expect(textos, ['MONTO A PAGAR Bs: 120.00']);
    });
  });
}
