/// The money each payment rail charges in (ISO 4217), as its charge request
/// names it.
///
/// One source for both ends of a charge: what the request asks the terminal
/// or the bank for, and what the monitoring says was charged
/// (`tx.summary.currency`, contracts §5.1). Neither is derived from the
/// account's country nor from the sale's money: a rail charges what it is
/// asked to, and that is what was charged.
///
/// A rail whose request names no money leaves it unknown (null) rather
/// than guessed: ATC (`/v2/{ctl|chip}/{ip}/{amount}/0`), and the QR, Bre-B
/// and pay-at-the-counter requests to iZi, which decides the money itself.
class ChargedCurrency {
  const ChargedCurrency._();

  /// Izify POS (EcoPay): the `currency` of its `/pay`.
  static const String izify = 'COP';

  /// Linkser: its `/sale` takes the ISO 4217 numeric code ([linkserCode]).
  static const String linkser = 'BOB';

  /// What Linkser is sent as `cod_moneda`: [linkser], by number.
  static const String linkserCode = '068';

  /// The money of a card charge on the terminal chosen: an Izify POS, else
  /// Linkser, else ATC (which names none).
  static String? ofCard({required bool izify, required bool linkser}) =>
      izify ? ChargedCurrency.izify : (linkser ? ChargedCurrency.linkser : null);

  /// The money a stored Izify POS charge was sent in: the one stored with it
  /// ([stored]), else [izify] for a row from before the kiosk stored it,
  /// which is all that terminal was ever asked for. Retrying it sends this.
  static String ofStoredIzify(String? stored) => stored ?? izify;
}
