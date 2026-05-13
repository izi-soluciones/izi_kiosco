import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:dio/dio.dart';
//import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/dto/filters_comanda.dart';
import 'package:izi_kiosco/domain/dto/invoice_dto.dart';
import 'package:izi_kiosco/domain/dto/new_order_dto.dart';
import 'package:izi_kiosco/domain/dto/new_sale_link_dto.dart';
import 'package:izi_kiosco/domain/dto/paid_charge_dto.dart';
import 'package:izi_kiosco/domain/dto/payment_attempt_dto.dart';
import 'package:izi_kiosco/domain/dto/payment_dto.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/category_order.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/domain/models/room.dart';
import 'package:izi_kiosco/domain/models/sale_link.dart';
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
  Future<List<Item>> getSaleItems(
      {String? catalog,
      required bool sortByPriority,
      List<String>? items}) async {
    String path = "/items-inventarios";
    var response = await _dioClient.get(
        uri: path,
        queryParameters: {
          if (catalog != null) "catalogo": catalog,
          if (items != null) "listaItemsIds": items,
          if (items == null) "habilitadoKiosco": true,
          "seVende": true,
          if (sortByPriority) "sortPrioridadKiosco": sortByPriority,
        },
        options: Options(
          responseType: ResponseType.json,
        ));
    if (response.statusCode == 200) {
      List<Item> list =
          List.from(response.data).map((e) => Item.fromJson(e)).toList();
      return list;
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
  Future<Comanda> getComanda({required String orderUuid}) async {
    String path = "/comandas/uuid/$orderUuid";
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
  Future<Invoice> invoicePreOrder(
      {required InvoiceDto invoice, required int orderId}) async {
    try {
      String path = "/comandas/pre-comanda/$orderId/facturar";
      var response = await _dioClient.post(
          uri: path,
          body: invoice.toJson(),
          options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200) {
        return Invoice.fromJson(response.data);
      } else {
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
  Future<SaleLink> createSaleLink(NewSaleLinkDto newSaleLinkDto) async {
    try {
      String path = "/solicitudes-cobro/enlace-kiosko";
      //final tokenCaptcha =await FirebaseAppCheck.instance.getLimitedUseToken();
      var response = await _dioClient.post(
          uri: path,
          body: newSaleLinkDto.toJson(),
          options: Options(responseType: ResponseType.json,headers: {
            //"X-Firebase-AppCheck": tokenCaptcha
          }));
      if (response.statusCode == 200) {
        return SaleLink.fromJson(response.data);
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
      String path = "/solicitudes-cobro/kiosko";
      //final tokenCaptcha =await FirebaseAppCheck.instance.getLimitedUseToken();
      var response = await _dioClient.post(
          uri: path,
          body: payment.toJson(contribuyenteId),
          options: Options(responseType: ResponseType.json,headers: {
            //"X-Firebase-AppCheck": tokenCaptcha
          }),);
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
      String path = "/categorias";
      var response = await _dioClient.get(
          uri: path,
          options: Options(responseType: ResponseType.json));
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
      String path = "/comandas/pre-comanda/emitir-public";
      //final tokenCaptcha =await FirebaseAppCheck.instance.getLimitedUseToken();
      var response = await _dioClient.post(
          uri: path,
          options: Options(responseType: ResponseType.json,headers: {
            //"X-Firebase-AppCheck": tokenCaptcha
          }),
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
  Future<Charge> generatePaymentAttempt(
      PaymentAttemptDto paymentAttemptDto) async {
    try {
      String path = "/solicitudes-cobro/intento-pago-kiosko";
      //final tokenCaptcha =await FirebaseAppCheck.instance.getLimitedUseToken();
      var response = await _dioClient.post(
          uri: path,
          options: Options(responseType: ResponseType.json,headers: {
            //"X-Firebase-AppCheck": tokenCaptcha
          }),
          body: paymentAttemptDto.toJson());
      if (response.statusCode == 200) {
        return Charge.fromJsonAttempt(response.data, paymentAttemptDto.uuid);
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
  Future<CardPayment> callCardPayment(
      {required int amount, required String ip}) async {
    try {
      String path = "/sale";
      var response = await _dioClient.get(
          uri: path,
          baseUrl: "http://$ip:8000",
          queryParameters: {"monto": amount.toString(), "cod_moneda": "068"},
          options: Options(
              responseType: ResponseType.json,
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 60)));
      if (response.statusCode == 200) {
        if (response.data is String) {
          var res = jsonDecode(response.data);
          if (res["estado"] == "False") {
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
  Future<Comanda> markAsCreated(String orderUuid) async {
    try {
      String path = "/comandas/pre-comanda-uuid/$orderUuid/crear";
      //final tokenCaptcha =await FirebaseAppCheck.instance.getLimitedUseToken();
      var response = await _dioClient.post(
          uri: path, 
          options: Options(responseType: ResponseType.json,headers: {
            //"X-Firebase-AppCheck": tokenCaptcha
          }));
      if (response.statusCode == 200) {
        return Comanda.fromJson(response.data);
      } else {
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
  Future<Invoice> getInvoice(String invoiceUuid) async {
    try {
      String path = "/facturas/uuid/$invoiceUuid";
      var response = await _dioClient.get(
          uri: path, options: Options(responseType: ResponseType.json));
      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data["factura"] != null) {
        return Invoice.fromJson(response.data["factura"]);
      } else {
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
  Future<void> createPaidCharge(PaidChargeDto paidChargeDto) async {
    try {
      String path = "/solicitudes-cobro/cobro-pagado";
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
  Future<CardPayment> callCardPaymentATC(
      {required String amount,
      required String ip,
      required CancelToken cancelToken,
      required bool contactless}) async {
    try {
      String path;
      if (contactless) {
        path = "/v2/ctl/$ip/$amount/0";
      } else {
        path = "/v2/chip/$ip/$amount/0";
      }
      var response = await _dioClient.get(
          uri: path,
          cancelToken: cancelToken,
          baseUrl: dotenv.env[EnvKeys.atcServerPOS],
          options: Options(
              responseType: ResponseType.json,
              receiveTimeout: const Duration(seconds: 60),
              sendTimeout: const Duration(seconds: 60)));
      if (response.statusCode == 200) {
        var res = {};
        if (response.data is String) {
           res = jsonDecode(response.data);
        }
        if(response.data is Map){
          res = response.data;
        }
        if (res["status"] == true && res["data"] != null) {
          return CardPayment.fromJsonATC(res["data"]);
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
  Future<CardPayment> callCardPaymentIzify({required String amount, required String ipPort, required String token, required String currency, required String cardType, required int quotas}) async {
    try {
      final String reference = "KOS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
      
      final payloadStr = "$amount|$currency|$reference";
      final dataToHash = "$payloadStr|$token";
      final bytes = utf8.encode(dataToHash);
      final signature = sha256.convert(bytes).toString();

      final res = await http.post(
        Uri.parse('http://$ipPort/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          "amount": amount,
          "currency": currency,
          "reference": reference,
          "signature": signature,
          "cardType": cardType,
          "quotas": quotas,
          "sendTicket": 0
        })
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          if (res.body.isEmpty) {
            return CardPayment(
              response: "Aprobada", 
              cardNumber: "****",
              date: DateTime.now().toIso8601String().split('T').first,
              hour: DateTime.now().toIso8601String().split('T').last.substring(0, 5)
            );
          }
          final data = jsonDecode(res.body);
          if (data is Map && data["success"] != null && data["success"] == false) {
             throw data["message"] ?? "Transacción rechazada por el POS";
          }
          return CardPayment(
               response: "Aprobada", 
               cardNumber: data is Map ? (data["cardNumber"] ?? "****") : "****",
               date: DateTime.now().toIso8601String().split('T').first,
               hour: DateTime.now().toIso8601String().split('T').last.substring(0, 5)
          );
        } catch (e) {
          if (e is FormatException) {
            return CardPayment(
               response: "Aprobada", 
               cardNumber: "****",
               date: DateTime.now().toIso8601String().split('T').first,
               hour: DateTime.now().toIso8601String().split('T').last.substring(0, 5)
            );
          }
          rethrow;
        }
      }
      throw "Error procesando el pago en el POS: ${res.statusCode}";
    } catch (error) {
      throw error.toString();
    }
  }
  @override
  Future<void> markPaymentATC(String chargeUuid, int? internalId) async {
    try {
      String? token = await TokenUtils.getTokenCard();
      if(token==null){
        throw "No existe un token"; 
      }
      String path = "/solicitudes-cobro/$chargeUuid/notificacion-pos";
      var response = await _dioClient.post(
          uri: path,
          body: {
            "token": token,
            if (internalId != null) "internalId": internalId
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
  Future<void> cancelBrebKey({required int contribuyenteId, required String handle}) async {
    try {
      String path = "/contribuyentes/$contribuyenteId/integraciones/breb/cancelar";
      var response = await _dioClient.post(
          uri: path,
          body: {
            "handle": handle
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
  Future<void> cancelPaymentAttempt({required String uuid}) async {
    try {
      String path = "/solicitudes-cobro/intento-pago-kiosko/$uuid/cancelar";
      var response = await _dioClient.post(
          uri: path,
          body: {},
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
  Future<void> confirmDemoPaymentRetail({required int id}) async {
    try {
      String path = "/solicitudes-cobro/procesar-intento-demo/$id";
      var response = await _dioClient.post(
          uri: path,
          body: {},
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
  Future<void> confirmDemoPaymentOrder({required int id}) async {
    try {
      String path = "/solicitudes-cobro/procesar-cobro-demo/$id";
      var response = await _dioClient.post(
          uri: path,
          body: {},
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
