import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';

/// The values of `tx.summary.method` (contracts §5.1).
class TxMethod {
  const TxMethod._();

  static const String card = 'card';
  static const String qr = 'qr';
  static const String breb = 'breb';

  /// Ordered at the kiosk and paid at the counter.
  static const String cash = 'cash';
  static const String other = 'other';
}

/// The values of `tx.summary.status` (contracts §5.1).
class TxStatus {
  const TxStatus._();

  static const String approved = 'approved';

  /// The terminal or the acquirer said no.
  static const String declined = 'declined';

  /// No verdict: the card may have been charged.
  static const String timeout = 'timeout';

  /// It never reached the terminal or iZi, or the kiosk could not ask.
  static const String error = 'error';

  /// The customer gave up: on the terminal, or by leaving the QR screen.
  static const String cancelled = 'cancelled';

  /// Charged, and iZi does not know.
  static const String unregistered = 'unregistered';
}

/// The values of `tx.summary.verdictVia` (contracts §5.1).
class TxVerdictVia {
  const TxVerdictVia._();

  static const String ws = 'ws';
  static const String poll = 'poll';
  static const String timeout = 'timeout';

  /// The word the kiosk's own logs use (`charge.result.via`), as the
  /// contract names it: the terminal saying it never got the charge was
  /// heard by polling. Null when it is none of them.
  static String? of(String? via) => switch (via) {
        ws || poll || timeout => via,
        'not_found' => poll,
        _ => null,
      };
}

/// One transaction of the payment page, from the moment the customer chose
/// how to pay to its outcome, for the `tx.summary` event (contracts §5.1).
///
/// The payment flow notes what it learns as it goes ([sent],
/// [acknowledged], [verdict], [settle]); [report] records the summary once,
/// at the point where the transaction ends. The monitoring keeps the latest
/// summary of each [chargeId], so a charge settled later (a pending one
/// verified, a retry, the recovery after a reload) is reported again under
/// the same [chargeId] and replaces the earlier outcome. That is also how a
/// page closing mid-charge works: [reportInterim] says how it stands, and
/// the flow still running reports how it ended.
///
/// Nothing here may break a sale: it never throws.
class TransactionSummary {
  final String method;
  final DateTime Function() _now;

  /// The whole charge (cobro), retries included: the terminal's `CHG-…` for
  /// an Izify POS charge, one of the kiosk's own for everything else.
  String? chargeId;

  /// The last attempt on the terminal (`KOS-…`); null without one.
  String? reference;
  num? amount;

  /// ISO 4217, when known.
  String? currency;

  /// The iZi order paid (its uuid).
  String? comandaId;

  /// The iZi invoice of the sale (its uuid), once iZi says.
  String? facturaId;
  String? verdictVia;
  int? msToAck;
  int? msToVerdict;

  /// Times the charge was sent to a terminal (or a QR shown) for this
  /// transaction, earlier attempts of a retried charge included.
  int attempts;

  DateTime? _sentAt;
  String? _settled;
  bool _reported = false;
  bool _interim = false;

  TransactionSummary(
      {required this.method,
      this.chargeId,
      this.reference,
      this.amount,
      this.currency,
      this.comandaId,
      this.attempts = 0,
      DateTime Function()? now})
      : _now = now ?? DateTime.now;

  /// What a stored card charge says about itself, for the summaries the
  /// transactions screen and the recovery report when they settle it.
  factory TransactionSummary.ofCardPayment(CardPayment cp, {DateTime Function()? now}) =>
      TransactionSummary(
          method: TxMethod.card,
          chargeId: cp.chargeId,
          reference: cp.reference,
          amount: num.tryParse(cp.amount ?? ''),
          currency: cp.currency,
          comandaId: cp.comandaId,
          attempts: cp.attempts ?? (cp.reference != null ? 1 : 0),
          now: now);

  /// ISO 4217 of the money of [countryCode] (`BO`, `CO`), when known.
  static String? currencyOf(String? countryCode) => switch (countryCode?.toUpperCase()) {
        'BO' => 'BOB',
        'CO' => 'COP',
        _ => null,
      };

