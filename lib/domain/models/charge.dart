import 'package:equatable/equatable.dart';

class Charge extends Equatable {
  final String? qrUrl;
  final String uuid;
  final int id;

  const Charge(
      {required this.qrUrl,
      required this.uuid,
      required this.id});

  factory Charge.fromJson(Map<String, dynamic> json) =>
      Charge(qrUrl: json["qr"], uuid: json["uuid"] ?? "", id: json["id"] ?? 0);

  Charge copyWith({
    String? qrUrl,
    String? uuid,
    int? id,
  }) {
    return Charge(
        qrUrl: qrUrl ?? this.qrUrl,
        uuid: uuid ?? this.uuid,
        id: id ?? this.id);
  }

  @override
  List<Object?> get props => [qrUrl, uuid, id];
}
