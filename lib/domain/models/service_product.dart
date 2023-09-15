class ServiceProduct {
  String codigoActividad;
  int codigoProducto;
  String descripcionProducto;

  ServiceProduct(
      {required this.codigoActividad,
      required this.codigoProducto,
      required this.descripcionProducto});

  factory ServiceProduct.fromJson(Map<String, dynamic> json) => ServiceProduct(
      codigoActividad: json["codigoActividad"],
      codigoProducto: json["codigoProducto"],
      descripcionProducto: json["descripcionProducto"]);
}
