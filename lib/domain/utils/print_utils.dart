import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:printing/printing.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import 'package:image/image.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class IziPrintText extends IziPrintItem {
  String text;
  IziPrintSize size;
  bool bold;
  IziPrintAlign align;

  IziPrintText(
      {required this.text,
      required this.size,
      this.bold = false,
      this.align = IziPrintAlign.left});
}

class IziPrintImage extends IziPrintItem {
  Uint8List image;
  IziPrintAlign align;
  int size;
  IziPrintImage(this.image,
      {this.align = IziPrintAlign.center, required this.size});
}

class IziPrintQR extends IziPrintItem {
  String qrContent;
  int size;
  IziPrintAlign align;
  IziPrintQR(this.qrContent,
      {required this.size, this.align = IziPrintAlign.center});
}

class IziPrintColumn {
  String text;
  IziPrintAlign align;
  int width;

  IziPrintColumn(
      {required this.text,
      this.align = IziPrintAlign.left,
      required this.width});
}

enum IziPrintAlign { left, center, right }

enum IziPrintSize { xs, sm, sml, md, lg, xl }

class IziPrintRow extends IziPrintItem {
  List<IziPrintColumn> values;
  bool bold;
  IziPrintSize size;
  IziPrintRow(this.values, {this.bold = false, required this.size});
}

class IziPrintSeparator extends IziPrintItem {
  bool dotted;
  IziPrintSeparator({this.dotted = false});
}

class IziPrintLineWrap extends IziPrintItem {
  int lines;
  IziPrintLineWrap({required this.lines});
}

class IziPrintCut extends IziPrintItem {}

abstract class IziPrintItem {
  static IziPrintAlign _alignFor(dynamic v) {
    switch (v) {
      case 'center':
        return IziPrintAlign.center;
      case 'right':
        return IziPrintAlign.right;
      default:
        return IziPrintAlign.left;
    }
  }

  static IziPrintSize _sizeFor(dynamic v) {
    switch (v) {
      case 'xs':
        return IziPrintSize.xs;
      case 'sml':
        return IziPrintSize.sml;
      case 'md':
        return IziPrintSize.md;
      case 'lg':
        return IziPrintSize.lg;
      case 'xl':
        return IziPrintSize.xl;
      case 'sm':
      default:
        return IziPrintSize.sm;
    }
  }

  static IziPrintItem? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final type = raw['type'];
    switch (type) {
      case 'text':
        return IziPrintText(
            text: raw['text']?.toString() ?? '',
            size: _sizeFor(raw['size']),
            bold: raw['bold'] == true,
            align: _alignFor(raw['align']));
      case 'row':
        final colsRaw = raw['cols'];
        final cols = <IziPrintColumn>[];
        if (colsRaw is List) {
          for (final c in colsRaw) {
            if (c is Map) {
              cols.add(IziPrintColumn(
                  text: c['text']?.toString() ?? '',
                  width: (c['width'] is num) ? (c['width'] as num).toInt() : 0,
                  align: _alignFor(c['align'])));
            }
          }
        }
        return IziPrintRow(cols,
            size: _sizeFor(raw['size']), bold: raw['bold'] == true);
      case 'separator':
        return IziPrintSeparator(dotted: raw['dotted'] == true);
      case 'lineWrap':
        return IziPrintLineWrap(
            lines: raw['lines'] is num ? (raw['lines'] as num).toInt() : 1);
      case 'qr':
        return IziPrintQR(raw['content']?.toString() ?? '',
            size: raw['size'] is num ? (raw['size'] as num).toInt() : 2,
            align: _alignFor(raw['align']));
      case 'image':
        try {
          final bytes = base64Decode(raw['data']?.toString() ?? '');
          return IziPrintImage(bytes,
              size: raw['size'] is num ? (raw['size'] as num).toInt() : 70,
              align: _alignFor(raw['align']));
        } catch (_) {
          return null;
        }
      case 'cut':
        return IziPrintCut();
      default:
        return null;
    }
  }

  static List<IziPrintItem> listFromJson(List<dynamic> raw) {
    final out = <IziPrintItem>[];
    for (final r in raw) {
      final item = fromJson(r);
      if (item != null) out.add(item);
    }
    return out;
  }
}

