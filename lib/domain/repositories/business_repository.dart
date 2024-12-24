import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/models/economic_activity.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/payment_method.dart';

abstract class BusinessRepository{

  Future<List<CashRegister>> getCashRegisters({required int contribuyenteId,required int sucursalId});
  Future<List<Currency>> getCurrencies({required int contribuyenteId});
  Future<List<Payment>> getPayments({required int orderId});
  Future<List<PaymentMethod>> getPaymentMethods();
  Future<List<DocumentType>> getDocumentTypes();
  Future<List<EconomicActivity>> getEconomicActivities({required int contribuyenteId,required int sucursalId});
  Future<List<Contribuyente>> queryBusinessSearch({required String query, required int contribuyenteId});
  Future<void> askHelp(int sucursal,String nombre);
}