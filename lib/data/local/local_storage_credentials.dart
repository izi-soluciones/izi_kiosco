import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart';

const String key='FoDnAl5OAUjXbpCSstdcyH2AHsDzZza0';

class CredentialStorage{
  String email;
  String password;

  CredentialStorage(this.email, this.password);
}
class LocalStorageCredentials{
  LocalStorageCredentials._();
  static Future<void> saveCredentials(String password,String email)async{

    SharedPreferences prefs=await SharedPreferences.getInstance();
    final keyValue = Key.fromUtf8(key);
    var text="$email,$password";
    final iv = IV.fromLength(16);
    final encrypt = Encrypter(AES(keyValue));
    final encrypted = encrypt.encrypt(text, iv: iv);
    await prefs.setString("lsc", encrypted.base64);
  }
  static Future<CredentialStorage?> getCredentials()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    String? lsc=prefs.getString("lsc");
    if(lsc!=null){
      final keyValue = Key.fromUtf8(key);
      final iv = IV.fromLength(16);
      final encrypt = Encrypter(AES(keyValue));
      final decrypted = encrypt.decrypt(Encrypted.fromBase64(lsc), iv: iv);
      final split=decrypted.split(",");
      if(split.length==2){
        return CredentialStorage(split[0], split[1]);
      }
      return null;
    }
    return null;
  }
  static Future<void> deleteCredentials()async{
    SharedPreferences prefs=await SharedPreferences.getInstance();
    await prefs.remove("lsc");
  }
}