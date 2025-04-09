class Catalog{
  String id;
  String nombre;
  String? listaPrecio;

  Catalog({
    required this.nombre,
    required this.id,
    required this.listaPrecio
});
  factory Catalog.fromJson(Map json){
    return Catalog(nombre: json["nombre"] ?? "", id: json["id"] ?? json["_id"] ?? "", listaPrecio: json["listaPrecio"]);
  }
}