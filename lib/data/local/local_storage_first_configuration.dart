import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageFirstConfiguration{
  LocalStorageFirstConfiguration._();
  static Future<void> saveFirstConfiguration(bool firstConfiguration)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.setBool("fc", firstConfiguration);
  }
  static Future<bool?> getFirstConfiguration()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    bool? room=prefs.getBool("fc");
    return room;
  }
  static Future<void> deleteFirstConfiguration()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("fc");
  }
}