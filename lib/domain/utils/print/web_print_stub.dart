import 'dart:typed_data';

import 'package:izi_kiosco/domain/utils/print/print_result.dart';

// Implementación usada fuera de web. La rama que la invoca está detrás de kIsWeb,
// así que en la práctica no se ejecuta: existe para que compile en Android.
Future<PrintResult> printPdfWeb(Uint8List bytes, Duration timeout) async {
  return PrintResult.fallo(
      PrintVia.webPdf, 0, "Impresión web no disponible en esta plataforma");
}
