import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:printing/printing.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
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

abstract class IziPrintItem {}

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
        await SunmiPrinter.printText("Bienvenido");
        await SunmiPrinter.cutPaper();
      } else {
        //await _pdfPrint(values);
      }
    }
  }
  printTest() async {
    if (kIsWeb) {
    } else {
      if (Platform.isAndroid) {
        await SunmiPrinter.printText("Bienvenido Kiosko-iZi",
            style: SunmiTextStyle(
                align: SunmiPrintAlign.CENTER,
                bold: true,
                fontSize: 24));
        await SunmiPrinter.cutPaper();
      } else {
        //await _pdfPrint(values);
      }
    }
  }
  print(List<IziPrintItem> values, Device? device) async {
    if (kIsWeb) {
      await _pdfPrint(values);
    } else {
      if (Platform.isAndroid) {
        await _sunmiPrint(values);
      } else {
        //await _pdfPrint(values);
      }
    }
  }

  _sunmiPrint(List<IziPrintItem> values) async {
    const longPaperSm = 62;
    int selectFontSize(IziPrintSize size) {
      switch (size) {
        case IziPrintSize.xs:
          return 18;
        case IziPrintSize.sm:
          return 20;
        case IziPrintSize.sml:
          return 20;
        case IziPrintSize.md:
          return 24;
        case IziPrintSize.lg:
          return 36;
        case IziPrintSize.xl:
          return 48;
      }
    }
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
            return SunmiColumn(
                width: e.width,
                text: e.text,
                style: SunmiTextStyle(
                    fontSize: selectFontSize(i.size),
                    bold: i.bold,
                    align: e.align == IziPrintAlign.left
                        ? SunmiPrintAlign.LEFT
                        : e.align == IziPrintAlign.right
                            ? SunmiPrintAlign.RIGHT
                            : SunmiPrintAlign.CENTER));
          },
        ).toList());
      } else if (i is IziPrintSeparator) {
        await SunmiPrinter.line(type: i.dotted ? 'DOTTED' : 'SOLID'); // It might wait for SOLID or DOTTED. In SunmiPrintLine it's SOLID, DOTTED. Wait, let's just use string or avoid type. Actually, type does not take an enum it takes a String?
      } else if (i is IziPrintText) {
        await SunmiPrinter.printText(i.text,
            style: SunmiTextStyle(
                align: i.align == IziPrintAlign.left
                    ? SunmiPrintAlign.LEFT
                    : i.align == IziPrintAlign.right
                        ? SunmiPrintAlign.RIGHT
                        : SunmiPrintAlign.CENTER,
                bold: i.bold,
                fontSize: selectFontSize(i.size)));
      } else if (i is IziPrintLineWrap) {
        await SunmiPrinter.lineWrap(i.lines);
      } else if (i is IziPrintQR) {
        // Assume qr width needs to be set. The old API had `size`. In v4 maybe we don't have align on QR but we will try. SunmiQrcodeStyle?
        await SunmiPrinter.printQRCode(i.qrContent,style: SunmiQrcodeStyle(qrcodeSize: i.size, align: i.align == IziPrintAlign.left ? SunmiPrintAlign.LEFT : i.align == IziPrintAlign.right ? SunmiPrintAlign.RIGHT : SunmiPrintAlign.CENTER));
        // We will remove size for now if it's not simply supported to specify alignment. Wait, I should provide size if it works.
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
    await SunmiPrinter.cutPaper();
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
