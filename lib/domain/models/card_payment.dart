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
  factory CardPayment.fromJsonATC(Map json)=>CardPayment(
      response: json["mensaje"] ?? "",
      cardNumber:json["pan"] ?? "",
      date: json["fecha"] ?? "",
      hour: json["hora"] ?? "");

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