class PrintUtils {
  printDummy() async {
    if (kIsWeb) {
      await _pdfPrint([
        IziPrintText(
          text: "Bienvenido Kiosko-iZi",
          size: IziPrintSize.md,
          bold: true,
          align: IziPrintAlign.center,
        )
      ]);
    } else {
      if (Platform.isAndroid) {
        var resBinding = await SunmiPrinter.bindingPrinter();
        await SunmiPrinter.initPrinter();
        var status = await SunmiPrinter.getPrinterStatus();
        if (resBinding == true && status != PrinterStatus.ERROR) {
          await SunmiPrinter.initPrinter();
          await SunmiPrinter.startTransactionPrint(true);
          await SunmiPrinter.printText("Bienvenido");
          await SunmiPrinter.submitTransactionPrint();
          await SunmiPrinter.cut();
          await SunmiPrinter.exitTransactionPrint(true);
        } else {
          //await _pdfPrint(values);
        }
      } else {
        //await _pdfPrint(values);
      }
    }
  }
  // Prints a diagnostic ticket through the SAME routing used for real
  // receipts (printSat / printAutoReply flags, SAT auto-detection, Sunmi
  // fallback), so it validates the exact path a sale would take.
  printTest({Device? device}) async {
    final items = <IziPrintItem>[
      IziPrintText(
          text: "Prueba de impresión",
          size: IziPrintSize.lg,
          bold: true,
          align: IziPrintAlign.center),
      IziPrintText(
          text: "Kiosko iZi", size: IziPrintSize.md, align: IziPrintAlign.center),
      IziPrintSeparator(),
      IziPrintText(
          text: "Acentos: áéíóúñÑ ÁÉÍÓÚ ¿¡",
          size: IziPrintSize.sm,
          align: IziPrintAlign.left),
      IziPrintRow([
        IziPrintColumn(text: "Artículo", width: 50),
        IziPrintColumn(text: "Cant.", width: 20, align: IziPrintAlign.center),
        IziPrintColumn(text: "Total", width: 30, align: IziPrintAlign.right),
      ], size: IziPrintSize.sm, bold: true),
      IziPrintRow([
        IziPrintColumn(text: "Café con leche", width: 50),
        IziPrintColumn(text: "2", width: 20, align: IziPrintAlign.center),
        IziPrintColumn(text: "Bs. 30,00", width: 30, align: IziPrintAlign.right),
      ], size: IziPrintSize.sm),
      IziPrintSeparator(dotted: true),
      // URL larga estilo SIAT: valida que los QR de facturas (150+ chars)
      // se impriman correctamente, no solo contenidos cortos.
      IziPrintQR(
          "https://pilotosiat.impuestos.gob.bo/consulta/QR?nit=123456789"
          "&cuf=ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF012345"
          "6789ABCDEF0123456789&numero=12345&t=2",
          size: 3),
      IziPrintLineWrap(lines: 1),
      IziPrintText(
          text: "Impresión OK",
          size: IziPrintSize.md,
          bold: true,
          align: IziPrintAlign.center),
    ];
    await print(items, device);
  }
  static const platform = MethodChannel('com.izisoluciones.kiosco/print');

  // Cached result of native SAT/Masung USB printer detection. The kiosk
  // printer is built in, so one probe per app session is enough.
  static bool? _satPrinterDetected;

  Future<bool> _hasSatPrinter() async {
    if (_satPrinterDetected != null) return _satPrinterDetected!;
    if (kIsWeb || !Platform.isAndroid) return _satPrinterDetected = false;
    try {
      _satPrinterDetected =
          await platform.invokeMethod('hasSatPrinter') == true;
    } catch (e) {
      log("hasSatPrinter probe failed: $e");
      _satPrinterDetected = false;
    }
    return _satPrinterDetected!;
  }

  Future<bool> printFromJson(List<dynamic>? raw, Device? device) async {
    if (raw == null || raw.isEmpty) return false;
    final items = IziPrintItem.listFromJson(raw);
    if (items.isEmpty) return false;
    try {
      await print(items, device);
      return true;
    } catch (e) {
      log("kiosco printFromJson failed: $e");
      return false;
    }
  }

