enum ConsumptionPointStatus{available,fill}
class ConsumptionPoint{
  String nombre;
  String id;
  bool activo;
  int capacidad;
  bool eliminado;
  ConsumptionPointStatus status;
  int x;
  int y;
  int comandaId;
  int? cantidadComensales;

  bool loading;
  ConsumptionPoint({
    required this.nombre,
    required this.id,
    required this.activo,
    required this.status,
    required this.capacidad,
    required this.eliminado,
    required this.x,
    required this.y,
    required this.comandaId,
    required this.cantidadComensales,
    this.loading = false
  });


  factory ConsumptionPoint.fromJson(Map<String,dynamic> json)=>ConsumptionPoint(
      id: json["_id"]??"",
    nombre: json["nombre"],
    status: json["estado"] == "ocupada"?ConsumptionPointStatus.fill:ConsumptionPointStatus.available,
    activo: json["activo"] ?? false,
    capacidad: json["capacidad"] ?? 0,
    eliminado: json["eliminado"]??false,
    x: json["posicionEspacio"] is Map?(json["posicionEspacio"]?["x"]??0):0,
    y: json["posicionEspacio"] is Map?(json["posicionEspacio"]?["y"]??0):0,
    comandaId: json["pedidoActivo"] is Map? (json["pedidoActivo"]?["comandaId"]??0):0,
    cantidadComensales: json["pedidoActivo"] is Map?json["pedidoActivo"]["cantidadComensales"] is String?int.tryParse(json["pedidoActivo"]["cantidadComensales"]): (json["pedidoActivo"]["cantidadComensales"] is int?(json["pedidoActivo"]["cantidadComensales"]) : 0) : 0,


  );

  ConsumptionPoint copyWith({
    bool? loading,
    ConsumptionPointStatus? status,
}){
    return ConsumptionPoint(
        nombre: nombre,
        id: id,
        activo: activo,
        status: status ?? this.status,
        capacidad: capacidad,
        eliminado: eliminado,
        x: x,
        y: y,
        comandaId: comandaId,
        cantidadComensales: cantidadComensales,
      loading: loading ?? this.loading
    );
  }
}