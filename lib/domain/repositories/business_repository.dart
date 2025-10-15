import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/catalog.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
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

abstract class BusinessRepository{

  Future<List<CashRegister>> getCashRegisters({required int contribuyenteId,required int sucursalId});
  Future<List<Currency>> getCurrencies({required int contribuyenteId});
  Future<List<Payment>> getPayments({required int orderId});
  Future<List<PaymentMethod>> getPaymentMethods();
  Future<List<DocumentType>> getDocumentTypes();
  Future<List<EconomicActivity>> getEconomicActivities({required int contribuyenteId,required int sucursalId});
  Future<List<Customer>> queryBusinessSearch({required String query, required int contribuyenteId});
  Future<void> askHelp(int sucursal,String nombre);

  Future<bool> verifyConnectionPos();
  Future<Catalog> getCatalog({required String id});


  Future<List<IdentificationType>> getIdentificationType();

  Future<List<IvaResponsability>> getIvaResponsability();

  Future<List<PersonType>> getPersonType();

  Future<List<TaxResponsability>> getTaxResponsability();

}