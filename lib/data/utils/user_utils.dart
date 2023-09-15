import 'dart:convert';
import 'package:izi_kiosco/domain/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserUtils{
  static Future<void> saveUser(User user)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    
    await prefs.setString("user", jsonEncode(user.toJson()));
  }
  static Future<User?> getUser()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String? user=prefs.getString("user");
    if(user==null){
      return null;
    }
    return User.fromJson(jsonDecode(user));
  }
  static Future<void> deleteUser()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("user");
  }
}