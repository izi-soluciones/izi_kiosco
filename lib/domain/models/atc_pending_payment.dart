enum AtcPaymentKind { retail, comanda }

/// Un intento de cobro ATC que el kiosko guarda antes de llamar al POS, con lo
/// que necesita `markPaymentATC` para completarlo si el resultado llega tarde.
class AtcPendingPayment {
  final String ref;
  final String uuid;
  final int? intentoPago;
  final AtcPaymentKind kind;
  final String amount;
  final DateTime createdAt;
  // La orden (uuid del PaymentObj): en comanda cada intento tiene su propio cobro (uuid)
  final String orderUuid;

  AtcPendingPayment(
      {required this.ref,
      required this.uuid,
      required this.intentoPago,
      required this.kind,
      required this.amount,
      required this.createdAt,
      String? orderUuid})
      : orderUuid = orderUuid ?? uuid;

  /// Lo que el cliente le muestra a caja: los últimos 6 caracteres del ref.
  String get shortCode =>
      ref.length > 6 ? ref.substring(ref.length - 6) : ref;

  factory AtcPendingPayment.fromJson(Map json) => AtcPendingPayment(
      ref: json["ref"],
      uuid: json["uuid"] ?? "",
      intentoPago: json["intentoPago"],
      kind: json["kind"] == AtcPaymentKind.comanda.name
          ? AtcPaymentKind.comanda
          : AtcPaymentKind.retail,
      amount: json["amount"] ?? "",
      createdAt: DateTime.parse(json["createdAt"]),
      orderUuid: json["orderUuid"]);

  Map<String, dynamic> toJson() => {
        "ref": ref,
        "uuid": uuid,
        "intentoPago": intentoPago,
        "kind": kind.name,
        "amount": amount,
        "createdAt": createdAt.toIso8601String(),
        "orderUuid": orderUuid
      };
}
