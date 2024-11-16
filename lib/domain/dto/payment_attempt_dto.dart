class PaymentAttemptDto {
  int metodoPago;
  String uuid;
  String nit;
  String razonSocial;
  String telefonoComprador;
  Map? tipoDocumento;
  String? complemento;

  PaymentAttemptDto(
      {
      required this.metodoPago,
        required this.uuid,
        required this.nit,
        required this.razonSocial,
        required this.telefonoComprador,
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
      "complemento": complemento,
      "tipoDocumento": tipoDocumento
    }
  };
}
