enum PrintVia { webPdf, sunmi, ninguna }

// Resultado de un intento de impresión. Antes print() no devolvía nada, así que el bloc
// no tenía forma de saber si el ticket había salido.
class PrintResult {
  final bool ok;
  final PrintVia via;
  final int duracionMs;
  final String? error;
  final bool timeout;

  const PrintResult({
    required this.ok,
    required this.via,
    required this.duracionMs,
    this.error,
    this.timeout = false,
  });

  factory PrintResult.exito(PrintVia via, int duracionMs) =>
      PrintResult(ok: true, via: via, duracionMs: duracionMs);

  factory PrintResult.fallo(PrintVia via, int duracionMs, String error) =>
      PrintResult(ok: false, via: via, duracionMs: duracionMs, error: error);

  factory PrintResult.porTiempo(PrintVia via, int duracionMs) => PrintResult(
      ok: false,
      via: via,
      duracionMs: duracionMs,
      timeout: true,
      error: "Timeout esperando a la impresora");

  String get resultadoLog => ok ? "OK" : (timeout ? "TIMEOUT" : "ERROR");

  String get viaLog {
    switch (via) {
      case PrintVia.webPdf:
        return "WEB_PDF";
      case PrintVia.sunmi:
        return "SUNMI";
      case PrintVia.ninguna:
        return "SUNMI";
    }
  }
}
