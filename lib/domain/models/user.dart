class User {
  User({
    this.uuid,
    required this.nombres,
    required this.apPaterno,
    required this.apMaterno,
    this.correoElectronico,
    this.documentoIdentidad,
    this.legalCheck,
    this.emailCheck,
    required this.id,
    this.avatar,
    this.estado,
    this.salario
  });
  String? uuid;
  String nombres;
  String apPaterno;
  String apMaterno;
  String? correoElectronico;
  String? documentoIdentidad;
  int? legalCheck;
  int? emailCheck;
  int id;
  int? avatar;
  int? estado;
  num? salario;

  factory User.fromJson(Map<String, dynamic> json)=>User(
    uuid : json['uuid'],
    nombres : json['nombres'],
    apPaterno : json['apPaterno'],
    apMaterno : json['apMaterno'],
    correoElectronico : json['correoElectronico'],
    documentoIdentidad : json['documentoIdentidad'],
    legalCheck : json['legalCheck'] is bool?json["legalCheck"]?1:0:json["legalCheck"],
    emailCheck : json['emailCheck'] is bool?json["emailCheck"]?1:0:json["emailCheck"],
    id : json['id'],
    avatar : json['avatar'],
    estado : json['estado'],
    salario: json["salario"]
  );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['uuid'] = uuid;
    data['nombres'] = nombres;
    data['apPaterno'] = apPaterno;
    data['apMaterno'] = apMaterno;
    data['correoElectronico'] = correoElectronico;
    data['documentoIdentidad'] = documentoIdentidad;
    data['legalCheck'] = legalCheck;
    data['emailCheck'] = emailCheck;
    data['id'] = id;
    data['avatar'] = avatar;
    data['estado'] = estado;
    return data;
  }
  Map<String, dynamic> toJsonUpdate() {
    final data = <String, dynamic>{};
    data['nombres'] = nombres;
    data['apPaterno'] = apPaterno;
    data['apMaterno'] = apMaterno;
    return data;
  }
}