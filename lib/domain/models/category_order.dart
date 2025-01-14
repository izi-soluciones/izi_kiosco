import 'package:izi_kiosco/domain/models/item.dart';

class CategoryOrder{
  String? id;
  String nombre;
  num? prioridad;
  List<Item> items;
  int? columns;
  List<String>? bannersKiosco;

  CategoryOrder({required this.nombre, this.items = const [],this.id,this.prioridad,this.columns,this.bannersKiosco});

  factory CategoryOrder.fromJson(Map<dynamic,dynamic> json){
    List listItems=json["items"] is List?json["items"]:[];
    listItems.removeWhere((element) => element.isEmpty);
    return CategoryOrder(
        nombre: json["nombre"],
        id: json["id"] ?? json["_id"] ?? "",
        prioridad: json["prioridad"] is num?json["prioridad"]:null,
        columns: json["custom"] is Map && json["custom"]["columnasKiosco"] is int?json["custom"]["columnasKiosco"]:null,
        bannersKiosco: json["custom"] is Map && json["custom"]["bannersKiosco"] is List?(json["custom"]["bannersKiosco"] as List).map((e) {
          return e is String?e:"";
        }).toList():null
    );
  }

  CategoryOrder copyWith()=>CategoryOrder(nombre: nombre, items: List.from(items),id: id,prioridad: prioridad,bannersKiosco: bannersKiosco,columns: columns);
}