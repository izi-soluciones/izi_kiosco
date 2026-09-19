import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';

void main() {
  group('moneyFormat (Bolivian style, digitsTaxes == 0)', () {
    test('zero always renders as 0,00 with no currency prefix', () {
      expect((0).moneyFormat(currency: 'Bs', digitsTaxes: 0), '0,00');
    });
    test('thousands use dot and decimals use comma', () {
      expect((1000.5).moneyFormat(currency: 'Bs', digitsTaxes: 0), 'Bs 1.000,5');
    });
    test('integer values render without decimals', () {
      expect((1000).moneyFormat(currency: 'Bs', digitsTaxes: 0), 'Bs 1.000');
    });
    test('trims to at most two significant decimals', () {
      expect(
        (1234.567).moneyFormat(currency: 'Bs', digitsTaxes: 0),
        'Bs 1.234,57',
      );
    });
  });

  group('moneyFormat (fixed decimals, digitsTaxes > 0)', () {
    test('formats with the requested tax digits', () {
      expect((1234.567).moneyFormat(currency: r'$', digitsTaxes: 2), r'$ 1234.57');
    });
    test('digits argument overrides digitsTaxes', () {
      expect((1.5).moneyFormat(currency: r'$', digitsTaxes: 2, digits: 0), r'$ 2');
    });
    test('empty currency yields no prefix', () {
      expect((5.5).moneyFormat(currency: '', digitsTaxes: 2), '5.50');
    });
    test('null currency yields no prefix', () {
      expect((5.5).moneyFormat(digitsTaxes: 2), '5.50');
    });
  });

  group('moneyFormat reduce flag', () {
    test('whole numbers drop decimals when reduce is true', () {
      expect((100).moneyFormat(currency: 'Bs', digitsTaxes: 2, reduce: true),
          'Bs 100');
    });
  });

  group('symbioticFormat', () {
    test('rounds to two decimals and scales by 100', () {
      expect((10.5).symbioticFormat(), 1050.0);
      expect((1.234).symbioticFormat(), 123.0);
    });
  });
}
