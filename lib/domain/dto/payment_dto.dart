class PaymentDto {
  int orderId;
  DateTime date;
  num monto;
  int monedaId;
  String moneda;
  int metodoPago;

  PaymentDto(
      {required this.orderId,
      required this.date,
      required this.monto,
      required this.moneda,
      required this.monedaId,
      required this.metodoPago});

  Map<String,dynamic> toJson(int contribuyenteId)=>{
    "contribuyente": contribuyenteId,
    "pedido": orderId,
    "monto": monto,
    "moneda": moneda,
    "monedaId": monedaId,
    "metodoPago": metodoPago,
    "config": {
      "notificarPagador":true,
      "desdeKiosco":true
    }
  };
}
