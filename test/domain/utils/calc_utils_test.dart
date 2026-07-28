import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/utils/calc_utils.dart';

void main() {
  group('Calc.mul', () {
    test('multiplies without floating point error', () {
      expect(Calc.mul(0.1, 0.2), 0.02);
      expect(Calc.mul(3, 4), 12);
      expect(Calc.mul(2.5, 4), 10);
    });
    test('multiplies by zero', () {
      expect(Calc.mul(0, 999.99), 0);
    });
    test('handles negatives', () {
      expect(Calc.mul(-2, 3), -6);
    });
  });

  group('Calc.add', () {
    test('adds without floating point error', () {
      expect(Calc.add(0.1, 0.2), 0.3);
      expect(Calc.add(1.005, 2.005), 3.01);
    });
    test('adds negatives', () {
      expect(Calc.add(-5, 3), -2);
    });
  });

  group('Calc.sub', () {
    test('subtracts without floating point error', () {
      expect(Calc.sub(0.3, 0.1), 0.2);
      expect(Calc.sub(1, 1), 0);
    });
    test('subtracts into negative', () {
      expect(Calc.sub(1, 3), -2);
    });
  });

  group('Calc.div', () {
    test('divides evenly', () {
      expect(Calc.div(10, 4), 2.5);
      expect(Calc.div(9, 3), 3);
    });
    test('divides producing repeating decimal', () {
      expect(Calc.div(1, 3), closeTo(0.3333333333, 1e-9));
    });
  });

  group('Calc.roundCeil', () {
    test('rounds up to 2 decimals', () {
      expect(Calc.roundCeil(1.231), 1.24);
      expect(Calc.roundCeil(1.001), 1.01);
    });
    test('leaves exact 2-decimal values unchanged', () {
      expect(Calc.roundCeil(1.23), 1.23);
    });
  });

  group('Calc.roundConservador', () {
    test('rounds normally when 3rd decimal is not 5', () {
      expect(Calc.roundConservador(1.234), 1.23);
      expect(Calc.roundConservador(1.236), 1.24);
    });
    test('returns the value unchanged when there is no decimal part', () {
      expect(Calc.roundConservador(5), 5);
      expect(Calc.roundConservador(100), 100);
    });
    test('truncates on trailing 5 with even following digit (incl. absent)', () {
      // "1.235" -> decisor '5', following digit absent -> treated as 0 (even) -> truncate
      expect(Calc.roundConservador(1.235), 1.23);
    });
    test('rounds away from zero on trailing 5 with odd following digit', () {
      // "1.2355" -> decisor '5', following '5' odd -> ceil for positive
      expect(Calc.roundConservador(1.2355), 1.24);
    });
    test('floors negatives away from zero on trailing 5 with odd following digit', () {
      expect(Calc.roundConservador(-1.2355), -1.24);
    });
    test('honors a custom decimals argument', () {
      expect(Calc.roundConservador(12.5, 0), 12);
      expect(Calc.roundConservador(12.34, 0), 12);
      expect(Calc.roundConservador(12.6, 0), 13);
    });
  });
}
