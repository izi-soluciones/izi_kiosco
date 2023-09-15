class PaymentMethod {
  int id;
  int codigoSiat;
  String nombre;
  dynamic custom;

  PaymentMethod(
      {required this.id,
      required this.codigoSiat,
      required this.nombre,
      required this.custom});

  factory PaymentMethod.fromJson(Map<String,dynamic> json)=>PaymentMethod(
      id: json["id"] ?? 0,
      codigoSiat: json["codigoSiat"] ?? 5,
      nombre: json["nombre"] ?? "",
      custom: json["custom"]
  );
}
