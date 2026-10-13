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
}
