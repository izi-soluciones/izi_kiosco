class Pos {
  int id;
  String? uuid;
  bool activo;
  bool isPruebas;
  dynamic custom;
  String token;

  Pos(
      {required this.id,
      required this.uuid,
      required this.activo,
      required this.custom,
      required this.isPruebas,
      required this.token});

  factory Pos.fromJson(Map<String, dynamic> json) => Pos(
      id: json["id"] ?? 0,
      uuid: json["uuid"] ?? "",
      activo: json["activo"] ?? false,
      custom: json["custom"],
      isPruebas: json["isPruebas"] ?? false,
      token: json["token"] ?? "");
}
