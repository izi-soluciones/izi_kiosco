import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageCardErrors{
  LocalStorageCardErrors._();
  static Future<void> saveCardErrors(String error)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    var errors = prefs.getStringList("cardErrors") ?? [];
    errors.add(error);
    await prefs.setStringList("cardErrors", errors);
  }
  static Future<List<String>> getErrors()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    return prefs.getStringList("cardErrors") ?? [];
  }

  /// Replaces the stored record whose `referencia` is [reference] with
  /// [record] (JSON). Returns false when no record carries that reference.
  static Future<bool> updateByReference(String reference, String record) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final errors = prefs.getStringList("cardErrors") ?? [];
    for (var i = errors.length - 1; i >= 0; i--) {
      try {
        final json = jsonDecode(errors[i]);
        if (json is Map && json["referencia"] == reference) {
          errors[i] = record;
          await prefs.setStringList("cardErrors", errors);
          return true;
        }
      } catch (_) {
        // Skip unreadable entries.
      }
    }
    return false;
  }
}
