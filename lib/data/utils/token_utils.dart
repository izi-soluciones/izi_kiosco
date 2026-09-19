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

  static Future<void> saveRefreshToken(String token)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.setString("rt", token);
  }
  static Future<String?> getRefreshToken()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String? token=prefs.getString("rt");
    return token;
  }
  static Future<void> deleteRefreshToken()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("rt");
  }


  static Future<void> saveTokenCard(String token)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.setString("tokenCard", token);
  }
  static Future<String?> getTokenCard()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String? token=prefs.getString("tokenCard");
    return token;
  }
  static Future<void> deleteTokenCard()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("tokenCard");
  }

  static Future<void> savePosIp(String ip)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.setString("posIp", ip);
  }
  static Future<String?> getPosIp()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String? ip=prefs.getString("posIp");
    return ip;
  }
  static Future<void> deletePosIp()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("posIp");
  }

  static Future<void> savePosToken(String token)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.setString("posToken", token);
  }
  static Future<String?> getPosToken()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String? token=prefs.getString("posToken");
    return token;
  }
  static Future<void> deletePosToken()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("posToken");
  }

  /// The paired terminal's mDNS name (`izify-POS-<pin>`), used to find it
  /// again when it moves to another IP.
  static Future<void> savePosName(String name)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.setString("posName", name);
  }
  static Future<String?> getPosName()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    return prefs.getString("posName");
  }
  static Future<void> deletePosName()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("posName");
  }

  /// The backend `ipEcopay` this kiosk last paired with. A backend value
  /// equal to it is not followed again, so a terminal the kiosk found at a
  /// new address is not abandoned for the stale backend one.
  static Future<void> savePosBackendIp(String ip)async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.setString("posBackendIp", ip);
  }
  static Future<String?> getPosBackendIp()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    return prefs.getString("posBackendIp");
  }
  static Future<void> deletePosBackendIp()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("posBackendIp");
  }
}
