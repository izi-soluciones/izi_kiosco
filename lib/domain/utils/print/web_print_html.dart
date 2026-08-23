import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:typed_data';

import 'package:izi_kiosco/domain/utils/print/print_result.dart';

const Duration _esperaLimpieza = Duration(seconds: 10);
int _contadorTrabajo = 0;

// Impresión propia en web, en reemplazo de Printing.layoutPdf. El package reutiliza un
// iframe de id fijo entre llamadas, así que la factura pisaba a la orden; nunca revoca el
// objectUrl ni remueve el iframe cuando el print es rápido (que es el caso con
// --kiosk-printing); y si el evento load no dispara, su Completer no completa nunca y deja
// el flujo de pago colgado. Acá el id es único por trabajo, hay timeout y se limpia todo.
Future<PrintResult> printPdfWeb(Uint8List bytes, Duration timeout) async {
  final cronometro = Stopwatch()..start();

  if (bytes.isEmpty) {
    return PrintResult.fallo(PrintVia.webPdf, 0, "El PDF generado está vacío");
  }

  _contadorTrabajo++;
  final frameId = "izi-print-$_contadorTrabajo-${DateTime.now().microsecondsSinceEpoch}";

  final blob = html.Blob(<Uint8List>[bytes], 'application/pdf');
  final objectUrl = html.Url.createObjectUrl(blob);
  final frame = html.IFrameElement()
    ..id = frameId
    ..style.visibility = 'hidden'
    ..style.height = '0'
    ..style.width = '0'
    ..style.position = 'absolute'
    ..src = objectUrl;

  final completer = Completer<PrintResult>();

  void completar(PrintResult resultado) {
    if (!completer.isCompleted) {
      completer.complete(resultado);
    }
  }

  html.EventListener? alCargar;
  alCargar = (html.Event event) {
    frame.removeEventListener('load', alCargar);
    try {
      final ventana = frame.contentWindow;
      if (ventana == null) {
        completar(PrintResult.fallo(PrintVia.webPdf,
            cronometro.elapsedMilliseconds, "El iframe no expuso contentWindow"));
        return;
      }
      js.JsObject.fromBrowserObject(ventana).callMethod('print', []);
      completar(PrintResult.exito(PrintVia.webPdf, cronometro.elapsedMilliseconds));
    } catch (e) {
      completar(PrintResult.fallo(
          PrintVia.webPdf, cronometro.elapsedMilliseconds, e.toString()));
    }
  };

  frame.addEventListener('load', alCargar);
  html.document.body!.append(frame);

  try {
    return await completer.future.timeout(
      timeout,
      onTimeout: () =>
          PrintResult.porTiempo(PrintVia.webPdf, cronometro.elapsedMilliseconds),
    );
  } finally {
    cronometro.stop();
    // Diferida: en algunos navegadores print() retorna antes de que el trabajo salga, y
    // remover el iframe en ese momento lo cancelaría.
    Timer(_esperaLimpieza, () {
      try {
        frame.removeEventListener('load', alCargar);
        frame.remove();
        html.Url.revokeObjectUrl(objectUrl);
      } catch (_) {}
    });
  }
}
