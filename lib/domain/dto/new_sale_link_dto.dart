import 'package:izi_kiosco/domain/models/campos_extra.dart';
import 'package:izi_kiosco/domain/models/item.dart';

class NewSaleLinkDto {
  int dispositivo;
  List<Item> listaItems;
  List<CamposExtra>? camposExtra;

  NewSaleLinkDto(
      {
      required this.listaItems,
      required this.dispositivo,
      this.camposExtra});

  Map<String,dynamic> toJson()=>{
      "listaItems": listaItems.map((item) => {
        "item": item.id,
        "cantidad": item.cantidad
      }).toList(),
      if (camposExtra != null && camposExtra!.isNotEmpty)
        "camposExtra": camposExtra!
            .where((c) => c.valor != null && c.valor!.isNotEmpty)
            .map((c) => c.toJson())
            .toList(),
  };
}
