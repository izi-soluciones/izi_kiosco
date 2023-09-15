

import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/login/login_request.dart';
import 'package:izi_kiosco/domain/models/login/login_response.dart';
import 'package:izi_kiosco/domain/models/user.dart';

abstract class AuthRepository{

  Future<List<Contribuyente>> getContribuyentes();
  Future<Contribuyente> getCurrentContribuyenteById(int idContribuyente);
  Future<User> getCurrentUserById(int idUser);

  Future<LoginResponse> login(LoginRequest loginRequest);

}