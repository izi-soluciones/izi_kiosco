class Room{
  String id;
  bool activo;
  List<int> cajas;
  String nombre;
  int width;
  int height;
  bool eliminado;

  Room({
      required this.id,
      required this.activo,
      required this.cajas,
      required this.nombre,
      required this.width,
      required this.height,
      required this.eliminado});

  factory Room.fromJson(Map<String, dynamic> json) {
      return Room(
          id: json["_id"] ?? "",
          activo: json["activo"] ?? false,
          cajas: json["cajas"] is Iterable?List.from(json["cajas"])
              .map((e) => e is int? e:0)
              .toList():[],
          nombre: json["nombre"] ?? "",
          width: json["dimensiones"] is Map && json["dimensiones"]?["width"] is Map?int.tryParse(json["dimensiones"]?["width"]?["\$numberDecimal"]??"") ?? 0 : 0,
          height: json["dimensiones"] is Map && json["dimensiones"]?["height"] is Map?int.tryParse(json["dimensiones"]?["height"]?["\$numberDecimal"]??"") ?? 0 : 0,
          eliminado: json["eliminado"] ?? false
      );
  }
}