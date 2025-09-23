import 'package:izi_kiosco/domain/models/item.dart';

class NewSaleLinkDto {
  int dispositivo;
  List<Item> listaItems;

  NewSaleLinkDto(
      {
      required this.listaItems,
      required this.dispositivo});

  Map<String,dynamic> toJson()=>{
    "dispositivo":dispositivo,
      "listaItems": listaItems.map((item) => {
        "item": item.id,
        "cantidad": item.cantidad
      }).toList(),
  };
}
