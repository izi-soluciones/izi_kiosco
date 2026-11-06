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
  final String? ipEcopay;
  final String? mqttClientId;
  final String? mqttUserName;
  final String? mqttPassword;
  final String? commerceId;
  final String? cajaId;
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
  final bool printSat;
  final bool printAutoReply;
  final bool ocultarCash;
  final bool ocultarQr;
  final bool ocultarBreb;
  final bool facturaCompacto;
  final bool noPrintRollo;
  final IziColorPalette? colors;
  final KioskColors kioskColors;
  final String? idiomaDefecto;
  final bool permiteCambioIdioma;

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
      this.ipEcopay,
      this.mqttClientId,
      this.mqttUserName,
      this.mqttPassword,
      this.commerceId,
      this.cajaId,
      required this.noPrintRollo,
      required this.descargarQR,
      required this.printSat,
      required this.printAutoReply,
      required this.ocultarCash,
      required this.ocultarQr,
      required this.ocultarBreb,
      required this.facturaCompacto,
      this.video,
        required this.pin,
      required this.demo,
      required this.colors,
      required this.kioskColors,
      required this.idiomaDefecto,
      required this.permiteCambioIdioma,
      required this.sortByPriority});

  factory ConfigDevice.fromJson(dynamic json) {
    Map? jsonObj = json is Map ? json : null;

    var config = ConfigDevice(
      ipAtc: jsonObj?["ipAtc"] is String ? jsonObj!["ipAtc"] : null,
      ipLinkser: jsonObj?["ipLinkser"] is String ? jsonObj!["ipLinkser"] : null,
      ipEcopay: _nonEmptyString(jsonObj?["ipEcopay"]),
      // EcoPay values come from the backend JSON, where ids like the MQTT user
      // name or commerce id may be stored as numbers. A raw `dynamic` assigned
      // to these String fields crashed the kiosk on login, so coerce them.
      mqttClientId: _nonEmptyString(_ecopayField(jsonObj, "mqttClientId")),
      mqttUserName: _nonEmptyString(_ecopayField(jsonObj, "mqttUserName")),
      mqttPassword: _nonEmptyString(_ecopayField(jsonObj, "mqttPassword")),
      commerceId: _nonEmptyString(_ecopayField(jsonObj, "commerceId")),
      cajaId: _nonEmptyString(_ecopayField(jsonObj, "cajaId")),
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
      // Accept a numeric PIN too: without it pairing with the POS is refused.
      pin: _nonEmptyString(jsonObj?["pin"]),
      sortByPriority:
      jsonObj?["ordenarPrioridad"] is bool ? jsonObj!["ordenarPrioridad"] : null,
      token: _nonEmptyString(jsonObj?["token"]),
      descargarQR: jsonObj?["descargarQR"] is bool ? jsonObj!["descargarQR"] : false,
      printSat: jsonObj?["printSat"] is bool ? jsonObj!["printSat"] : false,
      printAutoReply: jsonObj?["printAutoReply"] is bool ? jsonObj!["printAutoReply"] : false,
      ocultarCash: jsonObj?["ocultarCash"] is bool ? jsonObj!["ocultarCash"] : false,
      ocultarQr: jsonObj?["ocultarQr"] is bool ? jsonObj!["ocultarQr"] : false,
      ocultarBreb: jsonObj?["ocultarBreb"] is bool ? jsonObj!["ocultarBreb"] : false,
      facturaCompacto: jsonObj?["facturaCompacto"] is bool ? jsonObj!["facturaCompacto"] : false,
      isRetailBarcode: jsonObj?["isRetailBarcode"] is bool ? jsonObj!["isRetailBarcode"] : false,
      colors: IziColorPalette.fromMap(jsonObj?["colors"]),
      noPrintRollo: jsonObj?["noPrintRollo"] is bool ? jsonObj!["noPrintRollo"] : false,
      kioskColors: KioskColors.fromJson(jsonObj?["kioskColors"]),
      idiomaDefecto: jsonObj?["idiomaDefecto"] is String ? jsonObj!["idiomaDefecto"] : null,
      permiteCambioIdioma: jsonObj?["permiteCambioIdioma"] is bool ? jsonObj!["permiteCambioIdioma"] : false,
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

/// The EcoPay setting [key], read from `config.ecopayConfig` or, for older
/// device configs, from the root of `config`.
dynamic _ecopayField(Map? config, String key) {
  final nested = config?["ecopayConfig"];
  if (nested is Map && nested[key] != null) return nested[key];
  return config?[key];
}

/// [value] as a trimmed string, or null when absent or blank. Numbers are
/// accepted (the backend may store ids and PINs as numbers).
String? _nonEmptyString(dynamic value) {
  if (value == null) return null;
  if (value is! String && value is! num) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
