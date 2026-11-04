import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy_factory.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Contribuyente contribuyenteBo;
  late Contribuyente contribuyenteCo;
  late Invoice invoiceBo;
  late Invoice invoiceCo;
  late Map<String, dynamic> invoiceRawBo;
  late Map<String, dynamic> sucursalRawBo;
  late Map<String, dynamic> sucursalRawCo;

  setUpAll(() async {
    await dotenv.load(fileName: 'assets/.env.stg');

    final fixtureBo =
        jsonDecode(File('test/print/fixtures/bo.json').readAsStringSync())
            as Map<String, dynamic>;
    contribuyenteBo = Contribuyente.fromJson(
        Map<String, dynamic>.from(fixtureBo['contribuyente'] as Map));
    invoiceRawBo = Map<String, dynamic>.from(fixtureBo['facturaEmitida'] as Map);
    invoiceBo = Invoice.fromJson(invoiceRawBo);
    sucursalRawBo = Map<String, dynamic>.from(fixtureBo['sucursal'] as Map);

    final fixtureCo =
        jsonDecode(File('test/print/fixtures/co.json').readAsStringSync())
            as Map<String, dynamic>;
    contribuyenteCo = Contribuyente.fromJson(
        Map<String, dynamic>.from(fixtureCo['contribuyente'] as Map));
    invoiceCo = Invoice.fromJson(
        Map<String, dynamic>.from(fixtureCo['facturaEmitida'] as Map));
    sucursalRawCo = Map<String, dynamic>.from(fixtureCo['sucursal'] as Map);
  });

  group('Sucursal.ordenEnFactura', () {
    test('evalúa true con diferentes valores verdaderos en config', () {
      final sucTrue = Sucursal.fromJson({
        'config': {'ordenEnFactura': true}
      });
      final sucNum = Sucursal.fromJson({
        'config': {'ordenEnFactura': 1}
      });
      final sucStr = Sucursal.fromJson({
        'config': {'ordenEnFactura': 'true'}
      });

      expect(sucTrue.ordenEnFactura, isTrue);
      expect(sucNum.ordenEnFactura, isTrue);
      expect(sucStr.ordenEnFactura, isTrue);
    });

    test('evalúa true cuando config viene serializado como string JSON', () {
      final sucJsonStr = Sucursal.fromJson({
        'config': '{"ordenEnFactura": true}'
      });
      expect(sucJsonStr.ordenEnFactura, isTrue);
    });

    test('evalúa false cuando ordenEnFactura está deshabilitado o ausente', () {
      final sucFalse = Sucursal.fromJson({
        'config': {'ordenEnFactura': false}
      });
      final sucZero = Sucursal.fromJson({
        'config': {'ordenEnFactura': 0}
      });
      final sucNull = Sucursal.fromJson({
        'config': {'ordenEnFactura': null}
      });
      final sucEmpty = Sucursal.fromJson({'config': {}});
      final sucNoConfig = Sucursal.fromJson({});

      expect(sucFalse.ordenEnFactura, isFalse);
      expect(sucZero.ordenEnFactura, isFalse);
      expect(sucNull.ordenEnFactura, isFalse);
      expect(sucEmpty.ordenEnFactura, isFalse);
      expect(sucNoConfig.ordenEnFactura, isFalse);

      expect(sucFalse.ordenEnFacturaConfig, isFalse);
      expect(sucZero.ordenEnFacturaConfig, isFalse);
      expect(sucNull.ordenEnFacturaConfig, isNull);
      expect(sucEmpty.ordenEnFacturaConfig, isNull);
      expect(sucNoConfig.ordenEnFacturaConfig, isNull);
    });
  });

  group('Comportamiento por defecto cuando ordenEnFactura no está en config', () {
    test('Formato compacto con orderNumber explícito incluye número de orden por retrocompatibilidad', () async {
      final sucursalSinFlag = Sucursal.fromJson({
        ...sucursalRawBo,
        'config': {},
      });

      final items = await PrintTemplate.printInvoiceCompact(
        contribuyenteBo,
        sucursalSinFlag,
        invoiceBo,
        orderNumber: 88,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteBo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos, contains('Orden #88'));
    });

    test('Formato standard 80 sin flag no incluye número de orden (consistente con restaurantes)', () async {
      final sucursalSinFlag = Sucursal.fromJson({
        ...sucursalRawBo,
        'config': {},
      });

      final items = await PrintTemplate.printInvoice(
        contribuyenteBo,
        sucursalSinFlag,
        invoiceBo,
        orderNumber: 88,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteBo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos.where((t) => t.contains('Orden: 88')), isEmpty);
    });
  });

  group('PrintTemplate.resolveInvoiceOrder helper unificado', () {
    test('parsea número y customOrderNumber cuando llegan como String o num', () {
      final sucursal = Sucursal.fromJson({'config': {'ordenEnFactura': true}});
      final invoice = Invoice.fromJson({
        ...invoiceRawBo,
        'customFactura': {
          'comanda': {'numero': '55', 'numeroCustom': 12.0}
        }
      });

      final info = PrintTemplate.resolveInvoiceOrder(
        sucursal: sucursal,
        invoice: invoice,
      );

      expect(info.orderNumber, equals(55));
      expect(info.customOrderNumber, equals(12));
      expect(info.showOrder, isTrue);
      expect(info.shouldPrint, isTrue);
      expect(info.orderTextFull, equals('Orden: 12'));
      expect(info.orderTextCompact, equals('Orden #12'));
    });

    test('patrón exacto no confunde productos con orden', () {
      final pattern = RegExp(r'^orden\s*[#:]\s*\S+$', caseSensitive: false);
      expect(pattern.hasMatch('Orden: 12'), isTrue);
      expect(pattern.hasMatch('ORDEN #42'), isTrue);
      expect(pattern.hasMatch('Orden: A-1'), isTrue);

      expect(pattern.hasMatch('Ordenador'), isFalse);
      expect(pattern.hasMatch('Orden de compra: 123'), isFalse);
      expect(pattern.hasMatch('Ordenanza municipal'), isFalse);
    });
  });

  group('CU-04: Generar factura con número de orden (ordenEnFactura: true)', () {
    test('BO - Formato compacto incluye número de orden', () async {
      final sucursal = Sucursal.fromJson({
        ...sucursalRawBo,
        'config': {
          ...Map<String, dynamic>.from(sucursalRawBo['config'] as Map? ?? {}),
          'ordenEnFactura': true,
        },
      });

      final items = await PrintTemplate.printInvoiceCompact(
        contribuyenteBo,
        sucursal,
        invoiceBo,
        orderNumber: 105,
        customOrderNumber: 42,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteBo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos, contains('Orden #42'));

      final pdfBytes = await PrintUtils().buildPdfBytes(items);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('BO - Formato standard 80 incluye "Orden: <numero>" consistente con restaurantes', () async {
      final sucursal = Sucursal.fromJson({
        ...sucursalRawBo,
        'config': {
          ...Map<String, dynamic>.from(sucursalRawBo['config'] as Map? ?? {}),
          'ordenEnFactura': true,
        },
      });

      final items = await PrintTemplate.printInvoice(
        contribuyenteBo,
        sucursal,
        invoiceBo,
        orderNumber: 105,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteBo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos, contains('Orden: 105'));

      final pdfBytes = await PrintUtils().buildPdfBytes(items);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('CO - Formato compacto incluye número de orden', () async {
      final sucursal = Sucursal.fromJson({
        ...sucursalRawCo,
        'config': {
          ...Map<String, dynamic>.from(sucursalRawCo['config'] as Map? ?? {}),
          'ordenEnFactura': true,
        },
      });

      final items = await PrintTemplate.printInvoiceCompact(
        contribuyenteCo,
        sucursal,
        invoiceCo,
        orderNumber: 263,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteCo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos, contains('Orden #263'));

      final pdfBytes = await PrintUtils().buildPdfBytes(items);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('CO - Formato standard 80 incluye "Orden: <numero>" consistente con restaurantes', () async {
      final sucursal = Sucursal.fromJson({
        ...sucursalRawCo,
        'config': {
          ...Map<String, dynamic>.from(sucursalRawCo['config'] as Map? ?? {}),
          'ordenEnFactura': true,
        },
      });

      final items = await PrintTemplate.printInvoice(
        contribuyenteCo,
        sucursal,
        invoiceCo,
        orderNumber: 263,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteCo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos, contains('Orden: 263'));

      final pdfBytes = await PrintUtils().buildPdfBytes(items);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('Resuelve número de orden desde invoice.customFactura["comanda"] si no se pasa explícito', () async {
      final sucursal = Sucursal.fromJson({
        ...sucursalRawBo,
        'config': {
          ...Map<String, dynamic>.from(sucursalRawBo['config'] as Map? ?? {}),
          'ordenEnFactura': true,
        },
      });

      final invoiceConComanda = Invoice.fromJson({
        ...invoiceRawBo,
        'customFactura': {
          ...invoiceBo.customFactura,
          'comanda': {'id': 99, 'numero': 777},
        },
      });

      final items = await PrintTemplate.printInvoice(
        contribuyenteBo,
        sucursal,
        invoiceConComanda,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteBo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos, contains('Orden: 777'));
    });
  });

  group('CU-05: Generar factura sin número de orden (ordenEnFactura: false)', () {
    test('BO - Formato compacto no incluye número de orden', () async {
      final sucursal = Sucursal.fromJson({
        ...sucursalRawBo,
        'config': {
          ...Map<String, dynamic>.from(sucursalRawBo['config'] as Map? ?? {}),
          'ordenEnFactura': false,
        },
      });

      final items = await PrintTemplate.printInvoiceCompact(
        contribuyenteBo,
        sucursal,
        invoiceBo,
        orderNumber: 105,
        customOrderNumber: 42,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteBo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos.where((t) => t.contains('Orden')), isEmpty);

      final pdfBytes = await PrintUtils().buildPdfBytes(items);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('BO - Formato standard 80 no incluye número de orden', () async {
      final sucursal = Sucursal.fromJson({
        ...sucursalRawBo,
        'config': {
          ...Map<String, dynamic>.from(sucursalRawBo['config'] as Map? ?? {}),
          'ordenEnFactura': false,
        },
      });

      final items = await PrintTemplate.printInvoice(
        contribuyenteBo,
        sucursal,
        invoiceBo,
        orderNumber: 105,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteBo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos.where((t) => t.contains('Orden')), isEmpty);

      final pdfBytes = await PrintUtils().buildPdfBytes(items);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('CO - Formato compacto no incluye número de orden', () async {
      final sucursal = Sucursal.fromJson({
        ...sucursalRawCo,
        'config': {
          ...Map<String, dynamic>.from(sucursalRawCo['config'] as Map? ?? {}),
          'ordenEnFactura': false,
        },
      });

      final items = await PrintTemplate.printInvoiceCompact(
        contribuyenteCo,
        sucursal,
        invoiceCo,
        orderNumber: 263,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteCo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos.where((t) => t.contains('Orden')), isEmpty);

      final pdfBytes = await PrintUtils().buildPdfBytes(items);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('CO - Formato standard 80 no incluye número de orden', () async {
      final sucursal = Sucursal.fromJson({
        ...sucursalRawCo,
        'config': {
          ...Map<String, dynamic>.from(sucursalRawCo['config'] as Map? ?? {}),
          'ordenEnFactura': false,
        },
      });

      final items = await PrintTemplate.printInvoice(
        contribuyenteCo,
        sucursal,
        invoiceCo,
        orderNumber: 263,
        taxesStrategy: TaxesStrategyFactory.taxes(contribuyenteCo),
      );

      final textos = items.whereType<IziPrintText>().map((e) => e.text).toList();
      expect(textos.where((t) => t.contains('Orden')), isEmpty);

      final pdfBytes = await PrintUtils().buildPdfBytes(items);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
