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

  // Medio hacia arriba (el 5 sube, lejos de cero), igual que el backbone, izi-app, izi-pos e
  // izi-ms-ventas (BKB-008): si uno redondea distinto, el total no cuadra con la factura.
  static double roundConservador(num n, [int decimals = 2]) =>
      Decimal.parse(n.toString()).round(scale: decimals).toDouble();

  static double roundCeil(num a) =>
      Decimal.parse(a.toString()).ceil(scale: 2).toDouble();
}