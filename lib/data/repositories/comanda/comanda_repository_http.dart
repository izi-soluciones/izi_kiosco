import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/domain/dto/filters_comanda.dart';
import 'package:izi_kiosco/domain/dto/invoice_dto.dart';
import 'package:izi_kiosco/domain/dto/new_order_dto.dart';
import 'package:izi_kiosco/domain/dto/paid_charge_dto.dart';
import 'package:izi_kiosco/domain/dto/payment_dto.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/category_order.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/domain/models/room.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/dto/internal_movement_dto.dart';

class ComandaRepositoryHttp extends ComandaRepository {
  final DioClient _dioClient = DioClient();

  @override
  Future<List<Comanda>> getComandas(
      {required FiltersComanda filters, required int page}) async {
    String path = "/comandas";
    var response = await _dioClient.get(
        uri: path,
        queryParameters: {
          "limit": "${AppConstants.paginationSize}",
          "offset": "${AppConstants.paginationSize * (page - 1)}",
          ...filters.toJson()
        },
        options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return List.from(response.data["items"])
          .map((e) => Comanda.fromJson(e))
          .toList();
    } else {
      throw response.data;
    }
  }

  @override
  Future<List<ConsumptionPoint>> getConsumptionPoints(
      int sucursal, int contribuyente,
      {String? roomId}) async {
    String path = "/puntos-consumo";
    var response = await _dioClient.get(
        uri: path,
        queryParameters: {
          "sucursal": sucursal,
          "limite": 500,
          if (roomId != null) "espacio": roomId
        },
        baseUrl: dotenv.env[EnvKeys.apiUrlPedidos],
        options: Options(
          headers: {
            "source": "izi-pedidos",
            "contribuyente": contribuyente,
            "sucursal": sucursal
          },
          responseType: ResponseType.json,
        ));
    if (response.statusCode == 200) {
      (response.data as List)
          .removeWhere((element) => element["eliminado"] == true);
      return List.from(response.data)
          .map((e) => ConsumptionPoint.fromJson(e))
          .toList();
    } else {
      throw response.data;
    }
  }

