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

  static double roundConservador(num n) {
    Decimal numero = Decimal.parse(n.toString());
  final numString = numero.toString();
  final dotIndex = numString.indexOf('.');
  
  if (dotIndex == -1) return numero.toDouble();

  final tercerDecimal = (dotIndex + 3 < numString.length) ? numString[dotIndex + 3] : '0';

  if (tercerDecimal == '5') {
    final cuartoDecimal = (dotIndex + 4 < numString.length) ? int.tryParse(numString[dotIndex + 4]) ?? 0 : 0;
    if (cuartoDecimal % 2 != 0) {
      return numero.ceil(scale: 2).toDouble(); // round up
    } else {
      return numero.truncate(scale: 2).toDouble(); // round down
    }
  } else {
    return numero.round(scale: 2).toDouble(); // half-up normal
  }
}

  static double roundCeil(num a) =>
      Decimal.parse(a.toString()).ceil(scale: 2).toDouble();
}