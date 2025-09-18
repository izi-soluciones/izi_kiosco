import 'package:izi_kiosco/domain/dto/add_kiosk_dto.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
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
  Future<User> getCurrentUserById(String idUser)async {
    throw "error";
  }

  @override
  Future<List<Device>> getDevicesByContribuyente(int idContribuyente) {
    // TODO: implement getDevicesByContribuyente
    throw UnimplementedError();
  }

  @override
  Future<void> disableDevice(int idDevice) {
    // TODO: implement disableDevice
    throw UnimplementedError();
  }

  @override
  Future<void> enableDevice(int idDevice) {
    // TODO: implement enableDevice
    throw UnimplementedError();
  }

  @override
  Future<void> addDevice(AddKioskDto addKioskDto) {
    // TODO: implement addDevice
    throw UnimplementedError();
  }

  @override
  Future<List<Sucursal>> getSucursales(int idContribuyente) {
    // TODO: implement getSucursales
    throw UnimplementedError();
  }
  
  @override
  Future<Device> getDevice(int deviceId) {
    // TODO: implement getDevice
    throw UnimplementedError();
  }


}