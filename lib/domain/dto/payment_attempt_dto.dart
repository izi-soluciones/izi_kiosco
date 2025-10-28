import 'package:izi_kiosco/domain/dto/payment_dto.dart';

class PaymentAttemptDto {
  int metodoPago;
  String uuid;
  String nit;
  String razonSocial;
  String telefonoComprador;
  String? correoElectronico;
  Map? tipoDocumento;
  String? complemento;
  PaymentDtoVentaDataCo? co;

  PaymentAttemptDto(
      {
      required this.metodoPago,
        required this.uuid,
        required this.nit,
        required this.razonSocial,
        required this.telefonoComprador,
        this.correoElectronico,
        this.tipoDocumento,
        this.complemento
      });

  Map<String,dynamic> toJson()=>{
    "metodoPago": metodoPago,
    "uuid": uuid,
    "pagadorData":{},
    "ventaData": {
      "nit": nit,
      "razonSocial": razonSocial,
      "telefonoComprador": telefonoComprador,
      if(complemento!=null)"complemento": complemento,
      if(tipoDocumento!=null)"tipoDocumento": tipoDocumento,
      if(correoElectronico!=null)"correoElectronico": correoElectronico,
      if(co!=null)"CO": co
    }
  };
}