  print(List<IziPrintItem> values, Device? device) async {
    if (kIsWeb) {
      await _pdfPrint(values);
    } else {
      if (Platform.isAndroid) {
        // Routing precedence: explicit backend flags first (printSat,
        // printAutoReply), then hardware auto-detection of the SAT/Masung
        // kiosk printer, and finally the Sunmi built-in printer as default.
        if (device?.config.printSat == true ||
            (device?.config.printAutoReply != true && await _hasSatPrinter())) {
          try {
            log("iZi Kiosco: Routing to _satPrint...");
            await _satPrint(values);
            log("iZi Kiosco: _satPrint finished resolving channel.");
          } catch (e) {
            log("SatPrint failed: $e");
          }
        } else if (device?.config.printAutoReply == true) {
          try {
            await _autoReplyPrint(values);
          } catch (e) {
            log("AutoReplyPrint failed: $e");
          }
        } else {
          var resBinding = await SunmiPrinter.bindingPrinter();
          await SunmiPrinter.initPrinter();
          var status = await SunmiPrinter.getPrinterStatus();
          log(status.toString());
          if (resBinding == true && status != PrinterStatus.ERROR) {
            await _sunmiPrint(values);
          } else {
            //await _pdfPrint(values);
          }
        }
      } else {
        //await _pdfPrint(values);
      }
    }
  }

  _satPrint(List<IziPrintItem> values) async {
    List<Map<String, Object>> items = [];
    for (var i in values) {
      if (i is IziPrintText) {
        items.add({
          'type': 'text',
          'text': i.text,
          'size': i.size.index,
          'bold': i.bold,
          'align': i.align.toString().split('.').last,
        });
      } else if (i is IziPrintRow) {
         items.add({
           'type': 'row',
           'size': i.size.index,
           'bold': i.bold,
           'cols': i.values.map((c) => {
             'text': c.text,
             'width': c.width,
             'align': c.align.toString().split('.').last,
           }).toList(),
         });
      } else if (i is IziPrintQR) {
        items.add({
          'type': 'qrcode',
          'content': i.qrContent,
          'size': i.size,
          'align': i.align.toString().split('.').last,
        });
      } else if (i is IziPrintSeparator) {
        items.add({
          'type': 'line',
          'dotted': i.dotted
        });
      } else if (i is IziPrintLineWrap) {
        items.add({
          'type': 'feed',
          'lines': i.lines
        });
      } else if (i is IziPrintCut) {
        items.add({'type': 'cut'});
      } else if (i is IziPrintImage) {
        items.add({
          'type': 'image',
          'data': i.image,
          'align': i.align.toString().split('.').last,
          'size': i.size
        });
      }
    }
    items.add({'type': 'cut'});
    
    log("iZi Kiosco: Invoking platform channel 'printSat' with ${items.length} items");
    var res = await platform.invokeMethod('printSat', {'items': items});
    log("iZi Kiosco: platform method returned $res");
  }

  _autoReplyPrint(List<IziPrintItem> values) async {
    List<Map<String, Object>> items = [];
    for (var i in values) {
      if (i is IziPrintText) {
        items.add({
          'type': 'text',
          'text': i.text,
          'size': i.size.index,
          'bold': i.bold,
          'align': i.align.toString().split('.').last,
        });
      } else if (i is IziPrintRow) {
         items.add({
           'type': 'row',
           'size': i.size.index,
           'bold': i.bold,
           'cols': i.values.map((c) => {
             'text': c.text,
             'width': c.width,
             'align': c.align.toString().split('.').last,
           }).toList(),
         });
      } else if (i is IziPrintQR) {
        items.add({
          'type': 'qrcode',
          'content': i.qrContent,
          'size': i.size,
          'align': i.align.toString().split('.').last,
        });
      } else if (i is IziPrintSeparator) {
        items.add({
          'type': 'line',
          'dotted': i.dotted
        });
      } else if (i is IziPrintLineWrap) {
        items.add({
          'type': 'feed',
          'lines': i.lines
        });
      } else if (i is IziPrintCut) {
        items.add({'type': 'cut'});
      } else if (i is IziPrintImage) {
        items.add({
          'type': 'image',
          'data': i.image,
          'align': i.align.toString().split('.').last,
          'size': i.size
        });
      }
    }
    items.add({'type': 'cut'});
    
    await platform.invokeMethod('print', {'items': items});
  }

