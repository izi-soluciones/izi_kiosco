import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/utils/date_formatter.dart';

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

  Map? custom;

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
      this.anulada=false,
      required this.paraLlevar,
      required this.tipoComanda,
      this.total=0,
        required this.deviceId,
        this.clienteNombre,
      required this.sucursal});

  Map<String, dynamic> toJson() => {
        "caja": caja,
        "custom": {
          if (cantidadComensales != null)
            "cantidadComensales": cantidadComensales,
          if (nombreMesa != null) "nombreMesa": nombreMesa,
          "dispositivo": deviceId
        },
        "descuentos": descuentos,
        "emisor": emisor,
        "fecha": fecha.dateFormat(DateFormatterType.dataWithHour),
        "listaItems": listaItems.map(
          (e) {
            return e.toJson();
          },
        ).toList(),
        "mesa": mesa,
        if(notaInterna!=null)"notaInterna": notaInterna,
        "paraLlevar": paraLlevar,
        "sucursal": sucursal,
        "tipoComanda": tipoComanda,
        "anulada":anulada?1:0,
        "tipoMovimiento": "gasto-prod-venta"
      };
  Map<String, dynamic> toJsonEdit() => {
    "custom": custom,
    "fecha": fecha.dateFormat(DateFormatterType.dataWithHour),
    "clienteNombre": clienteNombre
  };

}
