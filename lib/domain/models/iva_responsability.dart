class IvaResponsability {
  String codigo;
  String nombre;

  IvaResponsability(
      {required this.codigo,
        required this.nombre});

  factory IvaResponsability.fromJson(Map<String, dynamic> json) => IvaResponsability(
      codigo: json["codigo"],
      nombre: json["nombre"]);

  Map<String,dynamic> toJson()=>{
    "codigo":codigo,
    "nombre":nombre
  };
}
