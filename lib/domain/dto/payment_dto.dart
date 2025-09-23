import 'package:izi_kiosco/domain/models/document_type.dart';

class PaymentDto {
  int orderId;
  int metodoPago;
  PaymentDtoVentaData ventaData;

  PaymentDto(
      {required this.orderId,
      required this.ventaData,
      required this.metodoPago});

  Map<String,dynamic> toJson(int contribuyenteId)=>{
    "pedido": orderId,
    "metodoPago": metodoPago,
    "ventaData": ventaData.toJson()
  };
}


class PaymentDtoVentaData{
  DocumentType? tipoDocumento;
  String nit;
  String? complemento;
  String razonSocial;
  String telefonoComprador;


  PaymentDtoVentaData(
      {required this.tipoDocumento,
      required this.complemento,
      required this.nit,
      required this.razonSocial,
      required this.telefonoComprador});

  Map toJson()=>{
    "tipoDocumento": tipoDocumento?.toJson(),
    "nit": nit,
    if(complemento!=null)"complemento": complemento,
    "razonSocial": razonSocial,
    "telefonoComprador": telefonoComprador
  };
}