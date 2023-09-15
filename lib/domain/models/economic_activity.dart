class EconomicActivity{
  String codigoCaeb;
  String descripcion;
  String tipoActividad;

  EconomicActivity({
    required this.codigoCaeb,
    required this.descripcion,
    required this.tipoActividad
});

  factory EconomicActivity.fromJson(Map<String, dynamic> json) =>
      EconomicActivity(
          codigoCaeb: json["codigoCaeb"]?? "",
          descripcion: json["descripcion"]??"",
          tipoActividad: json["tipoActividad"]??""
      );
}