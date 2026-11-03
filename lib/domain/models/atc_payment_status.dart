import 'package:izi_kiosco/domain/models/card_payment.dart';

/// Respuesta de `GET /v2/pago/:ref` del servidor POS.
class AtcPaymentStatus {
  static const String approved = "aprobado";
  static const String rejected = "rechazado";
  static const String notFound = "noEncontrado";
  static const String inProgress = "enCurso";
  static const String noResponse = "sinRespuesta";

  final String ref;
  final String estado;
  final dynamic resultado;
  final bool confirmado;
  // El encargado lo marcó resuelto en la página de contingencia
  final bool resuelto;

  AtcPaymentStatus(
      {required this.ref,
      required this.estado,
      required this.resultado,
      required this.confirmado,
      this.resuelto = false});

  factory AtcPaymentStatus.fromJson(Map json) => AtcPaymentStatus(
      ref: json["ref"]?.toString() ?? "",
      estado: json["estado"]?.toString() ?? "",
      resultado: json["resultado"],
      confirmado: json["confirmado"] == true,
      resuelto: json["resuelto"] == true);

  /// Aprobado para el servidor y para la regla del kiosko: `status == true`, `data` y `cod_respuesta == "00"`.
  bool get isApproved =>
      estado == approved &&
      resultado is Map &&
      resultado["status"] == true &&
      resultado["data"] is Map &&
      resultado["data"]["cod_respuesta"] == "00";

  bool get isRejected => !isApproved && estado == rejected;

  bool get isNotFound => !isApproved && estado == notFound;

  CardPayment? get cardPayment =>
      isApproved ? CardPayment.fromJsonATC(resultado["data"]) : null;
}
