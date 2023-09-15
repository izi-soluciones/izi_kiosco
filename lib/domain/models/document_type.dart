class DocumentType {
  int codigoClasificador;
  String descripcion;

  DocumentType(
      {required this.codigoClasificador,
        required this.descripcion});

  factory DocumentType.fromJson(Map<String, dynamic> json) => DocumentType(
      codigoClasificador: json["codigoClasificador"],
      descripcion: json["descripcion"]);

  Map<String,dynamic> toJson()=>{
    "codigoClasificador":codigoClasificador,
    "descripcion":descripcion
  };
}
