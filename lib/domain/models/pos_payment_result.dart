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
}

class PosPaymentResult {
  final PosPaymentStatus status;
  final String? transactionId;
  final String? errorMessage;
  final String? reference;

  const PosPaymentResult({
    required this.status,
    this.transactionId,
    this.errorMessage,
    this.reference,
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
    );
  }

  /// A terminal result stops WebSocket listening / polling. SUCCESS, ERROR,
  /// CANCELLED and PENDING are all terminal (PENDING is terminal-ish: the
  /// POS will not emit a further update, the operator must reconcile).
  bool get isTerminal =>
      status == PosPaymentStatus.success ||
      status == PosPaymentStatus.error ||
      status == PosPaymentStatus.cancelled ||
      status == PosPaymentStatus.pending;
}
