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
}