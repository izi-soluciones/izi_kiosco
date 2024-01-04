import 'package:shared_preferences/shared_preferences.dart';

class BusinessUtils{
  static Future<void> saveDeviceId(int id)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.setInt("deviceId", id);
  }
  static Future<int?> getDeviceId()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    int? sucursal=prefs.getInt("deviceId");
    return sucursal;
  }
  static Future<void> deleteDeviceId()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("deviceId");
  }
  static Future<void> saveSucursalId(int id)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();

    await prefs.setInt("sucursalId", id);
  }
  static Future<int?> getSucursalId()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    int? sucursal=prefs.getInt("sucursalId");
    return sucursal;
  }
  static Future<void> deleteSucursalId()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("sucursalId");
  }

  static Future<void> saveContribuyenteId(int id)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();

    await prefs.setInt("contribuyenteId", id);
  }
  static Future<int?> getContribuyenteId()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    int? contribuyente=prefs.getInt("contribuyenteId");
    return contribuyente;
  }
  static Future<void> deleteContribuyenteId()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("contribuyenteId");
  }

}