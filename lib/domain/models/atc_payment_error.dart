/// Cómo terminó una llamada a /v2/ctl o /v2/chip que no fue una aprobación.
enum AtcPaymentErrorType {
  /// El POS respondió (status false): rechazo o error del propio POS.
  rejected,

  /// El servidor no le mandó nada al POS porque ya tenía un pago en curso.
  paymentInProgress,

  /// El servidor respondió antes de contactar al POS (POS no conectado, monto
  /// inválido, ref inválido): el POS no cobró, es un error definitivo.
  notSent,

  /// No se sabe si el POS cobró: timeout, red, cancelación del cliente o
  /// una respuesta del servidor sin el status del POS (p. ej. su propio
  /// "Tiempo de espera superado").
  uncertain,
}

class AtcPaymentError implements Exception {
  final AtcPaymentErrorType type;
  final dynamic detail;

  const AtcPaymentError(this.type, [this.detail]);

  /// Clasifica una respuesta HTTP 200 del servidor que no cumple la regla de
  /// aprobación (`status == true && data != null`).
  factory AtcPaymentError.fromResponse(dynamic res) {
    if (res is Map && res["codigo"] == "pagoEnCurso") {
      return AtcPaymentError(AtcPaymentErrorType.paymentInProgress, res);
    }
    if (_beforePos(res)) {
      return AtcPaymentError(AtcPaymentErrorType.notSent, res);
    }
    if (res is Map && res["status"] == false) {
      return AtcPaymentError(AtcPaymentErrorType.rejected, res);
    }
    return AtcPaymentError(AtcPaymentErrorType.uncertain, res);
  }

  // Las respuestas de pos-v2.js que salen antes de SendConnection*, iguales en el servidor viejo
  // y en el nuevo. "Error" (el catch) no está: puede salir después de contactar al POS.
  static bool _beforePos(dynamic res) {
    if (res is String) {
      final text = res.trim();
      return text.startsWith("El IP no existe") ||
          text.startsWith("El monto debe ser");
    }
    if (res is Map && res["codigo"] == "refInvalido") {
      return true;
    }
    // {"resp": "El número IP<ip> no existe"}: el socket del POS no está conectado
    final resp = res is Map && res["status"] == null ? res["resp"] : null;
    return resp is String &&
        resp.startsWith("El n") &&
        resp.contains("IP") &&
        resp.trim().endsWith("no existe");
  }

  @override
  String toString() => "AtcPaymentError(${type.name}): $detail";
}
