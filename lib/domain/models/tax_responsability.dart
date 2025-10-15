class TaxResponsability {
  String? codigo;
  String nombre;

  TaxResponsability(
      {required this.codigo,
        required this.nombre});

  factory TaxResponsability.fromJson(Map<String, dynamic> json) => TaxResponsability(
      codigo: json["codigo"],
      nombre: json["nombre"]);

  Map<String,dynamic> toJson()=>{
    "codigo":codigo,
    "nombre":nombre
  };
}
