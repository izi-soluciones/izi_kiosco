class PrintLogDto {
  String eventoId;
  int? dispositivoId;
  String? dispositivoNombre;
  int? cajaId;
  int? comandaId;
  String? comandaUuid;
  int? facturaId;
  int? numeroOrden;
  int? numeroOrdenCustom;
  String tipoDocumento;
  String via;
  String resultado;
  int intento;
  String? errorMensaje;
  int? duracionMs;
  String? userAgent;
  String? versionApp;
  String fechaDispositivo;

  PrintLogDto({
    required this.eventoId,
    this.dispositivoId,
    this.dispositivoNombre,
    this.cajaId,
    this.comandaId,
    this.comandaUuid,
    this.facturaId,
    this.numeroOrden,
    this.numeroOrdenCustom,
    required this.tipoDocumento,
    required this.via,
    required this.resultado,
    required this.intento,
    this.errorMensaje,
    this.duracionMs,
    this.userAgent,
    this.versionApp,
    required this.fechaDispositivo,
  });

  Map<String, dynamic> toJson() => {
        "eventoId": eventoId,
        "dispositivoId": dispositivoId,
        "dispositivoNombre": dispositivoNombre,
        "cajaId": cajaId,
        "comandaId": comandaId,
        "comandaUuid": comandaUuid,
        "facturaId": facturaId,
        "numeroOrden": numeroOrden,
        "numeroOrdenCustom": numeroOrdenCustom,
        "tipoDocumento": tipoDocumento,
        "via": via,
        "resultado": resultado,
        "intento": intento,
        "errorMensaje": errorMensaje,
        "duracionMs": duracionMs,
        "userAgent": userAgent,
        "versionApp": versionApp,
        "fechaDispositivo": fechaDispositivo,
      };

  factory PrintLogDto.fromJson(Map<String, dynamic> json) => PrintLogDto(
        eventoId: json["eventoId"] ?? "",
        dispositivoId: json["dispositivoId"],
        dispositivoNombre: json["dispositivoNombre"],
        cajaId: json["cajaId"],
        comandaId: json["comandaId"],
        comandaUuid: json["comandaUuid"],
        facturaId: json["facturaId"],
        numeroOrden: json["numeroOrden"],
        numeroOrdenCustom: json["numeroOrdenCustom"],
        tipoDocumento: json["tipoDocumento"] ?? "",
        via: json["via"] ?? "",
        resultado: json["resultado"] ?? "",
        intento: json["intento"] ?? 1,
        errorMensaje: json["errorMensaje"],
        duracionMs: json["duracionMs"],
        userAgent: json["userAgent"],
        versionApp: json["versionApp"],
        fechaDispositivo: json["fechaDispositivo"] ?? "",
      );
}