  @override
  Future<Comanda> getComanda({required int orderId}) async {
    String path = "/comandas/$orderId";
    var response = await _dioClient.get(
        uri: path, options: Options(responseType: ResponseType.json));
    if (response.statusCode == 200) {
      return Comanda.fromJson(response.data);
    } else {
      if (response.data?["status"] ?? false) {
        throw response.data?["data"];
      }
    }
    throw response.data;
  }
  @override
  Future<Invoice> invoicePreOrder({required InvoiceDto invoice, required int orderId}) async {
    try {
      String path = "/comandas/pre-comanda/$orderId/facturar";
      var response = await _dioClient.post(
          uri: path,
          body: invoice.toJson(),
          options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200) {
        return Invoice.fromJson(response.data);
      }
      else{
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
  Future<void> emit({required InvoiceDto invoice, required int orderId}) async {
    try {
      String path = "/comandas/$orderId/facturar";
      var response = await _dioClient.put(
          uri: path,
          body: invoice.toJson(),
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
  Future<void> emitContingencia(
      {required InvoiceDto invoice, required int orderId}) async {
    String path = "/comandas/$orderId/facturar-contingencia";
    var response = await _dioClient.put(
        uri: path,
        body: invoice.toJson(),
        options: Options(responseType: ResponseType.json));
    if (response.statusCode != 200) {
      if (response.data?["status"] ?? false) {
        throw response.data?["data"];
      }
      throw response.data;
    }
  }

  @override
  Future<Payment> addPayment(
      {required Payment payment,
      required int orderId,
      required int contribuyente}) async {
    try {
      String path = "/comandas/$orderId/pagos";
      var response = await _dioClient.post(
          uri: path,
          body: payment.toJson(contribuyente),
          options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200) {
        return Payment.fromJson(response.data);
      }
      if (response.data?["status"] ?? false) {
        throw response.data?["data"];
      }
      throw response.data;
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
  Future<void> removePayment({required int paymentId}) async {
    try {
      String path = "/pagos-a-contribuyente/$paymentId";
      var response = await _dioClient.delete(
          uri: path, options: Options(responseType: ResponseType.json));
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
  Future<Charge> generatePayment(
      {required int contribuyenteId, required PaymentDto payment}) async {
    try {
      String path = "/solicitudes-cobro";
      var response = await _dioClient.post(
          uri: path,
          body: payment.toJson(contribuyenteId),
          options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Charge.fromJson(response.data);
      }
      if (response.data?["status"] ?? false) {
        throw response.data?["data"];
      }
      throw response.data;
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
  Future<List<Room>> getRooms(int sucursal, int contribuyente) async {
    try {
      String path = "/espacios";
      var response = await _dioClient.get(
          uri: path,
          queryParameters: {"sucursal": sucursal, "limite": 500},
          baseUrl: dotenv.env[EnvKeys.apiUrlPedidos],
          options: Options(
            headers: {
              "source": "izi-pedidos",
              "contribuyente": contribuyente,
              "sucursal": sucursal
            },
            responseType: ResponseType.json,
          ));
      if (response.statusCode == 200) {
        (response.data as List)
            .removeWhere((element) => element["eliminado"] == true);
        return List.from(response.data).map((e) => Room.fromJson(e)).toList();
      } else {
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
  Future<void> freeConsumptionPoint(
      {required String id,
      required int sucursal,
      required int contribuyente}) async {
    try {
      String path = "/puntos-consumo";
      var response = await _dioClient.put(
          uri: path,
          queryParameters: {
            "id": id,
          },
          body: {"estado": "libre", "pedidoActivo": {}},
          baseUrl: dotenv.env[EnvKeys.apiUrlPedidos],
          options: Options(
            headers: {
              "source": "izi-pedidos",
              "contribuyente": contribuyente,
              "sucursal": sucursal
            },
            responseType: ResponseType.json,
          ));
      if (response.statusCode != 200) {
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
  Future<void> cancelOrder({required int orderId}) async {
    try {
      String path = "/comandas/$orderId/anular";
      var response = await _dioClient.put(
          uri: path,
          options: Options(responseType: ResponseType.json),
          body: {});
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
  Future<void> markInternal(
      {required InternalMovementDto internalMovementDto}) async {
    try {
      String path =
          "/comandas/${internalMovementDto.comandaId}/consumo-interno";
      var response = await _dioClient.put(
          uri: path,
          options: Options(responseType: ResponseType.json),
          body: internalMovementDto.toJson());
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
  Future<List<CategoryOrder>> getCategories(
      {required int sucursal, required int contribuyente}) async {
    try {
      String path =
          "/contribuyentes/$contribuyente/sucursales/$sucursal/inventario/recetas/categorias";
      var response = await _dioClient.get(
          uri: path,
          options: Options(responseType: ResponseType.json),
          queryParameters: {"habilitadoKiosco": 1});
      if (response.statusCode == 200) {
        return List.from(response.data)
            .map((e) => CategoryOrder.fromJson(e))
            .toList();
      } else {
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
  Future<Comanda> emitOrder({required NewOrderDto newOrder}) async {
    try {
      String path = "/comandas";
      var response = await _dioClient.post(
          uri: path,
          options: Options(responseType: ResponseType.json),
          body: newOrder.toJson());
      if (response.statusCode == 200) {
        return Comanda.fromJson(response.data);
      } else {
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
  Future<Comanda> emitOrderPre({required NewOrderDto newOrder}) async {
    try {
      String path = "/comandas/pre-comanda/emitir";
      var response = await _dioClient.post(
          uri: path,
          options: Options(responseType: ResponseType.json),
          body: newOrder.toJson());
      if (response.statusCode == 200) {
        return Comanda.fromJson(response.data);
      } else {
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
  Future<Comanda> editOrder({required NewOrderDto newOrder}) async {
    try {
      String path = "/comandas/${newOrder.id}";
      var response = await _dioClient.put(
          uri: path,
          options: Options(responseType: ResponseType.json),
          body: newOrder.toJsonEdit());
      if (response.statusCode == 200) {
        if ((response.data is Map) &&
            (response.data as Map)["comanda"] != null) {
          return Comanda.fromJson(response.data["comanda"]);
        } else {
          throw response.data;
        }
      } else {
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
  Future<CardPayment> callCardPayment({required int amount,required String ip}) async{
    try {
      String path = "/sale";
      var response = await _dioClient.get(
          uri: path,
          baseUrl: "http://$ip:8000",
          queryParameters: {
            "monto": amount.toString(),
            "cod_moneda": "068"
          },
          options: Options(responseType: ResponseType.json,receiveTimeout: const Duration(seconds: 60),sendTimeout: const Duration(seconds: 60)));
    if (response.statusCode == 200) {
        if(response.data is String){
          var res=jsonDecode(response.data);
          if(res["estado"]=="False"){
            return CardPayment.fromJson(res);
          }
          throw response.data;
        }
        throw response.data;
      } else {
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
  Future<Comanda> markAsCreated(int orderId) async{
    try {
      String path =
          "/comandas/pre-comanda/$orderId/crear";
      var response = await _dioClient.post(
          uri: path,
          options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200) {
        return Comanda.fromJson(response.data);
      }
      else{
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
  Future<Invoice> getInvoice(int invoiceId) async{
    try {
      String path =
          "/facturas/$invoiceId";
      var response = await _dioClient.get(
          uri: path,
          options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200 && response.data is Map && response.data["factura"]!=null) {
        return Invoice.fromJson(response.data["factura"]);
      }
      else{
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
  Future<void> createPaidCharge(PaidChargeDto paidChargeDto) async{
    try {
      String path =
          "/solicitudes-cobro/cobro-pagado";
      var response = await _dioClient.post(
          uri: path,
          body: paidChargeDto.toJson(),
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
  Future<CardPayment> callCardPaymentATC({required String amount,required String ip,required bool contactless}) async{
    try {
      String path;
      if(contactless){
        path = "/v2/ctl/$ip/$amount/0";
      }
      else{
        path = "/v2/chip/$ip/$amount/0";
      }
      var response = await _dioClient.get(
          uri: path,
          baseUrl: dotenv.env[EnvKeys.atcServerPOS],
          options: Options(responseType: ResponseType.json,receiveTimeout: const Duration(seconds: 60),sendTimeout: const Duration(seconds: 60)));
      if (response.statusCode == 200) {
        if(response.data is String){
          var res=jsonDecode(response.data);
          if(res["status"]==true && res["data"]!=null){
            return CardPayment.fromJsonATC(res["data"]);
          }
          throw response.data;
        }
        throw response.data;
      } else {
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
  Future<void> markPaymentATC(String token, String chargeUuid) async{
    try {
      String path =
          "/solicitudes-cobro/$chargeUuid/notificacion-pos";
      var response = await _dioClient.post(
          uri: path,
          body: {
            "token":token
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
}
