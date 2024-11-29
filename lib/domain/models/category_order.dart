import 'package:izi_kiosco/domain/models/item.dart';

class CategoryOrder{
  String? id;
  String nombre;
  List<Item> items;

  CategoryOrder({required this.nombre, this.items = const [],this.id});

  factory CategoryOrder.fromJson(Map<dynamic,dynamic> json){
    List listItems=json["items"] is List?json["items"]:[];
    listItems.removeWhere((element) => element.isEmpty);
    return CategoryOrder(
        nombre: json["nombre"],
        id: json["id"] ?? json["_id"] ?? ""
    );
  }

  CategoryOrder copyWith()=>CategoryOrder(nombre: nombre, items: List.from(items),id: id);
}