class CardPayment{
  String response;
  String date;
  String hour;
  String? cardNumber;

  CardPayment({
    required this.response,
    required this.cardNumber,
    required this.date,
    required this.hour
});

  factory CardPayment.fromJson(Map json)=>CardPayment(
      response: json["mensaje"] ?? "",
      cardNumber:json["pan"]??"",
      date: json["fecha"]??"",
      hour: json["hora"]??"");
  // El servidor POS manda codigo_autorizacion, ult_4_digitos, fecha_transac (MMDD) y hora_transac (HHMM);
  // los nombres viejos se siguen leyendo. Los últimos 4 van enmascarados como tarjeta completa.
  factory CardPayment.fromJsonATC(Map json)=>CardPayment(
      response: (json["codigo_autorizacion"] ?? json["mensaje"] ?? "").toString(),
      cardNumber: json["ult_4_digitos"] != null ? "****${json["ult_4_digitos"]}" : (json["pan"] ?? "").toString(),
      date: (json["fecha_transac"] ?? json["fecha"] ?? "").toString(),
      hour: (json["hora_transac"] ?? json["hora"] ?? "").toString());

  factory CardPayment.fromJsonStorage(Map json)=>CardPayment(
      response: json["respuesta"] ?? "",
      cardNumber:json["tarjeta"],
      date: json["fecha"],
      hour: json["hora"]);

  Map toJson()=>{
    "respuesta": response,
    "fecha": date,
    "hora": hour,
    "tarjeta": cardNumber
  };

  }