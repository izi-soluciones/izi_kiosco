import 'package:dio/dio.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/domain/dto/add_kiosk_dto.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/login/login_request.dart';
import 'package:izi_kiosco/domain/models/login/login_response.dart';
import 'package:izi_kiosco/domain/models/user.dart';
import 'package:izi_kiosco/domain/repositories/auth_repository.dart';

class AuthRepositoryHttp extends AuthRepository{
  final DioClient _dioClient = DioClient();

  @override
  Future<List<Contribuyente>> getContribuyentes() async{
    String path="/contribuyentes";
    var response=await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json)
    );
    if(response.statusCode==200)
    {
      return List.from(response.data["contribuyentes"]).map((e) => Contribuyente.fromJsonList(e)).toList();
    }
    else{
      throw response.data;
    }
  }
  @override
  Future<Contribuyente> getCurrentContribuyenteById(int idContribuyente) async{
    String path="/contribuyentes/$idContribuyente";
    var response=await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json)
    );
    if(response.statusCode==200)
    {
      return Contribuyente.fromJson(response.data["contribuyente"]);
    }
    else{
      throw response.data;
    }
  }
  @override
  Future<LoginResponse> login(LoginRequest loginRequest) async{
    String path="/login";
    var response=await _dioClient.post(
        uri: path,
        body: loginRequest.toJson(),
        options:Options(headers: {"no-auth":true},responseType: ResponseType.json)
    );
    if(response.statusCode==200)
      {
        return LoginResponse.fromJson(response.data);
      }
    else{
      throw response.data;
    }
  }

  @override
  Future<User> getCurrentUserById(int idUser)async {
    String path = "/usuarios/$idUser";
    var response=await _dioClient.get(
        uri: path,
        options:Options(responseType: ResponseType.json));
    if(response.statusCode==200)
    {
      return User.fromJson(response.data);
    }
    else{
      throw response.data;
    }

  }

  @override
  Future<List<Device>> getDevicesByContribuyente(int idContribuyente) async {
    try{

      String path="/dispositivos";
      var response=await _dioClient.get(
          uri: path,
          queryParameters: {
            "contribuyente":idContribuyente
          },
          options: Options(responseType: ResponseType.json)
      );
      if(response.statusCode==200)
      {
        return List.from(response.data).map((e) => Device.fromJson(e)).toList();
      }
      else{
        throw response.data;
      }
    }
    catch(e){
      throw(e.toString());
    }
  }

  @override
  Future<void> disableDevice(int idDevice) async {
    try{
      String path="/dispositivos/$idDevice/desactivar-uso";
      var response=await _dioClient.post(
          uri: path,
          options: Options(responseType: ResponseType.json)
      );
      if(response.statusCode!=200)
      {
        throw response.data;
      }
    }
    catch(e){
      throw(e.toString());
    }
  }

  @override
  Future<void> enableDevice(int idDevice)async {
    try{
      String path="/dispositivos/$idDevice/activar-uso";
      var response=await _dioClient.post(
          uri: path,
          options: Options(responseType: ResponseType.json)
      );
      if(response.statusCode!=200)
      {
        throw response.data;
      }
    }
    catch(e){
      throw(e.toString());
    }
  }

  @override
  Future<void> addDevice(AddKioskDto addKioskDto) async{
    try{
      String path="/dispositivos";
      var response=await _dioClient.post(
          uri: path,
          body: addKioskDto.toJson(),
          options: Options(responseType: ResponseType.json)
      );
      if(response.statusCode!=200)
      {
        throw response.data;
      }
    }
    catch(e){
      throw(e.toString());
    }
  }


}