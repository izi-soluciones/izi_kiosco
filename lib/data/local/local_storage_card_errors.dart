import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageCardErrors{
  LocalStorageCardErrors._();
  static Future<void> saveCardErrors(String error) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var errors = prefs.getStringList("cardErrors") ?? [];

    errors.add(error);

    // Mantener solo los últimos 100
    if (errors.length > 50) {
      errors = errors.sublist(errors.length - 50);
    }

    await prefs.setStringList("cardErrors", errors);
  } catch (_) {}
}
  static Future<List<String>> getErrors()async{
    try{
      SharedPreferences prefs=await SharedPreferences.getInstance();
      return prefs.getStringList("cardErrors") ?? [];
    }
    catch(_){return [];}
  }
}