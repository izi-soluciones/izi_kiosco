import 'package:intl/intl.dart';

extension DateFormatter on num {
  String moneyFormat({
    String? currency,
    int? digits,
    bool reduce = false,
    required int digitsTaxes,
  }) {
    // Caso: reducir decimales si es entero
    if(digitsTaxes == 0 && this==0){
      return "0,00";
    }
    if (reduce && this % 1 == 0) {
      return "${currency?.isNotEmpty ?? false ? "$currency " : ""}$this";
    }

    // Si digitsTaxes == 0 => usar formato boliviano (punto miles, coma decimales)
    if (digitsTaxes == 0) {
      // Detecta si el número tiene parte decimal
      bool hasDecimals = this % 1 != 0;

      // Usa patrón decimal con o sin parte fraccionaria
      final formatter = NumberFormat(hasDecimals ? "#,##0.##" : "#,##0", "en_US");
      // Forzamos la inversión: punto para miles, coma para decimales
      String formatted = formatter.format(this)
          .replaceAll(',', '#')  // marca las comas (miles)
          .replaceAll('.', ',')  // cambia punto (decimal) → coma
          .replaceAll('#', '.'); // cambia las marcas (miles) → punto

      return "${currency?.isNotEmpty ?? false ? "$currency " : ""}$formatted";
    }

    // Caso normal (usa toStringAsFixed)
    return "${currency?.isNotEmpty ?? false ? "$currency " : ""}${toStringAsFixed(digits ?? (this == 0 ? 2 : digitsTaxes))}";
  }

  double symbioticFormat() {
    return num.parse(toStringAsFixed(2)) * 100;
  }
}