  _sunmiPrint(List<IziPrintItem> values) async {
    const longPaperSm = 62;
    SunmiFontSize selectFontSize(IziPrintSize size) {
      switch (size) {
        case IziPrintSize.xs:
          return SunmiFontSize.XS;
        case IziPrintSize.sm:
          return SunmiFontSize.SM;
        case IziPrintSize.sml:
          return SunmiFontSize.SM;
        case IziPrintSize.md:
          return SunmiFontSize.MD;
        case IziPrintSize.lg:
          return SunmiFontSize.LG;
        case IziPrintSize.xl:
          return SunmiFontSize.XL;
      }
    }

    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    for (var i in values) {
      if (i is IziPrintRow) {
        List<int> porcentajesAValoresSm(List<int> porcentajes) {
          if (porcentajes.reduce((a, b) => a + b) != 100) {
            throw ArgumentError(
                "La suma de los porcentajes debe ser igual a 100");
          }
          List<int> valores =
              porcentajes.map((p) => (p * longPaperSm ~/ 100)).toList();
          int diferencia = longPaperSm - valores.reduce((a, b) => a + b);
          for (int i = 0; i < diferencia; i++) {
            valores[i] += 1;
          }
          return valores;
        }

        await SunmiPrinter.setFontSize(selectFontSize(i.size));
        if (i.bold) {
          await SunmiPrinter.bold();
        }

        if (i.size == IziPrintSize.sm) {
          var valuesT =
              porcentajesAValoresSm(i.values.map((e) => e.width).toList());
          for (var j = 0; j < i.values.length; j++) {
            i.values[j].width = valuesT[j];
          }
        }
        await SunmiPrinter.printRow(
            cols: i.values.map(
          (e) {
            return ColumnMaker(
                width: e.width,
                text: e.text,
                align: e.align == IziPrintAlign.left
                    ? SunmiPrintAlign.LEFT
                    : e.align == IziPrintAlign.right
                        ? SunmiPrintAlign.RIGHT
                        : SunmiPrintAlign.CENTER);
          },
        ).toList());
        await SunmiPrinter.resetFontSize();
        await SunmiPrinter.resetBold();
      } else if (i is IziPrintSeparator) {
        await SunmiPrinter.line(ch: i.dotted ? '-' : '─', len: 48);
      } else if (i is IziPrintText) {
        await SunmiPrinter.printText(i.text,
            style: SunmiStyle(
                align: i.align == IziPrintAlign.left
                    ? SunmiPrintAlign.LEFT
                    : i.align == IziPrintAlign.right
                        ? SunmiPrintAlign.RIGHT
                        : SunmiPrintAlign.CENTER,
                bold: i.bold,
                fontSize: selectFontSize(i.size)));
      } else if (i is IziPrintLineWrap) {
        await SunmiPrinter.lineWrap(i.lines);
      } else if (i is IziPrintCut) {
        await SunmiPrinter.cut();
      } else if (i is IziPrintQR) {
        await SunmiPrinter.setAlignment(i.align == IziPrintAlign.left
            ? SunmiPrintAlign.LEFT
            : i.align == IziPrintAlign.right
                ? SunmiPrintAlign.RIGHT
                : SunmiPrintAlign.CENTER);
        await SunmiPrinter.printQRCode(i.qrContent, size: i.size);
        await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      } /*else if (i is IziPrintImage) {
        final profile = await CapabilityProfile.load();
        final generator =
            Generator(PaperSize.mm80, profile, spaceBetweenRows: 0);
        var dec = decodeImage(i.image);
        int round8(int number) {
          int remainder = number % 8;
          int difference = remainder > 4 ? 8 - remainder : -remainder;
          return number + difference;
        }
        if (dec != null) {
          Image resized = copyResize(dec, width: round8(i.size), height: round8(i.size));
          List<int> bytes = generator.imageRaster(resized,
              align: i.align == IziPrintAlign.left
                  ? PosAlign.left
                  : i.align == IziPrintAlign.right
                      ? PosAlign.right
                      : PosAlign.center);
          await SunmiPrinter.printImage(resized.toUint8List());
          await SunmiPrinter.lineWrap(2);
        }
      }*/
    }
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.cut();
    await SunmiPrinter.exitTransactionPrint(true);
  }

