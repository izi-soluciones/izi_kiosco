import 'package:dio/dio.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/domain/models/pos.dart';
import 'package:izi_kiosco/domain/repositories/pos_repository.dart';

class PosRepositoryHttp extends PosRepository{
  final DioClient _dioClient = DioClient();
  @override
  Future<Pos?> getPos({required int contribuyente, required int sucursal})async {
    try{
      String path = "/terminales";
      var response = await _dioClient.get(
          uri: path,
          queryParameters: {
            "contribuyente" : contribuyente,
            "sucursal" : sucursal
          },
          options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200) {
        if(response.data is Map){
          return Pos.fromJson(response.data);
        }
        return null;
      } else {
        if(response.data?["status"] ?? false){
          throw response.data?["data"];
        }
      }
      throw response.data;
    }
    on DioException catch(e){
      if(e.response?.data is String){
        throw e.response?.data;
      }
      throw e.error ?? "Network Error";
    }
    catch(error){
      throw error.toString();
    }
  }
  @override
  Future<Pos> activatePos({required int contribuyente, required int sucursal,required bool isTest})async {
    try{
      String path = "/terminales/activar";
      var response = await _dioClient.post(
          uri: path,
          body: {
            "contribuyente" : contribuyente,
            "sucursal" : sucursal,
            "isPruebas": isTest
          },
          options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200) {
        return Pos.fromJson(response.data);
      } else {
        if(response.data?["status"] ?? false){
          throw response.data?["data"];
        }
      }
      throw response.data;
    }
    on DioException catch(e){
      if(e.response?.data is String){
        throw e.response?.data;
      }
      throw e.error ?? "Network Error";
    }
    catch(error){
      throw error.toString();
    }
  }

  @override
  Future<Pos> updateEnvironment({required int posId, required bool isTest}) async{
    try{
      String path = "/terminales/$posId";
      var response = await _dioClient.put(
          uri: path,
          body: {
            "isPruebas": isTest
          },
          options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200) {
        return Pos.fromJson(response.data);
      } else {
        if(response.data?["status"] ?? false){
          throw response.data?["data"];
        }
      }
      throw response.data;
    }
    on DioException catch(e){
      if(e.response?.data is String){
        throw e.response?.data;
      }
      throw e.error ?? "Network Error";
    }
    catch(error){
      throw error.toString();
    }
  }

}