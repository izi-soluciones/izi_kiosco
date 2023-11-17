import 'package:izi_kiosco/domain/dto/filters_comanda.dart';
import 'package:izi_kiosco/domain/dto/invoice_dto.dart';
import 'package:izi_kiosco/domain/dto/new_order_dto.dart';
import 'package:izi_kiosco/domain/dto/qr_dto.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/category_order.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/domain/models/room.dart';
import 'package:izi_kiosco/domain/dto/internal_movement_dto.dart';

abstract class ComandaRepository{

  Future<List<Comanda>> getComandas({required FiltersComanda filters,required int page});
  Future<Comanda> getComanda({required int orderId});
  Future<void> emit({required InvoiceDto invoice,required int orderId});
  Future<void> emitContingencia({required InvoiceDto invoice,required int orderId});
  Future<Payment> addPayment({required Payment payment,required int orderId,required int contribuyente});
  Future<void> removePayment({required int paymentId});
  Future<Charge> generateQr({required int contribuyenteId, required QrDto qr});
  Future<void> markInternal({required InternalMovementDto internalMovementDto});
  Future<List<CategoryOrder>> getCategories({required int sucursal,required int contribuyente});


  Future<List<ConsumptionPoint>> getConsumptionPoints(int sucursal, int contribuyente,{String? roomId});
  Future<List<Room>> getRooms(int sucursal, int contribuyente);
  Future<void> freeConsumptionPoint({required String id,required int sucursal,required int contribuyente});

  Future<void> cancelOrder({required int orderId});
  Future<Comanda> emitOrder({required NewOrderDto newOrder});
  Future<Comanda> emitOrderPre({required NewOrderDto newOrder});
  Future<Comanda> editOrder({required NewOrderDto newOrder});
  Future<void> invoicePreOrder({required InvoiceDto invoice,required int orderId});

  Future<CardPayment> callCardPayment({required int amount});


}