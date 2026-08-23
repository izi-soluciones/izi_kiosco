import 'package:shared_preferences/shared_preferences.dart';

class LocalStoragePrintLogs {
  LocalStoragePrintLogs._();

  static const _key = "printLogs";
  static const _maxPendientes = 50;

  // Todo va en try/catch silencioso: el logging nunca puede tumbar el flujo de pago.
  static Future<void> add(String evento) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var pendientes = prefs.getStringList(_key) ?? [];

      pendientes.add(evento);

      if (pendientes.length > _maxPendientes) {
        pendientes = pendientes.sublist(pendientes.length - _maxPendientes);
      }

      await prefs.setStringList(_key, pendientes);
    } catch (_) {}
  }

  static Future<List<String>> getAll() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> remove(List<String> enviados) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var pendientes = prefs.getStringList(_key) ?? [];
      pendientes.removeWhere((element) => enviados.contains(element));
      await prefs.setStringList(_key, pendientes);
    } catch (_) {}
  }
}
