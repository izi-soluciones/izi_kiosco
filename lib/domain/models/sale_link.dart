import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/models/item.dart';

class SaleLink{
  int contribuyente;
  int id;
  int monedaId;
  num monto;
  String uuid;
  List<Item> items;

  SaleLink({
    required this.contribuyente,
    required this.monto,
    required this.id,
    required this.uuid,
    required this.monedaId,
    required this.items
});
  factory SaleLink.fromJson(Map json)=>
      SaleLink(
          contribuyente: json["contribuyente"],
          monto: json["monto"] ?? 0,
          id: json["id"],
          items: json["ventaData"] is Map && json["ventaData"]["listaItems"] is List?List.from(json["ventaData"]["listaItems"]).map((e) => Item.fromJson(e)).toList():[],
          uuid: json["uuid"] ?? "",
          monedaId: json["monedaId"]?? AppConstants.defaultCurrencyId
      );
}