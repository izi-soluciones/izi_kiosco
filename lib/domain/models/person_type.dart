class PersonType {
  String codigo;
  String nombre;

  PersonType(
      {required this.codigo,
        required this.nombre});

  factory PersonType.fromJson(Map<String, dynamic> json) => PersonType(
      codigo: json["codigo"],
      nombre: json["nombre"]);

  Map<String,dynamic> toJson()=>{
    "codigo":codigo,
    "nombre":nombre
  };
}
