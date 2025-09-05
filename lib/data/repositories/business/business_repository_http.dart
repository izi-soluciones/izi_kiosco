import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/catalog.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/customer.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/models/economic_activity.dart';
import 'package:izi_kiosco/domain/models/identification_type.dart';
import 'package:izi_kiosco/domain/models/iva_responsability.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/payment_method.dart';
import 'package:izi_kiosco/domain/models/person_type.dart';
import 'package:izi_kiosco/domain/models/tax_responsability.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
class BusinessRepositoryHttp extends BusinessRepository{
  final DioClient _dioClient = DioClient();


  @override
  Future<List<CashRegister>> getCashRegisters({required int contribuyenteId, required int sucursalId}) async{
    String path = "/contribuyentes/$contribuyenteId/sucursales/$sucursalId/cajas";
    var response = await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json,headers: {
          "Izi-Sucursal":sucursalId
        }));
    if (response.statusCode == 200) {
      return List.from(response.data)
          .map((e) => CashRegister.fromJson(e))
          .toList();
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<List<Currency>> getCurrencies({required int contribuyenteId}) async{
    String path = "/monedas-contribuyente";
    var response = await _dioClient.get(
        uri: path,
        queryParameters: {
          "contribuyente": contribuyenteId
        },
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return List.from(response.data)
          .map((e) => Currency.fromJson(e))
          .toList();
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async{
    String path = "/metodos-pago";
    var response = await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return List.from(response.data)
          .map((e) => PaymentMethod.fromJson(e))
          .toList();
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<List<Payment>> getPayments({required int orderId}) async{
    String path = "/comandas/$orderId/pagos";
    var response = await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return List.from(response.data)
          .map((e) => Payment.fromJson(e))
          .toList();
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<List<DocumentType>> getDocumentTypes() async{
    String path = "/integraciones/6/parametros/tipos-documento-identidad";
    var response = await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return List.from(response.data["datos"])
          .map((e) => DocumentType.fromJson(e))
          .toList();
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<List<EconomicActivity>> getEconomicActivities({required int contribuyenteId, required int sucursalId}) async{
    String path = "/integraciones/6/parametros/actividades-economicas";
    var response = await _dioClient.get(
        uri: path,
        queryParameters: {
          "contribuyenteId": contribuyenteId,
          "sucursalId": sucursalId
        },
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      if(response.data is Iterable){
        return List.from(response.data)
            .map((e) => EconomicActivity.fromJson(e))
            .toList();
      }
      else{
        return [EconomicActivity.fromJson(response.data)];
      }
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<List<Customer>> queryBusinessSearch({required String query, required int contribuyenteId}) async{
    String path = "/nit";
    var response = await _dioClient.get(
        uri: path,
        queryParameters: {
          "contribuyente": contribuyenteId,
          "nit": query
        },
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
        return List.from(response.data)
            .map((e) => Customer.fromJson(e))
            .toList();
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<void> askHelp(int sucursal,String nombre) async{
    try {
      String path =
          "/custom/ayuda-kiosko";
      var response = await _dioClient.post(
          uri: path,
          body: {
            "sucursal":sucursal,
            "nombre": nombre
          },
          options: Options(responseType: ResponseType.json));
      if (response.statusCode != 200) {
        if (response.data?["status"] ?? false) {
          throw response.data?["data"];
        }
        throw response.data;
      }
    } on DioException catch (e) {
      if (e.response?.data is String) {
        throw e.response?.data;
      }
      throw e.error ?? "Network Error";
    } catch (error) {
      throw error.toString();
    }
  }

  @override
  Future<bool> verifyConnectionPos() async{
    String path = "/verify-connection";
    var response = await _dioClient.get(
        uri: path,
        baseUrl: dotenv.env["ATC_SERVER_URL"],
        options: Options(responseType: ResponseType.json,));
    if (response.statusCode == 200) {
      return response.data is Map && response.data["connection"] ==true?true:false;
    } else {
      throw response.data;
    }
  }

  @override
  Future<Catalog> getCatalog({required String id}) async{
    String path = "/catalogos/$id";
    var response = await _dioClient.get(
        uri: path,
        queryParameters: {
          "categorias": true,
        },
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return Catalog.fromJson(response.data ?? {});
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<List<IdentificationType>> getIdentificationType()async {
    String path = "/integraciones/12/parametros/tipos-identificacion";
    var response = await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return List.from(response.data["datos"])
          .map((e) => IdentificationType.fromJson(e))
          .toList();
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<List<IvaResponsability>> getIvaResponsability() async{
    String path = "/integraciones/12/parametros/responsabilidades-iva";
    var response = await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return List.from(response.data["datos"])
          .map((e) => IvaResponsability.fromJson(e))
          .toList();
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<List<PersonType>> getPersonType() async{
    String path = "/integraciones/12/parametros/tipos-persona";
    var response = await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return List.from(response.data["datos"])
          .map((e) => PersonType.fromJson(e))
          .toList();
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }

  @override
  Future<List<TaxResponsability>> getTaxResponsability() async{
    String path = "/integraciones/12/parametros/responsabilidades-fiscales";
    var response = await _dioClient.get(
        uri: path,
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return List.from(response.data["datos"])
          .map((e) => TaxResponsability.fromJson(e))
          .toList();
    } else {
      if(response.data?["status"] ?? false){
        throw response.data?["data"];
      }
    }
    throw response.data;
  }
}
