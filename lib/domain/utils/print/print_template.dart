import 'dart:math';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/utils/date_formatter.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';

class PrintTemplate {
  static Future<List<IziPrintItem>> invoice80(
      Invoice invoice, Contribuyente contribuyente, Sucursal sucursal) async {
    List<IziPrintItem> items = [];
    Map? configSiat = contribuyente.customData is Map &&
            invoice.customFactura is Map &&
            invoice.customFactura["siat"] is Map &&
            contribuyente.customData["configSiat"] is Map
        ? contribuyente.customData["configSiat"]
        : null;
    Map? datosSiat =
        invoice.customFactura is Map ? invoice.customFactura["siat"] : null;
    List listCE = invoice.customFactura is Map &&
            invoice.customFactura["camposExtra"] is List
        ? invoice.customFactura["camposExtra"]
        : [];
    Uint8List? image;
    bool isPng(List<int> bytes) {
      Uint8List pngSignature = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
      return const ListEquality().equals(bytes.take(8).toList(), pngSignature);
    }
    try{
      var res = await Dio().get("${dotenv.env[EnvKeys.apiUrl]}/contribuyentes/${invoice.contribuyente}/logo",
          options: Options(responseType: ResponseType.bytes),);
      if (res.statusCode == 200 && res.data is List<int> && !isPng(res.data)) {
        image = Uint8List.fromList(res.data);
      }
    }
    catch(_){}
    if(image!=null && image.isNotEmpty){
      items.add(IziPrintImage(image,size: 70));
      items.add(IziPrintLineWrap(lines: 4));
    }
    items.add(IziPrintText(
        text: invoice.razonSocialEmisor ?? "",
        size: IziPrintSize.md,
        align: IziPrintAlign.center,
        bold: true));
    items.add(IziPrintText(
        text: sucursal.nombre ?? "",
        size: IziPrintSize.sm,
        align: IziPrintAlign.center,
        bold: true));
    if (
        sucursal.config is Map &&
        sucursal.config["siat"] is Map) {
      items.add(IziPrintText(
          text: "No. Punto de Venta ${sucursal.config["siat"]["puntoVenta"]}",
          size: IziPrintSize.sm,
          align: IziPrintAlign.center));
    }
    items.add(IziPrintText(
        text: "ZONA: ${sucursal.zona}",
        size: IziPrintSize.sm,
        align: IziPrintAlign.center));
    items.add(IziPrintText(
        text: "${sucursal.direccion}",
        size: IziPrintSize.sm,
        align: IziPrintAlign.center));
    items.add(IziPrintText(
        text: "TELF: ${sucursal.telf}",
        size: IziPrintSize.sm,
        align: IziPrintAlign.center));
    items.add(IziPrintText(
        text: "${sucursal.ciudad}, Bolivia",
        size: IziPrintSize.sm,
        align: IziPrintAlign.center));

    items.add(IziPrintLineWrap(lines: 3));
    if (invoice.isPruebas == true) {
      items.add(IziPrintText(
          text: "FACTURA DE PRUEBA, NO VÁLIDA PARA CRÉDITO FISCAL",
          size: IziPrintSize.xl,
          align: IziPrintAlign.center));
    } else {
      var titleInvoice = 'FACTURA ORIGINAL';
      if (configSiat != null) {
        titleInvoice = 'FACTURA';
      }

      var typeFact = invoice.prefactura == 1
          ? (sucursal.config is Map
              ? "${sucursal.config["nombrePreFactura"] ?? "Pre-Factura"}: ${invoice.numeroPrefactura}"
              : "Pre-Factura")
          : titleInvoice;

      items.add(IziPrintText(
          text: typeFact, size: IziPrintSize.xl, align: IziPrintAlign.center));
    }
    if (invoice.prefactura != 1) {
      items.add(IziPrintText(
          text: "Con derecho a crédito fiscal",
          size: IziPrintSize.sm,
          align: IziPrintAlign.center));

      var autorizacionLabel = "AUTORIZACIÓN No:";
      var nAutorizacion = invoice.autorizacion;
      if (configSiat != null) {
        autorizacionLabel = "CÓD. AUTORIZACIÓN: ";
        nAutorizacion = datosSiat?["cuf"];
      }

      items.add(IziPrintText(
          text: "NIT EMISOR: ${invoice.emisor}",
          size: IziPrintSize.sm,
          align: IziPrintAlign.center));

      items.add(IziPrintText(
          text:
              "FACTURA No: ${(invoice.numero ?? 0).toString().padLeft(5, '0')}",
          size: IziPrintSize.sm,
          align: IziPrintAlign.center));

      items.add(IziPrintText(
          text: "$autorizacionLabel $nAutorizacion",
          size: IziPrintSize.sm,
          align: IziPrintAlign.center));
      items.add(IziPrintSeparator());
      if (configSiat == null) {
        items.add(IziPrintText(
            text: "ACTIVIDAD ECONÓMICA",
            size: IziPrintSize.sm,
            align: IziPrintAlign.center));
        items.add(IziPrintText(
            text: "${invoice.actividadEconomica}",
            size: IziPrintSize.sm,
            align: IziPrintAlign.center));
        items.add(IziPrintSeparator());
      }
      String labelDocIdentidad;
      if (invoice.prefactura == 1) {
        items.add(IziPrintText(
            text: "NOMBRE: ${invoice.razonSocial}",
            size: IziPrintSize.sm,
            align: IziPrintAlign.center,bold: true));
        labelDocIdentidad = 'CODIGO: ';
      } else {
        items.add(IziPrintText(
            text: "NOMBRE/RAZÓN SOCIAL: ${invoice.razonSocial}",
            size: IziPrintSize.sm,
            align: IziPrintAlign.center,bold: true));
        labelDocIdentidad = 'NIT/CI/CEX: ';
      }
      var esCi = true;
      var complemento = esCi &&
              invoice.customFactura is Map &&
              invoice.customFactura["complemento"] != null
          ? " - ${invoice.customFactura["complemento"]}"
          : '';

      items.add(IziPrintText(
          text: "$labelDocIdentidad ${invoice.comprador}$complemento",
          size: IziPrintSize.sm,
          align: IziPrintAlign.center,bold: true));

      String codCliente = (datosSiat != null &&
              invoice.prefactura != 1 &&
              datosSiat["factura"] is Map &&
              datosSiat["factura"]["cabecera"] is Map &&
              datosSiat["factura"]["cabecera"]["codigoCliente"] != null
          ? datosSiat["factura"]["cabecera"]["codigoCliente"].toString()
          : (invoice.clienteId ?? invoice.comprador ?? '').toString());
      items.add(IziPrintText(
          text: "COD. CLIENTE: $codCliente",
          size: IziPrintSize.sm,
          align: IziPrintAlign.center,bold: true));
      items.add(IziPrintText(
          text:
              "FECHA: ${DateTime.parse(invoice.fecha).dateFormat(DateFormatterType.dateHour)}",
          size: IziPrintSize.sm,
          align: IziPrintAlign.center,bold: true));

      if (listCE.isNotEmpty) {
        items.add(IziPrintSeparator());
        for (var ce in listCE) {
          if (ce['visibleFactura'] == true) {
            items.add(IziPrintText(
                text: "${ce["titulo"]}: ${ce["valor"]}",
                size: IziPrintSize.sm,
                align: IziPrintAlign.center));
          }
        }
      }
      items.add(IziPrintSeparator());

      items.add(IziPrintRow([
        IziPrintColumn(text: "Cant.", width: 10, align: IziPrintAlign.left),
        IziPrintColumn(text: "Detalle", width: 30, align: IziPrintAlign.left),
        IziPrintColumn(text: "Precio U.", width: 20, align: IziPrintAlign.right),
        IziPrintColumn(text: "Desc U", width: 20, align: IziPrintAlign.right),
        IziPrintColumn(text: "Subtotal", width: 20, align: IziPrintAlign.right),
      ], size: IziPrintSize.sm,bold: true));
      items.add(IziPrintSeparator());

      for (Items item in invoice.listaItems??[]) {

        num precioUnitario = (invoice.prefactura == 1 ? item.precioUnitario : item.precioUnitarioImpuesto) ?? 0;
        num descuento = (invoice.prefactura == 1  ? item.descuento : item.descuentoImpuesto) ??0;
        num  precioTotal = (invoice.prefactura == 1  ? item.precioTotal : item.precioTotalImpuesto) ?? 0;
        var codInve = (item.codigoInventario == null && item.codigo == null) ? ' ' : '${item.codigoInventario ?? item.codigo??"000"}-';

        if(invoice.prefactura == 1 && sucursal.config is Map && sucursal.config["noMostrarCodigoInventarioPrefactura"]){
          codInve = "";
        }
        items.add(IziPrintRow([
          IziPrintColumn(text: item.cantidad.toString(), width:10, align: IziPrintAlign.left),
          IziPrintColumn(text: codInve + item.articulo, width: 30, align: IziPrintAlign.left),
          IziPrintColumn(text: precioUnitario.toStringAsFixed(2), width: 20, align: IziPrintAlign.right),
          IziPrintColumn(text: descuento.toStringAsFixed(2), width: 20, align: IziPrintAlign.right),
          IziPrintColumn(text: precioTotal.toStringAsFixed(2), width: 20, align: IziPrintAlign.right),
        ], size: IziPrintSize.sm,bold: true));
        items.add(IziPrintLineWrap(lines: 1));
      }

      var monto = _roundNumber(invoice.prefactura == 1 ? invoice.monto ?? 0 : (invoice.montoImpuesto ?? invoice.monto ?? 0),2);
      //var sincredito = _roundNumber(invoice.prefactura ==1? invoice.sincredito ?? 0 : invoice.sincreditoImpuesto??0,2);
      var descuento = _roundNumber(invoice.prefactura ==1? invoice.descuentos ?? 0 : (invoice.descuentosImpuesto ?? invoice.descuentos ?? 0),2);
      var total = _roundNumber(invoice.prefactura ==1? (invoice.monto ??0) - (invoice.descuentos ?? 0) : (invoice.montoImpuesto!=null && invoice.descuentosImpuesto!=null?(invoice.montoImpuesto ?? 0) - (invoice.descuentosImpuesto??0) : ((invoice.monto??0)) - (invoice.descuentos??0)),2);
      var giftCards = _roundNumber(invoice.prefactura ==1? (invoice.giftCards ?? 0) : (invoice.giftCardsImpuesto ?? invoice.giftCards ?? 0),2);
      var importeBase = _roundNumber(invoice.prefactura ==1 ? (invoice.montoTotal??0) - (invoice.giftCards ??0): (invoice.montoTotalImpuesto!=null && invoice.giftCardsImpuesto!=null?(invoice.montoTotalImpuesto??0) - (invoice.giftCardsImpuesto??0):(invoice.montoTotal??0) - (invoice.giftCards??0)),2);
      var esUnMil = (invoice.prefactura ==1? (invoice.monto ??0) - (invoice.giftCards ?? 0): (invoice.montoImpuesto!=null && invoice.giftCardsImpuesto!=null?invoice.montoImpuesto! - invoice.giftCardsImpuesto! : (invoice.monto ?? 0) - (invoice.giftCards??0))) ~/ 1000 == 1;
      num auxCents = ((invoice.prefactura ==1? invoice.montoTotal ??0 : (invoice.montoTotalImpuesto ?? invoice.montoTotal ?? 0)) - ((invoice.prefactura == 1 ? invoice.montoTotal ?? 0 : (invoice.montoTotalImpuesto ?? invoice.montoTotal ?? 0))).toInt());
      var totalCentavos = (auxCents*100).round().toInt();
      //var totalCentavosStr = totalCentavos.toString().padLeft(2,'0');
      num auxWritten= (invoice.prefactura ==1? (invoice.montoTotal??0) - (invoice.giftCards??0) : (invoice.montoTotalImpuesto!=null && invoice.giftCardsImpuesto!=null?invoice.montoTotalImpuesto! - invoice.giftCardsImpuesto! : (invoice.montoTotal??0) - (invoice.giftCards??0)));

      var writtenTotal = (esUnMil ? "un " : "") + _formatNumberToWord(auxWritten.toInt());
      items.add(IziPrintSeparator(dotted: true));

      items.add(IziPrintRow([
        IziPrintColumn(text: "SUBTOTAL", width: 70, align: IziPrintAlign.right),
        IziPrintColumn(text: monto.toStringAsFixed(2), width: 30, align: IziPrintAlign.right),
      ], size: IziPrintSize.sm,bold: true));
      items.add(IziPrintRow([
        IziPrintColumn(text: "DESCUENTO", width: 70, align: IziPrintAlign.right),
        IziPrintColumn(text: descuento.toStringAsFixed(2), width: 30, align: IziPrintAlign.right),
      ], size: IziPrintSize.sm,bold: true));
      items.add(IziPrintRow([
        IziPrintColumn(text: "TOTAL", width: 70, align: IziPrintAlign.right),
        IziPrintColumn(text: total.toStringAsFixed(2), width: 30, align: IziPrintAlign.right),
      ], size: IziPrintSize.sm,bold: true));
      items.add(IziPrintRow([
        IziPrintColumn(text: "MONTO GIFT-CARD", width: 70, align: IziPrintAlign.right),
        IziPrintColumn(text: giftCards.toStringAsFixed(2), width: 30, align: IziPrintAlign.right),
      ], size: IziPrintSize.sm,bold: true));
      items.add(IziPrintRow([
        IziPrintColumn(text: "IMPORTE BASE DE CREDITO FISCAL", width: 70, align: IziPrintAlign.right),
        IziPrintColumn(text: importeBase.toStringAsFixed(2), width: 30, align: IziPrintAlign.right),
      ], size: IziPrintSize.sm,bold: true));
      items.add(IziPrintRow([
        IziPrintColumn(text: "TOTAL A PAGAR", width: 70, align: IziPrintAlign.right),
        IziPrintColumn(text: importeBase.toStringAsFixed(2), width: 30, align: IziPrintAlign.right),
      ], size: IziPrintSize.sm,bold: true));
      items.add(IziPrintSeparator(dotted: true));

      items.add(IziPrintText(
          text: 'SON:  ${(writtenTotal).capitalize()} $totalCentavos/100 Bolivianos',
          size: IziPrintSize.sm,
          align: IziPrintAlign.left));
      items.add(IziPrintSeparator());
      dynamic aut;
      if (invoice.prefactura!=1) {

        if (configSiat==null) {
          items.add(IziPrintLineWrap(lines: 3));
          items.add(IziPrintText(
              text: "Código de Control: ${invoice.control}" ,
              size: IziPrintSize.sm,
              align: IziPrintAlign.center));
          items.add(IziPrintText(
              text: "Código de Control: ${invoice.control}" ,
              size: IziPrintSize.sm,
              align: IziPrintAlign.center));
          if(contribuyente.autorizaciones is List && invoice.autorizacion!=null){
            aut=(contribuyente.autorizaciones as List).firstWhereOrNull((element) => element["autorizacion"]==invoice.autorizacion);
            if(aut is Map && aut["limiteEmision"] is String){
              items.add(IziPrintText(
                  text: "Fecha límite de Emisión: ${DateTime.tryParse(aut["limiteEmision"])?.dateFormat(DateFormatterType.visual)}" ,
                  size: IziPrintSize.sm,
                  align: IziPrintAlign.center));
            }
          }
        }
        if (invoice.prefactura!=1) {

          var nit = invoice.emisor;
          var cuf = invoice.customFactura is Map && invoice.customFactura["siat"] is Map?invoice.customFactura["siat"]["cuf"]:null;
          var number = invoice.numero;
          String siatQRUrl;
          if (contribuyente.customData is Map && contribuyente.customData["configSiat"] is Map && contribuyente.customData["configSiat"]["codigoAmbiente"] == 1) {
            siatQRUrl ="https://siat.impuestos.gob.bo/consulta/QR?nit=$nit&cuf=$cuf&numero=$number&t=2";
          } else {
            siatQRUrl ="https://pilotosiat.impuestos.gob.bo/consulta/QR?nit=$nit&cuf=$cuf&numero=$number&t=2";
          }
          items.add(IziPrintQR(siatQRUrl,size:3));
          items.add(IziPrintLineWrap(lines: 1));

          final leyendaLey = (configSiat==null) ? aut is Map? aut["leyenda"]:"": datosSiat?["leyenda"]??"";

          var ley = 'ESTA FACTURA CONTRIBUYE AL DESARROLLO DEL PAÍS, EL USO ILÍCITO DE ÉSTA SERÁ SANCIONADO PENALMENTE DE ACUERDO A LEY';

          items.add(IziPrintText(
              text: ley,
              size: IziPrintSize.sm,
              align: IziPrintAlign.center));
          items.add(IziPrintLineWrap(lines: 1));

          items.add(IziPrintText(
              text: leyendaLey ,
              size: IziPrintSize.sm,
              align: IziPrintAlign.center));

          if (configSiat!=null) {
            var mensajeFacturaSiat = datosSiat?["codigoDescripcion"] == 'CONTINGENCIA' ? '"Este documento es la Representaci\u00F3n Gr\u00E1fica de un Documento Fiscal Digital emitido fuera de l\u00EDnea, verifique su env\u00EDo con su proveedor o en la p\u00E1gina web www.impuestos.gob.bo"' : '“Este documento es la Representaci\u00F3n Gr\u00E1fica de un Documento Fiscal Digital emitido en una modalidad de facturaci\u00F3n en l\u00EDnea”';

            items.add(IziPrintLineWrap(lines: 1));
            items.add(IziPrintText(
                text: mensajeFacturaSiat ,
                size: IziPrintSize.sm,
                align: IziPrintAlign.center));
          }
        }
      }
      items.add(IziPrintSeparator());
      items.add(IziPrintText(
          text: "Generada a través de iZi",
          size: IziPrintSize.sm,
          bold: true,
          align: IziPrintAlign.center));


    }
    return items;
  }
 static final _wordMap = {
   0: 'cero',
   1: 'uno',
   2: 'dos',
   3: 'tres',
   4: 'cuatro',
   5: 'cinco',
   6: 'seis',
   7: 'siete',
   8: 'ocho',
   9: 'nueve',
   10: 'diez',
   11: 'once',
   12: 'doce',
   13: 'trece',
   14: 'catorce',
   15: 'quince',
   16: 'dieciséis',
   17: 'diecisiete',
   18: 'dieciocho',
   19: 'diecinueve',
   20: 'veinte',
   21: 'veintiuno',
   22: 'veintidós',
   23: 'veintitres',
   24: 'veinticuatro',
   25: 'veinticinco',
   26: 'veintiseis',
   27: 'veintisiete',
   28: 'veintiocho',
   29: 'veintinueve',
   30: 'treinta',
   40: 'cuarenta',
   50: 'cincuenta',
   60: 'sesenta',
   70: 'setenta',
   80: 'ochenta',
   90: 'noventa',
   100: 'cien',
   200: 'doscientos',
   300: 'trescientos',
   400: 'cuatrocientos',
   500: 'quinientos',
   600: 'seiscientos',
   700: 'setecientos',
   800: 'ochocientos',
   900: 'novecientos',
 };
  static num _roundNumber(num number, int decimalPlaces) {
    num factor = pow(10.0, decimalPlaces);
    return (number * factor).roundToDouble() / factor;
  }
  static String _formatNumberToWord(int value){

    if (value >= 100000) {
      return value.toString();
    }
    if (value < 0) {
      throw UnimplementedError('Values below 0 are not supported');
    }
    if (value == 1) {
      // special case for one
      return 'un';
    }
    List<String> result = [];
    final teens = value % 100;
    if (teens <= 29) {
      if (value <= 15 || teens != 0) {
        result.add(_wordMap[teens]!);
      }
    } else {
      final ones = value % 10;
      if (ones > 0) {
        result.add(_wordMap[ones]!);
        result.add('y');
      }
      final tens = (teens ~/ 10) * 10;
      result.add(_wordMap[tens]!);
    }

    final hundreds = value ~/ 100 % 10;
    final thousands = value ~/ 1000 % 10;
    if (hundreds > 0) {
      if (teens == 0 && hundreds == 1) {
        result.add('cien');
      } else {
        if (hundreds != 1) {
          result.add(_wordMap[hundreds*100]!);
        }
        else{
          result.add('ciento');
        }
      }
    }

    if (thousands > 0) {
      result.add('mil');
      if (thousands > 1) {
        result.add(_wordMap[thousands]!);
      }
    }

    return result.reversed.join(' ');
  }

}
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}