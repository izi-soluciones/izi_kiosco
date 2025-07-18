import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/catalog.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/models/economic_activity.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/domain/models/payment_method.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
class BusinessRepositoryOffline extends BusinessRepository{
  final DioClient _dioClient = DioClient();


  @override
  Future<List<CashRegister>> getCashRegisters({required int contribuyenteId, required int sucursalId}) async{
    return [
      CashRegister(
          id: 2,
          nombre:"Caja",
          estado: true,
          userOpen: "",
          abierta: true)
    ];
  }

  @override
  Future<List<Currency>> getCurrencies({required int contribuyenteId}) async{
    return [Currency(
        id: 150,
        nombre: "",
        simbolo: "Bs",
        monedaReferencia: 151,
        exRate: 1,
        customData: {},
        contribuyente: 39942,
        exRatePrincipal: 1,
        monedaContribuyenteId: 1
    )];
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async{
    return [PaymentMethod(
        id: 1,
        nombre: "QR", codigoSiat: 1, custom: null,
    )];
  }

  @override
  Future<List<Payment>> getPayments({required int orderId}) async{
    return [Payment()];
  }

  @override
  Future<List<DocumentType>> getDocumentTypes() async{
    return [DocumentType(codigoClasificador: 3, descripcion: '')];
  }

  @override
  Future<List<EconomicActivity>> getEconomicActivities({required int contribuyenteId, required int sucursalId}) async{
    return [EconomicActivity(codigoCaeb: "3",descripcion: "",tipoActividad: "")];
  }

  @override
  Future<List<Contribuyente>> queryBusinessSearch({required String query, required int contribuyenteId}) async{
    return [Contribuyente(
        actividadesEconomicas: [],
        autorizadosAPI: [])];
  }


  @override
  Future<Catalog> getCatalog({required String id}) async{
    return Catalog(nombre: "", id: "", listaPrecio: "");
  }
}
