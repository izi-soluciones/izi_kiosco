import 'package:izi_kiosco/domain/models/user.dart';

class LoginResponse{
  String token;
  User user;
  LoginResponse({required this.user,required this.token});

  factory LoginResponse.fromJson(Map<String,dynamic> json)=>
      LoginResponse(
          user: User.fromJson(json["usuario"]),
          token: json["token"]
      );
}