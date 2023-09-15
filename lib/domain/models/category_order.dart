import 'package:izi_kiosco/domain/models/item.dart';

class CategoryOrder{
  int? id;
  String nombre;
  List<Item> items;

  CategoryOrder({required this.nombre, required this.items,this.id});

  factory CategoryOrder.fromJson(Map<dynamic,dynamic> json){
    List listItems=json["items"] is List?json["items"]:[];
    listItems.removeWhere((element) => element.isEmpty);
    return CategoryOrder(
        nombre: json["nombre"],
        items: listItems.map((e) => Item.fromJson(e)).toList()
    );
  }

  CategoryOrder copyWith()=>CategoryOrder(nombre: nombre, items: List.from(items),id: id);
}