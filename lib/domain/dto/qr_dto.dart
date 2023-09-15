import 'package:izi_kiosco/domain/utils/date_formatter.dart';

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
    "titulo": "Cobro Solicitado",
    "fechaCreacion": date.dateFormat(DateFormatterType.data),
    "pasarela": "QH-SIMPLE",
    "monto": monto,
    "moneda": moneda,
    "monedaId": monedaId,
    "config": {
      "notificarPagador":true
    }
  };
}
