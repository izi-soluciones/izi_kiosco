class Currency {
  int id;
  String nombre;
  String simbolo;
  int monedaReferencia;
  num exRate;
  num exRatePrincipal;
  int monedaContribuyenteId;
  int contribuyente;
  dynamic customData;

  Currency(
      {required this.id,
      required this.nombre,
      required this.simbolo,
      required this.monedaReferencia,
      required this.exRate,
      required this.customData,
      required this.contribuyente,
      required this.exRatePrincipal,
      required this.monedaContribuyenteId});

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
      id: json["id"] ?? 0,
      nombre: json["nombre"] ?? "",
      simbolo: json["simbolo"] ?? "Bs",
      monedaReferencia: json["monedaReferencia"] ?? 150,
      exRate: json["exRate"] ?? 1,
      customData: json["customData"],
      contribuyente: json["contribuyente"] ?? 0,
      exRatePrincipal: json["exRatePrincipal"] ?? 1,
      monedaContribuyenteId: json["monedaContribuyenteId"] ?? 0);

  Map<String, dynamic> toJson() => {
    "contribuyente": contribuyente,
    "customData": customData,
    "exRate": exRate,
    "exRatePrincipal":exRatePrincipal,
    "id":id,
    "monedaContribuyenteId":monedaContribuyenteId,
    "monedaReferencia":monedaReferencia,
    "nombre":nombre,
    "simbolo":simbolo
  };
}
