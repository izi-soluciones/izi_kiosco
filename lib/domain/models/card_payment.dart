class CardPayment{
  String response;
  String date;
  String hour;
  String? cardNumber;
  /// Reference sent to the Izify POS in the `/pay` body. Kept so the caller can
  /// poll `/payment-status/{reference}` as a fallback to the WebSocket.
  String? reference;

  CardPayment({
    required this.response,
    required this.cardNumber,
    required this.date,
    required this.hour,
    this.reference,
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