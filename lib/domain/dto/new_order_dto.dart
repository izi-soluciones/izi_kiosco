import 'package:izi_kiosco/domain/models/campos_extra.dart';
import 'package:izi_kiosco/domain/models/document_type.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/utils/date_formatter.dart';


class NewOrderDtoCustom {
  NewOrderDtoCustomPagadorData? pagadorData;
  int? deviceId;
  String? nombreMesa;
  List<CamposExtra>? camposExtras;

  NewOrderDtoCustom({
    this.pagadorData,
    this.deviceId,
    this.nombreMesa,
    this.camposExtras,
  });

  Map<String, dynamic> toJson() {
    return {
      if (pagadorData != null) 'pagadorData': pagadorData?.toJson(),
      if (deviceId != null) 'deviceId': deviceId,
      if (nombreMesa != null && nombreMesa!.isNotEmpty) "nombreMesa": nombreMesa,
      if (camposExtras != null && camposExtras!.isNotEmpty)
        "camposExtra": camposExtras!
            .where((e) => e.valor != null && e.valor!.isNotEmpty)
            .map((e) => e.toJson())
            .toList(),
    };
  }
}
class NewOrderDtoCustomPagadorData {
  String? nit;
  String? complemento;
  DocumentType? tipoDocumento;
  String? razonSocial;
  String? telefonoComprador;
  NewOrderDtoCustomPagadorDataCo? co;

  NewOrderDtoCustomPagadorData({
    this.nit,
    this.complemento,
    this.razonSocial,
    this.telefonoComprador,
    this.co
  });

  Map<String, dynamic> toJson() {
    return {
      'nit': nit,
      'complemento': complemento,
      'razonSocial': razonSocial,
      if(telefonoComprador?.isNotEmpty==true)'telefonoComprador': telefonoComprador,
      'tipoDocumento': tipoDocumento?.toJson(),
      "CO": co?.toJson()
    };
  }
}
class NewOrderDtoCustomPagadorDataCo {
  String? tipoIdentificacion;
  String? resonsabilidadIva;
  String? tipoPersona;
  String? resposabilidadFiscal;

  NewOrderDtoCustomPagadorDataCo({
    required this.tipoIdentificacion,
    required this.resonsabilidadIva,
    required this.tipoPersona,
    required this.resposabilidadFiscal,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipoIdentificacion': tipoIdentificacion,
      'resonsabilidadIva': resonsabilidadIva,
      'tipoPersona': tipoPersona,
      'resposabilidadFiscal': resposabilidadFiscal,
    };
  }
}


class NewOrderDto {
  int? caja;
  int? cantidadComensales;
  String? nombreMesa;
  num descuentos;
  String emisor;
  DateTime fecha;
  List<Item> listaItems;
  String mesa;
  String? notaInterna;
  bool paraLlevar;
  int sucursal;
  String tipoComanda;
  int? id;
  bool anulada;
  int deviceId;

  num total;

  NewOrderDtoCustom? custom;

  String? clienteNombre;

  NewOrderDto(
      {required this.caja,
      required this.cantidadComensales,
      required this.nombreMesa,
      required this.descuentos,
      required this.emisor,
      required this.fecha,
      required this.listaItems,
      required this.mesa,
      this.notaInterna,
      this.anulada = false,
      required this.paraLlevar,
      required this.tipoComanda,
      this.total = 0,
      required this.deviceId,
      this.clienteNombre,
      this.custom,
      required this.sucursal});

  Map<String, dynamic> toJson() => {
        "listaItems": listaItems.map(
          (e) {
            return e.toJson();
          },
        ).toList(),
        "paraLlevar": paraLlevar,
        if (mesa.isNotEmpty) "mesa": mesa,
        if (nombreMesa != null && nombreMesa!.isNotEmpty) "nombreMesa": nombreMesa,
        if (custom != null) "custom": custom!.toJson(),
      };
  Map<String, dynamic> toJsonEdit() => {
    "custom": custom?.toJson(),
    "fecha": fecha.dateFormat(DateFormatterType.dataWithHour),
    "clienteNombre": clienteNombre
  };

}
