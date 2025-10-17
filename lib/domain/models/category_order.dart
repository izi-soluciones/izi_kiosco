import 'package:izi_kiosco/domain/models/item.dart';

class CategoryOrder{
  String? id;
  String nombre;
  List<Item> items;
  List<String> subCategorias;

  CategoryOrder({required this.nombre, this.items = const [],this.id, this.subCategorias= const []});

  factory CategoryOrder.fromJson(Map<dynamic,dynamic> json){
    List<String> subCategorias = [];
    List listItems=json["items"] is List?json["items"]:[];
    listItems.removeWhere((element) => element.isEmpty);
    if(json['subcategorias'] is List){
      for(dynamic sub in json['subcategorias']){
        if(sub is String){
          subCategorias.add(sub);
        }
      }
    }
    return CategoryOrder(
        nombre: json["nombre"],
        subCategorias: subCategorias,
        id: json["id"] ?? json["_id"] ?? ""
    );
  }

  CategoryOrder copyWith()=>CategoryOrder(nombre: nombre, items: List.from(items),id: id,subCategorias: subCategorias);
}