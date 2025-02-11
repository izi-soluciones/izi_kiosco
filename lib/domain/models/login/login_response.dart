import 'package:izi_kiosco/domain/models/user.dart';

class LoginResponse{
  String token;
  String? refreshToken;
  User user;
  LoginResponse({required this.user,required this.token, required this.refreshToken});

  factory LoginResponse.fromJson(Map<String,dynamic> json)=>
      LoginResponse(
        user: User.fromJson(json["usuario"]),
        token: json["token"],
        refreshToken: json["refreshToken"],
      );
}