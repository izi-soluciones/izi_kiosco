import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/utils/date_formatter.dart';

class InvoiceDto {
  String actividadEconomica;
  int caja;
  int? codigoMetodoPago;
  String comprador;
  Currency? moneda;
  num descuentos;
  DateTime fecha;
  int metodoPago;
  num? pagoEnEfectivo;
  num? pagoEnTarjeta;
  bool prefactura;
  String razonSocial;
  String sucursalDireccion;
  String terminosPago;
  Map<String,dynamic>? customFactura;
  num? giftCards;
  DocumentType? documentType;
  String? numero;
  String? autorizacion;
  String? correoElectronicoComprador;

  InvoiceDto(
      {required this.actividadEconomica,
      required this.caja,
      this.codigoMetodoPago,
      required this.comprador,
      required this.moneda,
      required this.descuentos,
      required this.fecha,
        this.giftCards,
      required this.metodoPago,
      this.pagoEnEfectivo,
      this.pagoEnTarjeta,
      required this.prefactura,
      required this.razonSocial,
      this.documentType,
      this.customFactura,
        this.numero,
        this.autorizacion,
      required this.sucursalDireccion,
        this.correoElectronicoComprador,
      required this.terminosPago});

  Map<String, dynamic> toJson() {
    customFactura ??= {};
    customFactura?["exRate"]=moneda?.exRate;
    customFactura?["moneda"]=moneda?.toJson();
    var map ={
      "actividadEconomica": actividadEconomica,
      "caja": caja,
      if(codigoMetodoPago!=null)"codigoMetodoPago": codigoMetodoPago,
      "comprador": comprador,
      "customFactura":customFactura,
      "descuentos": descuentos,
      if (giftCards != null) "giftCards": giftCards,
      "fecha": fecha.dateFormat(DateFormatterType.data),
      "fechaPago": fecha.dateFormat(DateFormatterType.data),
      "metodoPago": metodoPago,
      if (pagoEnEfectivo != null) "pagoEnEfectivo": pagoEnEfectivo,
      if (pagoEnTarjeta != null) "pagoEnTarjeta": pagoEnTarjeta,
      "prefactura": prefactura,
      "razonSocial": razonSocial,
      "sucursalDireccion": sucursalDireccion,
      "terminosPago": terminosPago,
      if (documentType != null) "tipoDocumentoIdentidad": documentType,
      if(autorizacion!=null)"autorizacion": autorizacion,
      if(numero!=null)"numero":numero,
      if(correoElectronicoComprador!=null) "correoElectronicoComprador":correoElectronicoComprador
    };
    return map;
  }
}
