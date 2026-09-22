/// Result of an Izify POS card payment, as reported either over the
/// `/payment-updates` WebSocket or the `/payment-status/{reference}` polling
/// endpoint. Both channels use the same JSON shape.
enum PosPaymentStatus {
  success,
  error,
  cancelled,

  /// The outcome is UNKNOWN: the card may or may not have been charged
  /// (confirmation timeout or unconfirmed publish on the POS side).
  /// The kiosk must NOT auto-retry a pending payment; it has to be surfaced
  /// to the operator to verify/reconcile before any retry.
  pending,

  /// No recognizable status could be parsed from the payload.
  unknown,

  /// The terminal accepted the charge and it is still running.
  processing,

  /// The terminal has no record of the reference (HTTP 404): it never
  /// received the `/pay` request, so nothing was charged under it.
  notFound,

  /// The terminal rejected the token (HTTP 401) — it was unpaired or paired
  /// again. The lookup could not be made.
  unauthorized,

  /// The terminal could not be reached for the lookup.
  unreachable,
}

class PosPaymentResult {
  final PosPaymentStatus status;
  final String? transactionId;
  final String? errorMessage;
  final String? reference;

  /// Proof of the charge as the terminal reports it (PayPOS 1.26+). The card
  /// number never carries more than its last 4 digits.
  final String? authCode;
  final String? cardMasked;
  final String? cardBrand;
  final String? cardType;
  final double? amount;
  final String? currency;
  final String? timestamp;
  final String? acquirerTerminalId;
  final String? traceNumber;

  const PosPaymentResult({
    required this.status,
    this.transactionId,
    this.errorMessage,
    this.reference,
    this.authCode,
    this.cardMasked,
    this.cardBrand,
    this.cardType,
    this.amount,
    this.currency,
    this.timestamp,
    this.acquirerTerminalId,
    this.traceNumber,
  });

  static PosPaymentStatus statusFromString(String? raw) {
    switch (raw) {
      case 'SUCCESS':
        return PosPaymentStatus.success;
      case 'ERROR':
        return PosPaymentStatus.error;
      case 'CANCELLED':
        return PosPaymentStatus.cancelled;
      case 'PENDING':
        return PosPaymentStatus.pending;
      case 'PROCESSING':
        return PosPaymentStatus.processing;
      default:
        return PosPaymentStatus.unknown;
    }
  }

  factory PosPaymentResult.fromJson(Map json) {
    return PosPaymentResult(
      status: statusFromString(json['status']?.toString()),
      transactionId: json['transactionId']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      reference: json['reference']?.toString(),
      authCode: json['authCode']?.toString(),
      cardMasked: json['cardMasked']?.toString(),
      cardBrand: json['cardBrand']?.toString(),
      cardType: json['cardType']?.toString(),
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency']?.toString(),
      timestamp: json['timestamp']?.toString(),
      acquirerTerminalId: json['acquirerTerminalId']?.toString(),
      traceNumber: json['traceNumber']?.toString(),
    );
  }

  /// A terminal result stops WebSocket listening / polling. SUCCESS, ERROR,
  /// CANCELLED and PENDING are all terminal. PENDING is terminal-ish: the
  /// terminal may still settle it later (it keeps chasing the answer in the
  /// background), which the operator can check from the transactions screen.
  bool get isTerminal =>
      status == PosPaymentStatus.success ||
      status == PosPaymentStatus.error ||
      status == PosPaymentStatus.cancelled ||
      status == PosPaymentStatus.pending;
}
