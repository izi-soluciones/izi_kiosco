import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
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
import 'package:uuid/uuid.dart';

const CE_COMBO_MEAL_ID = "combo_meal_id";
const CE_MENU_ITEM_ID = "menu_item_id";
const CE_CONDIMENT_ID = "condiment_id";
const CE_INTERNAL_NAME = "internal_name";
const CE_EXTRA_VARIABLE_ID = "extra_variable_id";
const NOMBRE_EXTRAS = "Extras";
const NOMBRE_SIN = "Personaliza Tu Combo";
const NOMBRE_SALSA = "Salsa";
const NOMBRE_SALSA_1 = "Salsa 1";
const NOMBRE_SALSA_2 = "Salsa 2";
class ComandaRepositoryOffline extends ComandaRepository {
  final DioClient _dioClient = DioClient();

  @override
  Future<List<Comanda>> getComandas(
      {required FiltersComanda filters, required int page}) async {
    return [Comanda(
        id: 1,
        comandasPdf: [],
        consumoInterno: false,
        creado: DateTime.now(),
        descuentos: 0,
        facturada: 0,
        fecha: DateTime.now(),
        isTerminada: false,
        listaItems: [],
        anulada: 0,
        monto: 0,
        paraLlevar: true)];
  }
  @override
  Future<List<Item>> getSaleItems(
  {required String catalog}) async {
    final String response = await rootBundle.loadString('assets/data/comanda_items_offline.json');
    final data = json.decode(response);
    return List.from(data).map((e) => Item.fromJson(e)).toList();
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
  Future<CardPayment> callCardPaymentATC({required String amount,required String ip,required bool contactless, required CancelToken cancelToken}) async{
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
          cancelToken: cancelToken,
          baseUrl: dotenv.env[EnvKeys.atcServerPOS],
          options: Options(responseType: ResponseType.json,receiveTimeout: const Duration(seconds: 300),sendTimeout: const Duration(seconds: 300)));
      if (response.statusCode == 200) {
        var res={};
        if(response.data is String){
          res=jsonDecode(response.data);
        }
        if(response.data is Map){
          res = response.data;
        }
        if(res["status"]==true && res["data"]!=null){
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
  Future<void> markPaymentATC(String token, String chargeUuid,int? internalId) async{
    try {
      String path =
          "/solicitudes-cobro/$chargeUuid/notificacion-pos";
      var response = await _dioClient.post(
          uri: path,
          body: {
            "token":token,
            if(internalId!=null) "internalId": internalId
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
  Future<Payment> addPayment({required Payment payment, required int orderId, required int contribuyente}) {
    // TODO: implement addPayment
    throw UnimplementedError();
  }
  
  @override
  Future<CardPayment> callCardPayment({required int amount, required String ip}) {
    // TODO: implement callCardPayment
    throw UnimplementedError();
  }
  
  @override
  Future<void> cancelOrder({required int orderId}) {
    // TODO: implement cancelOrder
    throw UnimplementedError();
  }
  
  @override
  Future<SaleLink> createSaleLink(NewSaleLinkDto newSaleLinkDto) {
    // TODO: implement createSaleLink
    throw UnimplementedError();
  }
  
  @override
  Future<Comanda> editOrder({required NewOrderDto newOrder}) {
    // TODO: implement editOrder
    throw UnimplementedError();
  }
  
  @override
  Future<void> emit({required InvoiceDto invoice, required int orderId}) {
    // TODO: implement emit
    throw UnimplementedError();
  }
  
  @override
  Future<void> emitContingencia({required InvoiceDto invoice, required int orderId}) {
    // TODO: implement emitContingencia
    throw UnimplementedError();
  }
  
  @override
  Future<Comanda> emitOrder({required NewOrderDto newOrder}) {
    // TODO: implement emitOrder
    throw UnimplementedError();
  }
  
  @override
  Future<Comanda> emitOrderPre({required NewOrderDto newOrder}) async{
    num montoTotal = 0;
    for(var i in newOrder.listaItems){
      montoTotal += i.cantidad*i.precioUnitario + i.precioModificadores;
    }
    return Comanda(
        id: 1,
        comandasPdf: [],
        consumoInterno: false,
        creado: DateTime.now(),
        descuentos: 0,
        facturada: 0,
        fecha: DateTime.now(),
        isTerminada: false,
        montoTotal: montoTotal,
        listaItems: newOrder.listaItems.map((e) => ItemComanda(
          nombre: e.nombre,
          cantidad: e.cantidad,
          precioUnitario: e.precioUnitario
          )).toList(),
        anulada: 0,
        monto: 0,
        paraLlevar: true);
  }
  
  @override
  Future<void> freeConsumptionPoint({required String id, required int sucursal, required int contribuyente}) {
    // TODO: implement freeConsumptionPoint
    throw UnimplementedError();
  }
  
  @override
  Future<Charge> generatePayment({required int contribuyenteId, required PaymentDto payment}) {
    // TODO: implement generatePayment
    throw UnimplementedError();
  }
  
  @override
  Future<Charge> generatePaymentAttempt(PaymentAttemptDto paymentAttemptDto) {
    // TODO: implement generatePaymentAttempt
    throw UnimplementedError();
  }
  
  @override
  Future<List<CategoryOrder>> getCategories({required int sucursal, required int contribuyente}) async{
    final String response = await rootBundle.loadString('assets/data/comanda_categories_offline.json');
    final data = json.decode(response);
    return List.from(data).map((e) => CategoryOrder.fromJson(e)).toList();
  }
  
  @override
  Future<Comanda> getComanda({required int orderId}) {
    // TODO: implement getComanda
    throw UnimplementedError();
  }
  
  @override
  Future<List<ConsumptionPoint>> getConsumptionPoints(int sucursal, int contribuyente, {String? roomId}) {
    // TODO: implement getConsumptionPoints
    throw UnimplementedError();
  }
  
  @override
  Future<List<Room>> getRooms(int sucursal, int contribuyente) {
    // TODO: implement getRooms
    throw UnimplementedError();
  }
  
  @override
  Future<Invoice> invoicePreOrder({required InvoiceDto invoice, required int orderId}) {
    // TODO: implement invoicePreOrder
    throw UnimplementedError();
  }
  
  @override
  Future<Comanda> markAsCreated(int orderId, {NewOrderDto? newOrder})async {

    if(newOrder==null){
      throw "Error newOrder";
    }

    final String response = await rootBundle.loadString('assets/data/credentials.json');
    final data = json.decode(response) as Map;
    String orgName = data["orgName"];
    String locRef = data["locRef"];
    String rvcRef = data["rvcRef"];
    int definitionSequence = data["definitionSequence"];
    int priceSequence = data["priceSequence"];
    int tenderId = data["tenderId"];
    int checkEmployeeRef = data["checkEmployeeRef"];
    int orderTypeRefLlevar = data["orderTypeRefLlevar"];
    int orderTypeRefAqui = data["orderTypeRefAqui"];

            List<dynamic> comboMeals = [];
            List<dynamic>  menuItems = [];
            for (var item in newOrder.listaItems) {
                if (item.customItem !=null && item.customItem["camposExtra"] !=null) {
                    dynamic comboMealId;
                    dynamic menuItemId;
                    dynamic internalName;
                    dynamic extraVariableId;
                    for (var ce in item.customItem["camposExtra"]) {
                        if (ce["titulo"] == CE_COMBO_MEAL_ID) {
                            comboMealId = ce["valor"];
                        }
                        if (ce["titulo"]  == CE_MENU_ITEM_ID) {
                            menuItemId = ce["valor"];
                        }
                        if (ce["titulo"]  == CE_INTERNAL_NAME) {
                            internalName = ce["valor"];
                        }
                        if (ce["titulo"]  == CE_EXTRA_VARIABLE_ID) {
                            extraVariableId = ce["valor"];
                        }

                    }
                    if (comboMealId!=null && menuItemId!=null) {
                        if (item.ingredientes.isEmpty) {
                          throw "Error ingredientes";
                        }

                        var mainItem = item.ingredientes[0];
                        dynamic mainItemMenuItem;
                        dynamic mainItemInternalName;
                        dynamic mainItemQuantity = 1;


                        if (mainItem.customItem["camposExtra"] !=null) {
                            for (var ce in mainItem.customItem["camposExtra"]) {
                                if (ce["titulo"] == CE_MENU_ITEM_ID) {
                                    mainItemMenuItem = ce["valor"];
                                }
                                if (ce["titulo"] == CE_INTERNAL_NAME) {
                                    mainItemInternalName = ce["valor"];
                                }
                            }
                        }
                        mainItemQuantity = mainItem.cantidad;

                        if (mainItemMenuItem ==null) {
                          throw "Error mainItemMenuItem";
                        }
                        List<dynamic>  sideItems = [];
                        List<dynamic>  condiments = [];
                          for (var mod in item.modificadores) {
                                for (var car in mod.caracteristicas) {
                                    if (car.check) {
                                        if (car.ingredientes.isEmpty) {
                                          throw "Error car.ingredientes";
                                        }


                                        var ingredienteCar = car.ingredientes[0];
                                        dynamic ingredienteCarMenuItem;
                                        dynamic ingredienteCarInternalName;
                                        dynamic ingredienteCarCondiment;
                                        if (ingredienteCar.customItem["camposExtra"]!=null) {
                                            for (var ce in ingredienteCar.customItem["camposExtra"]) {
                                                if (ce["titulo"] == CE_MENU_ITEM_ID) {
                                                    ingredienteCarMenuItem = ce["valor"];
                                                }
                                                if (ce["titulo"] == CE_INTERNAL_NAME) {
                                                    ingredienteCarInternalName = ce["valor"];
                                                }
                                                if (ce["titulo"] == CE_CONDIMENT_ID) {
                                                    ingredienteCarCondiment = ce["valor"];
                                                }
                                            }
                                        }
                                        if (mod.nombre == NOMBRE_EXTRAS || mod.nombre == NOMBRE_SIN || mod.nombre == NOMBRE_SALSA || mod.nombre == NOMBRE_SALSA_1 || mod.nombre == NOMBRE_SALSA_2) {
                                            if (ingredienteCarCondiment ==null) {
                                          throw "Error ingredienteCarCondiment";
                                            }
                                            var condiment =
                                            {
                                                "condimentId": ingredienteCarCondiment,
                                                "definitionSequence": definitionSequence,
                                                "name": ingredienteCarInternalName,
                                                "quantity": ingredienteCar.cantidad*item.cantidad,
                                                "unitPrice": car.modPrecio / ingredienteCar.cantidad,
                                                "priceSequence": priceSequence,
                                                "total": car.modPrecio,
                                                "seat": 1,
                                                "surcharge": 0
                                            };
                                            condiments.add(condiment);
                                        }
                                        else {
                                            if (ingredienteCarMenuItem==null) {
                                          throw "Error ingredienteCarMenuItem";
                                            }
                                            var sideItem =
                                            {
                                                "menuItemId": ingredienteCarMenuItem,
                                                "definitionSequence": definitionSequence,
                                                "name": ingredienteCarInternalName,
                                                "quantity": ingredienteCar.cantidad*item.cantidad,
                                                "unitPrice": car.modPrecio  / ingredienteCar.cantidad,
                                                "priceSequence": priceSequence,
                                                "total": car.modPrecio,
                                                "seat": 1,
                                                "surcharge": 0,
                                                "condiments": []
                                            };
                                            sideItems.add(sideItem);
                                        }

                                    }
                                }
                                                      }
                                              if(extraVariableId!=null){
                            var sideItem =
                            {
                                "menuItemId": extraVariableId,
                                "definitionSequence": definitionSequence,
                                "quantity": item.cantidad,
                                "unitPrice": 0,
                                "priceSequence": priceSequence,
                                "total":  0,
                                "seat": 1,
                                "surcharge": 0,
                                "condiments": []
                            };
                            sideItems.add(sideItem);
                        }
                        var itemCombo =
                        {
                            "comboMealId": comboMealId,
                            "seat": 1,
                            "comboItem": {
                                "menuItemId": menuItemId,
                                "definitionSequence": definitionSequence,
                                "name": internalName,
                                "quantity": item.cantidad,
                                "unitPrice": item.precioUnitario,
                                "priceSequence": priceSequence,
                                "total": item.cantidad * item.precioUnitario + item.precioModificadores,
                                "seat": 1,
                                "surcharge": 0,
                                "condiments": []
                            },
                            "mainItem": {
                                "menuItemId": mainItemMenuItem,
                                "definitionSequence": definitionSequence,
                                "name": mainItemInternalName,
                                "quantity": item.cantidad*mainItemQuantity,
                                "unitPrice": 0,
                                "priceSequence": priceSequence,
                                "total": 0,
                                "seat": 1,
                                "surcharge": 0,
                                "condiments": condiments
                            },
                            "sideItems": sideItems
                        };
                        comboMeals.add(itemCombo);
                    }
                    else if (menuItemId!=null) {
                        var menuItem = {
                            "menuItemId": menuItemId,
                            "definitionSequence": definitionSequence,
                            "name": internalName,
                            "quantity": item.cantidad,
                            "unitPrice": item.precioUnitario,
                            "priceSequence": priceSequence,
                            "total": item.cantidad * item.precioUnitario + item.precioModificadores,
                            "seat": 1,
                            "surcharge": 0,
                            "condiments": []
                        };
                        menuItems.add(menuItem);
                    }
                    else {
                      throw "Error item";
                    }
                }
            }
            if (comboMeals.isEmpty && menuItems.isEmpty) {
              throw "Error item vacio";
            }
            var uuid = const Uuid();
            var orden = {
                "header": {
                    "orgShortName": orgName,
                    "locRef": locRef,
                    "rvcRef": rvcRef,
                    "idempotencyId": uuid.v4().replaceAll('-', ''),
                    "checkEmployeeRef": checkEmployeeRef,
                    "orderTypeRef": newOrder.paraLlevar?orderTypeRefLlevar: orderTypeRefAqui
                },
                "menuItems": menuItems,
                "comboMeals": comboMeals,
                "discounts": [],
                "serviceCharges": [],
                "extensions": [],
                "taxes": [],
                "tenders": [
                    {
                        "tenderId": tenderId
                    }
                ]
            };

        
    Dio dio = new Dio();
    var res = await dio.post("https://mtu5-sts.oraclecloud.com/api/v1/checks",
    data: orden,
    options: Options(
      headers: {
        'Authorization': "Bearer ${data["token"]}",
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Simphony-OrgShortName': data["orgName"],
        'Simphony-LocRef': data["locRef"],
        'Simphony-RvcRef': data["rvcRef"]
      }
    ));
    return Comanda(
        id: 1,
        numero: 3,
        comandasPdf: [],
        consumoInterno: false,
        creado: DateTime.now(),
        descuentos: 0,
        facturada: 0,
        fecha: DateTime.now(),
        isTerminada: false,
        listaItems: [],
        anulada: 0,
        custom: {
          "simphony":res.data
          },
        monto: 0,
        paraLlevar: true);
        
  }
  
  @override
  Future<void> markInternal({required InternalMovementDto internalMovementDto}) {
    // TODO: implement markInternal
    throw UnimplementedError();
  }
  
  @override
  Future<void> removePayment({required int paymentId}) {
    // TODO: implement removePayment
    throw UnimplementedError();
  }
}