  Future _pdfPrint(List<IziPrintItem> values) async {
    log("pdfPrint");
    const double xs = 6;
    const double sm = 7;
    const double sml = 9;
    const double md = 12;
    const double lg = 14;
    const double xl = 16;
    selectFontSize(IziPrintSize size) {
      switch (size) {
        case IziPrintSize.xs:
          return xs;
        case IziPrintSize.sm:
          return sm;
        case IziPrintSize.sml:
          return sml;
        case IziPrintSize.md:
          return md;
        case IziPrintSize.lg:
          return lg;
        case IziPrintSize.xl:
          return xl;
      }
    }
    final bytesTtf= await rootBundle.load('assets/fonts/Monaco.ttf');
    final pdf = pw.Document(theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: pw.Font.ttf(bytesTtf))));

    List<pw.Widget> items = [];

    for (var i in values) {
      if (i is IziPrintRow) {
        items.add(pw.Row(
            children: i.values.map(
          (e) {
            return pw.Expanded(
                flex: e.width,
                child: pw.Text(e.text,
                    textAlign: e.align == IziPrintAlign.left
                        ? pw.TextAlign.left
                        : e.align == IziPrintAlign.right
                            ? pw.TextAlign.right
                            : pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: selectFontSize(i.size),
                      fontWeight:
                          i.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    )));
          },
        ).toList()));
      } else if (i is IziPrintSeparator) {
        items.add(pw.Divider(borderStyle: i.dotted?pw.BorderStyle.dashed:pw.BorderStyle.solid));
      } else if (i is IziPrintText) {
        items.add(pw.Text(i.text,
            textAlign: i.align == IziPrintAlign.left
                ? pw.TextAlign.left
                : i.align == IziPrintAlign.right
                    ? pw.TextAlign.right
                    : pw.TextAlign.center,
            style: pw.TextStyle(
                fontSize: selectFontSize(i.size),
                fontWeight:
                    i.bold ? pw.FontWeight.bold : pw.FontWeight.normal)));
      } else if (i is IziPrintLineWrap) {
        items.add(pw.SizedBox(height: i.lines*xs));
      } else if (i is IziPrintQR) {
        items.add(
          pw.Row(
            mainAxisAlignment: i.align == IziPrintAlign.left
                ? pw.MainAxisAlignment.start
                : i.align == IziPrintAlign.right
                ? pw.MainAxisAlignment.end
                : pw.MainAxisAlignment.center,
            children: [
              pw.BarcodeWidget(
                data: i.qrContent,
                barcode: pw.Barcode.fromType(pw.BarcodeType.QrCode),
                width: 30.0*i.size,
                height: 30.0*i.size,
              )
            ]
          )
        );
      } else if (i is IziPrintImage) {
        var dec = decodeImage(i.image);
        if (dec != null) {
          items.add(pw.Row(
            mainAxisAlignment: i.align == IziPrintAlign.left
                ? pw.MainAxisAlignment.start
                : i.align == IziPrintAlign.right
                ? pw.MainAxisAlignment.end
                : pw.MainAxisAlignment.center,
            children: [
              pw.Image(
                pw.MemoryImage(
                  i.image,
                ),
                height: i.size.toDouble()*0.6,
                width: i.size.toDouble()*0.6,

              )
            ]
          ));
        }
      }
    }

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(children: items,crossAxisAlignment: pw.CrossAxisAlignment.stretch); // Center
        }));

    var bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (format)=>bytes,format: PdfPageFormat.roll80,usePrinterSettings: false);
  }
}
