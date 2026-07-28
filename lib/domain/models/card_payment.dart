/// Outcome classification for a stored card transaction, used to decide
/// whether a retry may be offered and whether a safety warning is required.
enum CardPaymentStatus {
  /// Approved / charged (may still have a server-sync error, but the card WAS
  /// charged) — retry must NOT be offered.
  success,

  /// Declined / rejected / cancelled — safe to retry with a normal confirm.
  declined,

  /// Outcome unknown (PENDING / confirmation timeout). The original charge may
  /// have gone through — retry requires a warning confirmation.
  pending,

  /// Could not be classified.
  unknown,
}

class CardPayment{
  String response;
  String date;
  String hour;
  String? cardNumber;
  /// Reference sent to the Izify POS in the `/pay` body. Kept so the caller can
  /// poll `/payment-status/{reference}` as a fallback to the WebSocket, and so a
  /// retry can be tied back to the original attempt.
  String? reference;
  /// Amount string exactly as sent to the POS (e.g. "12.50"). Needed to retry.
  String? amount;
  /// Currency sent to the POS (e.g. "COP"). Needed to retry.
  String? currency;
  /// Transaction id reported by the POS, when known. Opaque string.
  String? transactionId;
  /// Explicit status persisted at save time (SUCCESS/ERROR/CANCELLED/PENDING/
  /// UNKNOWN). Older records won't have this and fall back to text parsing.
  String? status;

  CardPayment({
    required this.response,
    required this.cardNumber,
    required this.date,
    required this.hour,
    this.reference,
    this.amount,
    this.currency,
    this.transactionId,
    this.status,
});

  factory CardPayment.fromJson(Map json)=>CardPayment(
      response: json["mensaje"] ?? "",
      cardNumber:json["pan"]??"",
      date: json["fecha"]??"",
      hour: json["hora"]??"");
  factory CardPayment.fromJsonATC(Map json)=>CardPayment(
      response: json["mensaje"] ?? "",
      cardNumber:json["pan"] ?? "",
      date: json["fecha"] ?? "",
      hour: json["hora"] ?? "");

  factory CardPayment.fromJsonStorage(Map json)=>CardPayment(
      response: json["respuesta"] ?? "",
      cardNumber:json["tarjeta"],
      date: json["fecha"],
      hour: json["hora"],
      reference: json["referencia"],
      amount: json["monto"],
      currency: json["moneda"],
      transactionId: json["transactionId"],
      status: json["estado"]);

  Map toJson()=>{
    "respuesta": response,
    "fecha": date,
    "hora": hour,
    "tarjeta": cardNumber,
    if (reference != null) "referencia": reference,
    if (amount != null) "monto": amount,
    if (currency != null) "moneda": currency,
    if (transactionId != null) "transactionId": transactionId,
    if (status != null) "estado": status,
  };

  /// Classifies the transaction outcome. Prefers the explicit [status] field
  /// (new records) and falls back to parsing the free-text [response] for
  /// records saved before structured status existed.
  CardPaymentStatus get retryStatus {
    switch (status) {
      case 'SUCCESS':
        return CardPaymentStatus.success;
      case 'ERROR':
      case 'CANCELLED':
        return CardPaymentStatus.declined;
      case 'PENDING':
      case 'UNKNOWN':
        return CardPaymentStatus.pending;
    }
    final r = response.toLowerCase();
    if (r.startsWith('aprobada') || r.startsWith('aprobado')) {
      // Approved (even "Aprobada - Error sync server") means the card WAS
      // charged, so retry must not be offered.
      return CardPaymentStatus.success;
    }
    if (r.startsWith('pendiente') || r.contains('sin confirmar')) {
      return CardPaymentStatus.pending;
    }
    if (r.startsWith('rechazad') || r.contains('cancel')) {
      return CardPaymentStatus.declined;
    }
    return CardPaymentStatus.unknown;
  }

  /// Retry is allowed for anything that is NOT a confirmed success.
  bool get canRetry => retryStatus != CardPaymentStatus.success;

  /// Whether retrying needs the "may already be charged" warning.
  bool get retryNeedsWarning =>
      retryStatus == CardPaymentStatus.pending ||
      retryStatus == CardPaymentStatus.unknown;

  }
