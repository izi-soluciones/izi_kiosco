import 'package:izi_kiosco/domain/utils/date_formatter.dart';

class Payment {
  int? id;
  int? metodoPago;
  String? terminosPago;
  num? monto;
  int? moneda;
  String? pdfPago;
  bool loading;
  bool fromCharge;

  Payment({
    this.id,
    this.metodoPago,
    this.monto,
    this.loading = false,
    this.terminosPago,
    this.moneda,
    this.pdfPago,
    this.fromCharge = false
  });

  factory Payment.fromJson(Map<String,dynamic> json)=>Payment(
      id: json["id"] ?? 0,
      metodoPago: json["metodoPago"] ?? 1,
      terminosPago: json["terminosPago"] ?? "",
      monto: json["monto"] ?? 0,
      moneda: json["moneda"] ?? 150,
      pdfPago: json["pdfPago"]
  );

  Map<String,dynamic> toJson(int contribuyenteId)=>{
    "metodoPago":metodoPago,
    "terminosPago":terminosPago,
    "contribuyente": contribuyenteId,
    "fechaPago": DateTime.now().dateFormat(DateFormatterType.data),
    "moneda":moneda,
    "monto":monto,
  };

  copyWith({
    bool? loading
}){
    return Payment(
      id: id,
      loading: loading ?? this.loading,
      monto: monto,
      metodoPago: metodoPago,
      moneda: moneda,
      pdfPago: pdfPago,
      terminosPago: terminosPago
    );
  }
}