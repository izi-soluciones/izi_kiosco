import 'package:izi_kiosco/domain/models/item.dart';

class NewSaleLinkDto {
  int contribuyente;
  String moneda;
  int monedaId;
  String? actividadEconomica;
  String almacen;
  List<Item> listaItems;
  int sucursal;
  bool prefactura;

  NewSaleLinkDto(
      {required this.monedaId,
      required this.contribuyente,
      required this.sucursal,
      required this.actividadEconomica,
      required this.almacen,
        required this.prefactura,
      required this.listaItems,
      required this.moneda});

  Map<String,dynamic> toJson()=>{
    "activo":true,
    "contribuyente":contribuyente,
    "config":{
      "desdeKiosco":true
    },
    "moneda": moneda,
    "monedaId":monedaId,
    "titulo":"",
    "isInternal": true,
    "ventaData":{
      "actividadEconomica":actividadEconomica,
      "almacen": almacen,
      "listaItems": listaItems.map((item) => {
        "item": item.id,
        "cantidad": item.cantidad,
        "precioUnitario": item.precioUnitario + item.precioModificadores / item.cantidad,
        "articulo": item.nombre,
        "codigoInventario": item.codigo,
        "customItem": item.customItem
      }).toList(),
      "sucursal": sucursal,
      "tipoFactura": prefactura?-1:1
    }
  };
}
