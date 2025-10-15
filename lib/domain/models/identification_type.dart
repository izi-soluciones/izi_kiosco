class IdentificationType {
  String codigo;
  String nombre;

  IdentificationType(
      {required this.codigo,
        required this.nombre});

  factory IdentificationType.fromJson(Map<String, dynamic> json) => IdentificationType(
      codigo: json["codigo"],
      nombre: json["nombre"]);

  Map<String,dynamic> toJson()=>{
    "codigo":codigo,
    "nombre":nombre
  };
}
