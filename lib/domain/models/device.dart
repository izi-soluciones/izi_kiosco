class Device {
  int id;
  int sucursal;
  String nombre;
  int caja;
  Map config;
  bool activo;
  bool enUso;
  String? sucursalName;

  Device(
      {required this.id,
      required this.sucursal,
      required this.nombre,
      required this.caja,
      required this.config,
      this.sucursalName,
      required this.enUso,
      required this.activo});

  factory Device.fromJson(Map json) => Device(
      id: json["id"],
      sucursal: json["sucursal"],
      nombre: json["nombre"],
      caja: json["caja"],
      config: json["config"] is Map ? json["config"] : {},
      activo: json["activo"] ?? false,
      enUso: json["enUso"] ?? false);

  @override
  String toString() {
    return 'Device{id: $id, sucursal: $sucursal, nombre: $nombre, caja: $caja, config: $config, activo: $activo, enUso: $enUso, sucursalName: $sucursalName}';
  }
}
