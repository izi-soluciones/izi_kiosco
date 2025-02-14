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
  final bool isRetail;
  final String? almacen;
  final String? actividadEconomica;
  final int? timeVideo;
  final int? timeOrder;
  final int? timeConfirmation;
  final int? timePayment;

  const ConfigDevice(
      {this.ipAtc,
      required this.timeConfirmation,
      required this.timeOrder,
      required this.timePayment,
      required this.timeVideo,
      required this.actividadEconomica,
      required this.almacen,
      required this.isRetail,
      this.ipLinkser,
      this.video,
      required this.demo});

  factory ConfigDevice.fromJson(dynamic json) {
    Map? jsonObj = json is Map ? json : null;

    var config = ConfigDevice(
      ipAtc: jsonObj?["ipAtc"] is String ? jsonObj!["ipAtc"] : null,
      ipLinkser: jsonObj?["ipLinkser"] is String ? jsonObj!["ipLinkser"] : null,
      video: jsonObj?["video"] is String ? jsonObj!["video"] : null,
      demo: jsonObj?["demo"] is bool ? jsonObj!["demo"] : false,
      isRetail: jsonObj?["isRetail"] is bool ? jsonObj!["isRetail"] : false,
      almacen: jsonObj?["almacen"] is String ? jsonObj!["almacen"] : null,
      actividadEconomica: jsonObj?["actividadEconomica"] is int
          ? (jsonObj?["actividadEconomica"] as int).toString()
          : jsonObj?["actividadEconomica"] is String
              ? jsonObj!["actividadEconomica"]
              : null,
      timeConfirmation:
          jsonObj?["tiempoConfirmacion"] is int ? jsonObj!["tiempoConfirmacion"] : null,
      timeVideo:
      jsonObj?["tiempoVideo"] is int ? jsonObj!["tiempoVideo"] : null,
      timePayment:
      jsonObj?["tiempoPago"] is int ? jsonObj!["tiempoPago"] : null,
      timeOrder:
      jsonObj?["tiempoOrden"] is int ? jsonObj!["tiempoOrden"] : null,
    );
    return config;
  }
}
