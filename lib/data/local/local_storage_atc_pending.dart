import 'dart:convert';

import 'package:izi_kiosco/domain/models/atc_pending_payment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageAtcPending{
  LocalStorageAtcPending._();
  static const String _key = "atcPendingPayments";

  static Future<void> savePending(AtcPendingPayment pending)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    var list = List<String>.from(prefs.getStringList(_key) ?? []);
    list.removeWhere((element) => _refOf(element) == pending.ref);
    list.add(jsonEncode(pending.toJson()));
    await prefs.setStringList(_key, list);
  }
  static Future<List<AtcPendingPayment>> getPending()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    List<AtcPendingPayment> pending = [];
    for (var element in prefs.getStringList(_key) ?? <String>[]) {
      try {
        pending.add(AtcPendingPayment.fromJson(jsonDecode(element)));
      } catch (_) {}
    }
    return pending;
  }
  static Future<void> removePending(String ref)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    var list = List<String>.from(prefs.getStringList(_key) ?? []);
    list.removeWhere((element) => _refOf(element) == ref);
    await prefs.setStringList(_key, list);
  }

  static String? _refOf(String element) {
    try {
      var json = jsonDecode(element);
      return json is Map ? json["ref"] : null;
    } catch (_) {
      return null;
    }
  }
}