  /// Already reported: nothing changes it any more.
  bool get reported => _reported;

  /// Reported for now ([reportInterim]): its outcome is still to come.
  bool get interim => _interim;

  /// The outcome noted with [settle], not reported yet.
  String? get settled => _settled;

  /// Sent to the terminal (or the QR shown), the [attempts]-th time.
  bool get started => _sentAt != null;

  /// A verdict came in for the last attempt.
  bool get hasVerdict => msToVerdict != null || verdictVia != null;

  /// The charge left for the terminal (or the QR is on screen). [at] is when,
  /// when the flow took it itself.
  void sent({String? reference, DateTime? at}) {
    try {
      if (_reported) return;
      attempts++;
      if (reference != null) this.reference = reference;
      _sentAt = at ?? _now();
      msToAck = null;
      msToVerdict = null;
      verdictVia = null;
    } catch (_) {}
  }

  /// The terminal took the charge (`/pay` answered).
  void acknowledged() {
    try {
      if (_reported || msToAck != null) return;
      msToAck = _since();
    } catch (_) {}
  }

  /// The outcome of the last attempt is known. [via] is how it arrived (see
  /// [TxVerdictVia.of]); the first verdict is the one kept.
  void verdict({String? via}) {
    try {
      if (_reported || hasVerdict) return;
      msToVerdict = _since();
      verdictVia = TxVerdictVia.of(via);
    } catch (_) {}
  }

  /// The outcome is known, but the transaction is not over: approved, while
  /// iZi still makes the invoice. The first one noted stays. After
  /// [reportInterim] nobody waits for the rest any more (the page is gone):
  /// it is reported right away.
  void settle(String status) {
    if (_reported) return;
    _settled ??= status;
    if (_interim) report();
  }

  /// The `tx.summary` data for [status], or null once reported: a
  /// transaction is summed up once.
  Map<String, Object?>? finish(String status) {
    if (_reported) return null;
    _reported = true;
    return toData(status);
  }

  /// The summary as the contract names it, whatever was reported before.
  Map<String, Object?> toData(String status) => {
        'chargeId': chargeId,
        'reference': reference,
        'amount': amount,
        'currency': currency,
        'method': method,
        'status': status,
        'verdictVia': verdictVia,
        'comandaId': comandaId,
        'facturaId': facturaId,
        'msToAck': msToAck,
        'msToVerdict': msToVerdict,
        'attempts': attempts,
      };

  /// Records the `tx.summary` for [status] (the outcome noted with [settle]
  /// when null), once. Returns whether it did. Never throws.
  bool report([String? status]) {
    try {
      final outcome = status ?? _settled;
      if (outcome == null) return false;
      final data = finish(outcome);
      if (data == null) return false;
      _record(outcome, data);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Records the `tx.summary` for [status] for now: the page is going away
  /// while the transaction's flow still runs (the terminal deciding, iZi
  /// being told). What the flow learns next ([report], [settle]) is
  /// reported over it; if nothing comes, this one stands. Once, and not
  /// after [report]. Returns whether it did. Never throws.
  bool reportInterim(String status) {
    try {
      if (_reported || _interim) return false;
      _interim = true;
      _record(status, toData(status));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _record(String status, Map<String, Object?> data) => Telemetry.event('tx.summary',
      level: levelOf(status), chargeId: chargeId, reference: reference, data: data);

  /// A charge without a verdict or one iZi does not know needs someone;
  /// a decline or a cancellation is routine.
  static TelemetryLevel levelOf(String status) => switch (status) {
        TxStatus.unregistered => TelemetryLevel.error,
        TxStatus.timeout || TxStatus.error => TelemetryLevel.warning,
        _ => TelemetryLevel.info,
      };

  int? _since() {
    final sentAt = _sentAt;
    if (sentAt == null) return null;
    final ms = _now().difference(sentAt).inMilliseconds;
    return ms < 0 ? 0 : ms;
  }
}
