import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageRoom{
  LocalStorageRoom._();
  static Future<void> saveRoom(String room)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.setString("room", room);
  }
  static Future<String?> getRoom()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String? room=prefs.getString("room");
    return room;
  }
  static Future<void> deleteRoom()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("lsc");
  }
}