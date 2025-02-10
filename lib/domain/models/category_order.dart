import 'package:izi_kiosco/domain/models/item.dart';

class CategoryOrder{
  int? id;
  String nombre;
  String? image;
  List<Item> items;

  CategoryOrder({required this.nombre, required this.items,this.id,this.image});

  factory CategoryOrder.fromJson(Map<dynamic,dynamic> json){
    List listItems=json["items"] is List?json["items"]:[];
    listItems.removeWhere((element) => element.isEmpty);
    return CategoryOrder(
        nombre: json["nombre"],
        image: json["customCategoria"] is Map && json["customCategoria"]["imagen"] is String?json["customCategoria"]["imagen"]:null,
        items: listItems.map((e) => Item.fromJson(e)).toList()
    );
  }

  CategoryOrder copyWith()=>CategoryOrder(nombre: nombre, items: List.from(items),id: id,image: image);
}