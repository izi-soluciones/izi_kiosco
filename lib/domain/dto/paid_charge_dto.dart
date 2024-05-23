class PaidChargeDto{
  int orden;
  int metodoPago;
  num monto;
  String moneda;
  int monedaId;
  int contribuyente;

  PaidChargeDto(
      {required this.orden,
        required this.metodoPago,
        required this.monto,
        required this.moneda,
        required this.monedaId,
        required this.contribuyente});


  toJson()=>{
    "pedido": orden,
    "metodoPago": metodoPago,
    "monto": monto,
    "moneda":moneda,
    "monedaId": monedaId,
    "contribuyente": contribuyente
  };
}