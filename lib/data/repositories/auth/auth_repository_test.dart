import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/login/login_request.dart';
import 'package:izi_kiosco/domain/models/login/login_response.dart';
import 'package:izi_kiosco/domain/models/user.dart';
import 'package:izi_kiosco/domain/repositories/auth_repository.dart';

class AuthRepositoryTest extends AuthRepository{

  @override
  Future<List<Contribuyente>> getContribuyentes() async{
    throw "error";
  }
  @override
  Future<Contribuyente> getCurrentContribuyenteById(int idContribuyente) async{
    throw "error";
  }
  @override
  Future<LoginResponse> login(LoginRequest loginRequest) async{
    throw "error";
  }

  @override
  Future<User> getCurrentUserById(int idUser)async {
    throw "error";
  }


}