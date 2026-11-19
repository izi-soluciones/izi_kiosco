import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/charged_currency.dart';

void main() {
  test('what each rail is asked to charge', () {
    expect(ChargedCurrency.izify, 'COP');
    expect(ChargedCurrency.linkser, 'BOB');
    expect(ChargedCurrency.linkserCode, '068');
  });

  test('a card charge: the terminal chosen, Izify POS first, ATC names none', () {
    expect(ChargedCurrency.ofCard(izify: true, linkser: false), 'COP');
    expect(ChargedCurrency.ofCard(izify: true, linkser: true), 'COP',
        reason: 'the charge goes to the Izify POS, as _callCardProvider does');
    expect(ChargedCurrency.ofCard(izify: false, linkser: true), 'BOB');
    expect(ChargedCurrency.ofCard(izify: false, linkser: false), isNull);
  });

  test('a stored Izify charge: what it was sent in, COP when the row does not say', () {
    expect(ChargedCurrency.ofStoredIzify('COP'), 'COP');
    expect(ChargedCurrency.ofStoredIzify('USD'), 'USD', reason: 'sent again exactly as stored');
    expect(ChargedCurrency.ofStoredIzify(null), 'COP');
  });
}
