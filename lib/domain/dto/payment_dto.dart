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

class PaymentDtoVentaDataCo{
  String identificationType;
  String ivaResponsability;
  String personType;
  String? taxResponsability;

  PaymentDtoVentaDataCo({
    required this.identificationType,
    required this.ivaResponsability,
    required this.personType,
    required this.taxResponsability
  });
  Map toJson()=>{
    "tipoPersona": personType,
    "resonsabilidadIva": ivaResponsability,
    "resposabilidadFiscal": taxResponsability,
    "tipoIdentificacion": identificationType,
  };

}

class PaymentDtoVentaData{
  DocumentType? tipoDocumento;
  String nit;
  String? complemento;
  String razonSocial;
  String telefonoComprador;
  String? correoElectronico;
  PaymentDtoVentaDataCo? co;


  PaymentDtoVentaData(
      {this.tipoDocumento,
      required this.complemento,
      required this.nit,
      this.correoElectronico,
      required this.razonSocial,
      this.co,
      required this.telefonoComprador});

  Map toJson()=>{
    "tipoDocumento": tipoDocumento?.toJson(),
    "nit": nit,
    if(complemento?.isNotEmpty==true)"complemento": complemento,
    "razonSocial": razonSocial,
    "telefonoComprador": telefonoComprador,
    if(correoElectronico?.isNotEmpty==true)"correoElectronico": correoElectronico,
    if(co!=null)"co": co
  };
}