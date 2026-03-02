import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';

class Device {
  int id;
  int sucursal;
  String nombre;
  int caja;
  ConfigDevice config;
  bool activo;
  bool enUso;
  String? sucursalName;
  String? catalogo;

  Device(
      {required this.id,
      required this.sucursal,
      required this.nombre,
      required this.caja,
      required this.config,
      this.sucursalName,
      required this.enUso,
        required this.catalogo,
      required this.activo});

  factory Device.fromJson(Map json) => Device(
      id: json["id"],
      sucursal: json["sucursal"],
      nombre: json["nombre"],
      caja: json["caja"],
      config: ConfigDevice.fromJson(json["config"]),
      activo: json["activo"] ?? false,
      catalogo: json["catalogo"],
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
  final bool isRetailBarcode;
  final String? almacen;
  final String? actividadEconomica;
  final int? timeVideo;
  final int? timeOrder;
  final int? timeConfirmation;
  final int? timePayment;
  final String? pin;
  final bool? sortByPriority;
  final String? token;
  final bool descargarQR;
  final bool ocultarCash;
  final bool facturaCompacto;
  final bool noPrintRollo;
  final IziColorPalette? colors;
  final KioskColors kioskColors;

  const ConfigDevice(
      {this.ipAtc,
      required this.timeConfirmation,
      required this.timeOrder,
      required this.timePayment,
      required this.timeVideo,
      required this.actividadEconomica,
      required this.almacen,
      required this.isRetail,
      required this.isRetailBarcode,
      required this.token,
      this.ipLinkser,
      required this.noPrintRollo,
      required this.descargarQR,
      required this.ocultarCash,
      required this.facturaCompacto,
      this.video,
        required this.pin,
      required this.demo,
      required this.colors,
      required this.kioskColors,
      required this.sortByPriority});

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
      pin:
      jsonObj?["pin"] is String ? jsonObj!["pin"] : null,
      sortByPriority:
      jsonObj?["ordenarPrioridad"] is bool ? jsonObj!["ordenarPrioridad"] : null,
      token: jsonObj?["token"] is String ? jsonObj!["token"] : null,
      descargarQR: jsonObj?["descargarQR"] is bool ? jsonObj!["descargarQR"] : false,
      ocultarCash: jsonObj?["ocultarCash"] is bool ? jsonObj!["ocultarCash"] : false,
      facturaCompacto: jsonObj?["facturaCompacto"] is bool ? jsonObj!["facturaCompacto"] : false,
      isRetailBarcode: jsonObj?["isRetailBarcode"] is bool ? jsonObj!["isRetailBarcode"] : false,
      colors: IziColorPalette.fromMap(jsonObj?["colors"]),
      noPrintRollo: jsonObj?["noPrintRollo"] is bool ? jsonObj!["noPrintRollo"] : false,
      kioskColors: KioskColors.fromJson(jsonObj?["kioskColors"]),
    );
    return config;
  }
}

class KioskColors{
  final Color? categoryBgColor;
  final Color? categoryTextColor;

  const KioskColors({required this.categoryBgColor, required this.categoryTextColor});

  factory KioskColors.fromJson(Map<String, dynamic>? json) { 

  Color? parseColor(String? value) {
    if (value == null) return null;
    try {
      String hex = value.replaceAll("#", "");
      if (hex.length == 6) {
        hex = "FF$hex";
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return null;
    }
  }
    return KioskColors(
      categoryBgColor: json?["categoryBgColor"] is String? parseColor(json?["categoryBgColor"]) : null,
      categoryTextColor: json?["categoryTextColor"] is String? parseColor(json?["categoryTextColor"]) : null);}
}
