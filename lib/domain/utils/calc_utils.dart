import 'package:decimal/decimal.dart';

class Calc {
  static double mul(num a, num b) =>
      (Decimal.parse(a.toString()) * Decimal.parse(b.toString())).toDouble();

  static double sub(num a, num b) =>
      (Decimal.parse(a.toString()) - Decimal.parse(b.toString())).toDouble();

  static double add(num a, num b) =>
      (Decimal.parse(a.toString()) + Decimal.parse(b.toString())).toDouble();

  static double div(num a, num b) =>
      (Decimal.parse(a.toString()) / Decimal.parse(b.toString())).toDouble();

  static double roundConservador(num n, [int decimals = 2]) {
    Decimal numero = Decimal.parse(n.toString());
    final numString = numero.toString();
    final dotIndex = numString.indexOf('.');

    if (dotIndex == -1) return numero.toDouble();

    final decimalDecisorPos = dotIndex + decimals + 1;
    final decimalDecisor = (decimalDecisorPos < numString.length) ? numString[decimalDecisorPos] : '0';

    if (decimalDecisor == '5') {
      final decimalSiguienteChar = (decimalDecisorPos + 1 < numString.length) ? numString[decimalDecisorPos + 1] : '0';
      final int decimalSiguiente = int.tryParse(decimalSiguienteChar) ?? 0;

      if (decimalSiguiente % 2 != 0) {
        if (numero >= Decimal.zero) {
          return numero.ceil(scale: decimals).toDouble();
        } else {
          return numero.floor(scale: decimals).toDouble();
        }
      } else {
        return numero.truncate(scale: decimals).toDouble();
      }
    } else {
      return numero.round(scale: decimals).toDouble();
    }
  }

  static double roundCeil(num a) =>
      Decimal.parse(a.toString()).ceil(scale: 2).toDouble();
}