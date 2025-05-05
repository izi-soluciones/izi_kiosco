class User {
  User({
    this.uuid,
    required this.nombres,
    required this.apellidos,
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
  String apellidos;
  String? correoElectronico;
  String? documentoIdentidad;
  bool? legalCheck;
  bool? emailCheck;
  String id;
  int? avatar;
  bool? estado;
  num? salario;

  factory User.fromJson(Map<String, dynamic> json)=>User(
    uuid : json['uuid'],
    nombres : json['nombres'],
    apellidos : json['apellidos'],
    correoElectronico : json['correoElectronico'],
    documentoIdentidad : json['documentoIdentidad'],
    legalCheck : json['legalCheck'] is bool?json["legalCheck"]:false,
    emailCheck : json['emailCheck'] is bool?json["emailCheck"]:false,
    id : json['id'],
    avatar : json['avatar'],
    estado : json['estado'],
    salario: json["salario"]
  );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['uuid'] = uuid;
    data['nombres'] = nombres;
    data['apellidos'] = apellidos;
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
    data['apellidos'] = apellidos;
    return data;
  }
}