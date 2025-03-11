
import 'package:izi_kiosco/domain/models/category_order.dart';

class Catalog{
  String id;
  String nombre;
  String? listaPrecio;
  List<CatalogCategory> categories;

  Catalog({
    required this.nombre,
    required this.id,
    required this.listaPrecio,
    required this.categories
});
  factory Catalog.fromJson(Map json){
    return Catalog(
      nombre: json["nombre"] ?? "",
      id: json["id"] ?? json["_id"] ?? "",
      listaPrecio: json["listaPrecio"],
        categories: json["categorias"] is List?List.from(json["categorias"]).map((e) => CatalogCategory.fromJson(e) ).toList():[]
    );
  }
}

class CatalogCategory{
  CategoryOrder? category;
  List<String> items;

  CatalogCategory({
    required this.category,
    required this.items
});
  factory CatalogCategory.fromJson(Map json){
    return CatalogCategory(
        category: json["categoria"] is Map? CategoryOrder.fromJson(json["categoria"]):null,
        items: json["items"] is List? List.from(json["items"]).map((e) => e is String?e:"").toList():[]
    );
  }
}