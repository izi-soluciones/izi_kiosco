import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy_factory.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';

import 'fixture_http_overrides.dart';

const _salida = '../print-preview/kiosco';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: 'assets/.env.stg');
    Directory(_salida).createSync(recursive: true);
  });

  for (final pais in ['co', 'bo']) {
    test('lotes de impresion local $pais', () async {
      final fixture = jsonDecode(
              File('test/print/fixtures/$pais.json').readAsStringSync())
          as Map<String, dynamic>;

      final logo = fixture['logo'];
      HttpOverrides.global = FixtureHttpOverrides(logo is Map
          ? base64Decode(logo['base64'] as String)
          : Uint8List(0));

      final contribuyente = Contribuyente.fromJson(
          Map<String, dynamic>.from(fixture['contribuyente'] as Map));
      final taxes = TaxesStrategyFactory.taxes(contribuyente);

      final sucursalJson =
          Map<String, dynamic>.from(fixture['sucursal'] as Map);
      final sucursal = Sucursal.fromJson(sucursalJson);
      final sucursalCompacta = Sucursal.fromJson({
        ...sucursalJson,
        'config': {
          ...Map<String, dynamic>.from(sucursalJson['config'] as Map? ?? {}),
          'tipoFacturaVentas': 'compacto',
        },
      });

      final invoice = Invoice.fromJson(
          Map<String, dynamic>.from(fixture['facturaEmitida'] as Map));
      final comanda = Comanda.fromJson(
          Map<String, dynamic>.from(fixture['comanda'] as Map));

      // Mismo armado que MakeOrderBloc hace tras emitir la orden.
      final paymentObj = PaymentObj(
        id: comanda.id,
        uuid: comanda.uuid,
        custom: comanda.custom is Map ? comanda.custom : {},
        amount: comanda.montoTotal ?? 0,
        isComanda: true,
        items: comanda.listaItems
            .map((e) => ItemPaymentObj(
                quantity: e.cantidad ?? 0,
                custom: e.modificadores,
                name: e.nombre))
            .toList(),
      );

      final currency = _monedaPrincipal(fixture, contribuyente);
      final orderNumber = comanda.numero?.toInt() ?? 0;
      final customOrderNumber =
          comanda.custom is Map && comanda.custom['numeroCustom'] is int
              ? comanda.custom['numeroCustom'] as int
              : null;

      final deviceJson = fixture['device'];
      final deviceBase = deviceJson is Map
          ? Device.fromJson(Map<String, dynamic>.from(deviceJson))
          : null;
      final deviceCompacto = deviceJson is Map
          ? Device.fromJson({
              ...Map<String, dynamic>.from(deviceJson),
              'config': {
                ..._config(deviceJson['config']),
                'facturaCompacto': true,
              },
            })
          : null;

      final escenarios = <String, Future<List<IziPrintItem>> Function()>{
        'solo_orden_$pais': () => PrintTemplate.order80(orderNumber,
            customOrderNumber, contribuyente, sucursal, paymentObj, currency,
            taxesStrategy: taxes),
        'lote_orden_factura_$pais': () => _printRollo(
              contribuyente: contribuyente,
              sucursal: sucursal,
              device: deviceBase,
              invoice: invoice,
              paymentObj: paymentObj,
              currency: currency,
              taxes: taxes,
              orderNumber: orderNumber,
              customOrderNumber: customOrderNumber,
            ),
        'lote_orden_facturacompacta_$pais': () => _printRollo(
              contribuyente: contribuyente,
              sucursal: sucursalCompacta,
              device: deviceBase,
              invoice: invoice,
              paymentObj: paymentObj,
              currency: currency,
              taxes: taxes,
              orderNumber: orderNumber,
              customOrderNumber: customOrderNumber,
            ),
        'lote_compacto_$pais': () => _printRollo(
              contribuyente: contribuyente,
              sucursal: sucursal,
              device: deviceCompacto,
              invoice: invoice,
              paymentObj: paymentObj,
              currency: currency,
              taxes: taxes,
              orderNumber: orderNumber,
              customOrderNumber: customOrderNumber,
            ),
      };

      for (final escenario in escenarios.entries) {
        final items = await escenario.value();
        final bytes = await PrintUtils().buildPdfBytes(items);
        final archivo = File('$_salida/kiosco_${escenario.key}.pdf');
        archivo.writeAsBytesSync(bytes);
        // ignore: avoid_print
        print('${archivo.path}  (${items.length} items, ${bytes.length} bytes)');
      }
    });
  }
}

Map<String, dynamic> _config(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String) {
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {}
  }
  return {};
}

Currency? _monedaPrincipal(
    Map<String, dynamic> fixture, Contribuyente contribuyente) {
  final monedas = (fixture['monedas'] as List? ?? [])
      .map((e) => Currency.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  final buscada = contribuyente.config?['monedaInventario'];
  for (final moneda in monedas) {
    if (moneda.id == buscada) return moneda;
  }
  return null;
}

/// Reproduce la decision de PaymentBloc._printRollo con backendTicket ausente,
/// que es el lote que la impresora recibe de verdad.
Future<List<IziPrintItem>> _printRollo({
  required Contribuyente contribuyente,
  required Sucursal sucursal,
  required Device? device,
  required Invoice invoice,
  required PaymentObj paymentObj,
  required Currency? currency,
  required TaxesStrategy taxes,
  required int orderNumber,
  required int? customOrderNumber,
}) async {
  List<IziPrintItem> tmp = await PrintTemplate.order80(orderNumber,
      customOrderNumber, contribuyente, sucursal, paymentObj, currency,
      taxesStrategy: taxes);

  final useCompact = device?.config.facturaCompacto == true;

  if (useCompact) {
    tmp = await PrintTemplate.printInvoiceCompact(
        contribuyente, sucursal, invoice,
        orderNumber: orderNumber,
        customOrderNumber: customOrderNumber,
        taxesStrategy: taxes);
  } else {
    tmp.add(IziPrintLineWrap(lines: 2));
    tmp.add(IziPrintCut());
    if (sucursal.config is Map &&
        (sucursal.config as Map)['tipoFacturaVentas'] == 'compacto') {
      tmp.addAll(await PrintTemplate.printInvoiceCompact(
          contribuyente, sucursal, invoice,
          taxesStrategy: taxes));
    } else {
      tmp.addAll(await PrintTemplate.printInvoice(
          contribuyente, sucursal, invoice,
          taxesStrategy: taxes));
    }
  }
  return tmp;
}
