import 'dart:io';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';
import 'package:image/image.dart';

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

class IziPrintImage extends IziPrintItem{
  Uint8List image;
  IziPrintAlign align;
  int size;
  IziPrintImage(this.image,{this.align = IziPrintAlign.center,required this.size});
}
class IziPrintQR extends IziPrintItem{
  String qrContent;
  int size;
  IziPrintAlign align;
  IziPrintQR(this.qrContent,{required this.size,this.align=IziPrintAlign.center});
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
enum IziPrintSize { xs,sm,md,lg,xl}

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
  print(List<IziPrintItem> values) async {
    if (kIsWeb) {
      await _pdfPrint();
    } else {
      if (Platform.isAndroid) {
        var resBinding = await SunmiPrinter.bindingPrinter();
        if (resBinding == true) {
          await _sunmiPrint(values);
        } else {
          await _pdfPrint();
        }
      } else {
        await _pdfPrint();
      }
    }
  }

  _sunmiPrint(List<IziPrintItem> values) async {

    const longPaperSm = 62;
    SunmiFontSize selectFontSize(IziPrintSize size){
      switch(size){
        case IziPrintSize.xs:
          return SunmiFontSize.XS;
        case IziPrintSize.sm:
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
            throw ArgumentError("La suma de los porcentajes debe ser igual a 100");
          }
          List<int> valores = porcentajes.map((p) => (p * longPaperSm ~/ 100)).toList();
          int diferencia = longPaperSm - valores.reduce((a, b) => a + b);
          for (int i = 0; i < diferencia; i++) {
            valores[i] += 1;
          }
          return valores;
        }



        await SunmiPrinter.setFontSize(selectFontSize(i.size));
        if(i.bold){
          await SunmiPrinter.bold();
        }

        if(i.size==IziPrintSize.sm){
          var valuesT=porcentajesAValoresSm(i.values.map((e) => e.width).toList());
          for(var j = 0;j<i.values.length;j++){
            i.values[j].width=valuesT[j];
          }
        }
        await SunmiPrinter.printRow(

            cols: i.values.map((e) {

          return ColumnMaker(
              width: e.width,
              text: e.text,
              align: e.align == IziPrintAlign.left
                  ? SunmiPrintAlign.LEFT
                  : e.align == IziPrintAlign.right
                      ? SunmiPrintAlign.RIGHT
                      : SunmiPrintAlign.CENTER);
        },).toList());
        await SunmiPrinter.resetFontSize();
        await SunmiPrinter.resetBold();
      }
      else if(i is IziPrintSeparator){
        await SunmiPrinter.line(ch: i.dotted?'-':'─',len: 48);
      }
      else if(i is IziPrintText){
        await SunmiPrinter.printText(i.text,style: SunmiStyle(align: i.align == IziPrintAlign.left
            ? SunmiPrintAlign.LEFT
            : i.align == IziPrintAlign.right
            ? SunmiPrintAlign.RIGHT
            : SunmiPrintAlign.CENTER,bold: i.bold,fontSize: selectFontSize(i.size)));
      }
      else if(i is IziPrintLineWrap){
        await SunmiPrinter.lineWrap(i.lines);
      }
      else if(i is IziPrintQR){
        await SunmiPrinter.setAlignment(i.align == IziPrintAlign.left
            ? SunmiPrintAlign.LEFT
            : i.align == IziPrintAlign.right
            ? SunmiPrintAlign.RIGHT
            : SunmiPrintAlign.CENTER);
        await SunmiPrinter.printQRCode(i.qrContent,size: i.size);
        await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      }
      else if(i is IziPrintImage){
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile,spaceBetweenRows: 0);
        var dec=decodeImage(i.image);
        if(dec!=null){
          Image resized = copyResize(dec,width: i.size,height: i.size);
          List<int> bytes = generator.imageRaster(resized,align: i.align == IziPrintAlign.left
              ? PosAlign.left
              : i.align == IziPrintAlign.right
              ? PosAlign.right
              : PosAlign.center);
          await SunmiPrinter.printRawData(Uint8List.fromList(bytes));
        }
      }
    }
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.cut();
    await SunmiPrinter.exitTransactionPrint(true);

  }

  _pdfPrint() async {}
}
