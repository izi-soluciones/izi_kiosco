import 'package:equatable/equatable.dart';

class Charge extends Equatable {
  final String? qrUrl;
  final String uuid;
  final int id;
  final String? qrBase64;

  const Charge(
      {required this.qrUrl,
      required this.uuid,
      required this.qrBase64,
      required this.id});

  factory Charge.fromJson(Map<String, dynamic> json) {
    String? qrUrl;
    String? qrBase64;
    if(json["qr"] is String){
      if((json["qr"] as String).startsWith("data:")){
        qrBase64=(json["qr"] as String).split(",").lastOrNull;
      }
      else{
        qrUrl=json["qr"];
      }
    }
    return Charge(
        qrUrl: qrUrl,
        uuid: json["uuid"] ?? "",
        id: json["id"] ?? 0,
        qrBase64: qrBase64);
  }

  Charge copyWith({
    String? qrUrl,
    String? uuid,
    int? id,
    String? qrBase64
  }) {
    return Charge(
        qrUrl: qrUrl ?? this.qrUrl, uuid: uuid ?? this.uuid, id: id ?? this.id,qrBase64: qrBase64 ?? this.qrBase64);
  }

  @override
  List<Object?> get props => [qrUrl, uuid, id,qrBase64];
}
