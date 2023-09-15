import 'package:shared_preferences/shared_preferences.dart';

class TokenUtils{
  static Future<void> saveToken(String token)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }
  static Future<String?> getToken()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String? token=prefs.getString("token");
    return token;
  }
  static Future<void> deleteToken()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}