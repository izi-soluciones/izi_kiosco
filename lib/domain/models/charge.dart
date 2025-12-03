import 'package:equatable/equatable.dart';

class Charge extends Equatable {
  final String? qrUrl;
  final String uuid;
  final int id;
  final String? qrBase64;
  final String? token;
  final int? intentoPago;
  final String? cobroKeyValue;

  const Charge(
      {required this.qrUrl,
      required this.uuid,
      required this.qrBase64,
      this.intentoPago,
      required this.token,
      required this.id, 
      this.cobroKeyValue});

  factory Charge.fromJson(Map<String, dynamic> json) {
    String? qrUrl;
    String? qrBase64;
    if (json["qr"] is String) {
      if (Uri.parse(json["qr"]).isAbsolute) {
        qrUrl = json["qr"];
      } else {
        qrBase64 = (json["qr"] as String).split(",").lastOrNull;
      }
    }
    return Charge(
        qrUrl: qrUrl,
        uuid: json["uuid"] ?? "",
        id: json["id"] ?? 0,
        token: json["custom"] is Map &&
                json["custom"]["datosIntegracion"] is Map &&
                json["custom"]["datosIntegracion"]["token"] is String
            ? json["custom"]["datosIntegracion"]["token"]
            : null,
        cobroKeyValue: json["custom"] is Map &&
                json["custom"]["datosIntegracion"] is Map &&
                json["custom"]["datosIntegracion"]["cobroKeyValue"] is String
            ? json["custom"]["datosIntegracion"]["cobroKeyValue"]
            : null,
        qrBase64: qrBase64);
  }

  factory Charge.fromJsonAttempt(Map<String, dynamic> json,String uuid) {
    String? qrUrl;
    String? qrBase64;
    if (json["qr"] is String) {
      if (Uri.parse(json["qr"]).isAbsolute) {
        qrUrl = json["qr"];
      } else {
        qrBase64 = (json["qr"] as String).split(",").lastOrNull;
      }
    }
    return Charge(
        qrUrl: qrUrl,
        uuid: uuid,
        id: json["id"],
        intentoPago: json["id"],
        token: json["custom"] is Map &&
            json["custom"]["datosIntegracion"] is Map &&
            json["custom"]["datosIntegracion"]["token"] is String
            ? json["custom"]["datosIntegracion"]["token"]
            : null,
        cobroKeyValue: json["custom"] is Map &&
                json["custom"]["datosIntegracion"] is Map &&
                json["custom"]["datosIntegracion"]["cobroKeyValue"] is String
            ? json["custom"]["datosIntegracion"]["cobroKeyValue"]
            : null,
        qrBase64: qrBase64);
  }

  Charge copyWith({String? qrUrl, String? uuid, int? id, String? qrBase64,String? token,String? cobroKeyValue,}) {
    return Charge(
        qrUrl: qrUrl ?? this.qrUrl,
        uuid: uuid ?? this.uuid,
        id: id ?? this.id,
        token: token ?? this.token,
        qrBase64: qrBase64 ?? this.qrBase64,
        cobroKeyValue: cobroKeyValue ?? this.cobroKeyValue);
  }

  @override
  List<Object?> get props => [qrUrl, uuid, id, qrBase64,token,cobroKeyValue];
}
