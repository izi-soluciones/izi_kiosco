class CashRegister {
  int id;
  String nombre;
  bool estado;
  bool abierta;

  int? userOpen;

  CashRegister(
      {required this.id,
      required this.nombre,
      required this.estado,
        required this.userOpen,
      required this.abierta});

  factory CashRegister.fromJson(Map<String, dynamic> json) => CashRegister(
      id: json["id"] ?? 0,
      nombre: json["nombre"] ?? "",
      userOpen: (json["sesiones"] is List<dynamic>)?((json["sesiones"] as List<dynamic>).firstOrNull?["usuario"]):null,
      estado: json["estado"] ?? false,
      abierta: json["abierta"] ?? false);
}
