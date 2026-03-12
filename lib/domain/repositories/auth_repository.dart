

import 'package:izi_kiosco/domain/dto/add_kiosk_dto.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/login/login_request.dart';
import 'package:izi_kiosco/domain/models/login/login_response.dart';
import 'package:izi_kiosco/domain/models/user.dart';

abstract class AuthRepository{

  Future<List<Contribuyente>> getContribuyentes();
  Future<Contribuyente> getCurrentContribuyenteById(int idContribuyente);
  Future<List<Sucursal> > getSucursales(int idContribuyente);
  Future<User> getCurrentUserById(String idUser);
  Future<Device> getDevice();
  Future<List<Device>> getDevicesByContribuyente(int idContribuyente);

  Future<void> enableDevice(int idDevice);
  Future<void> disableDevice(int idDevice);
  Future<void> addDevice(AddKioskDto addKioskDto);

  Future<LoginResponse> login(LoginRequest loginRequest);
  
  Future<String> createKioskSession();
  Future<Map<String, dynamic>> pollKioskSession(String sessionId);

}