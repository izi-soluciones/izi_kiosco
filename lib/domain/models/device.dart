class Device {
  int id;
  int sucursal;
  String nombre;
  int caja;
  ConfigDevice config;
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
      config: ConfigDevice.fromJson(json["config"]),
      activo: json["activo"] ?? false,
      enUso: json["enUso"] ?? false);

  @override
  String toString() {
    return 'Device{id: $id, sucursal: $sucursal, nombre: $nombre, caja: $caja, config: $config, activo: $activo, enUso: $enUso, sucursalName: $sucursalName}';
  }
}

class ConfigDevice {
  final String? ipAtc;
  final String? ipLinkser;
  final String? video;
  final bool demo;
  final int? timeMessage;

  const ConfigDevice(
      {this.ipAtc, this.ipLinkser, this.video, this.timeMessage,required this.demo});

  factory ConfigDevice.fromJson(dynamic json) {
    Map? jsonObj = json is Map ? json : null;
    return ConfigDevice(
      ipAtc: jsonObj?["ipAtc"] is String ? jsonObj!["ipAtc"] : null,
      ipLinkser: jsonObj?["ipLinkser"] is String ? jsonObj!["ipLinkser"] : null,
      video: jsonObj?["video"] is String ? jsonObj!["video"] : null,
      demo: jsonObj?["demo"] is bool ? jsonObj!["demo"] : false,
      timeMessage:
          jsonObj?["timeMessage"] is int ? jsonObj!["timeMessage"] : null,
    );
  }
}
