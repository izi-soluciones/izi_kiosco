import 'package:izi_kiosco/app/values/app_constants.dart';

class QrDto {
  int orderId;
  DateTime date;
  num monto;
  int monedaId;
  String moneda;

  QrDto(
      {required this.orderId,
      required this.date,
      required this.monto,
      required this.moneda,
      required this.monedaId});

  Map<String,dynamic> toJson(int contribuyenteId)=>{
    "contribuyente": contribuyenteId,
    "pedido": orderId,
    "monto": monto,
    "moneda": moneda,
    "monedaId": monedaId,
    "metodoPago": AppConstants.idPaymentMethodQR,
    "config": {
      "notificarPagador":true,
      "desdeKiosco":true
    }
  };
}
