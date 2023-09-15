class Comanda {
  int? almacen;
  int id;
  int? caja;
  List<ComandaPdf> comandasPdf;
  bool consumoInterno;
  DateTime creado;
  dynamic custom;
  num descuentos;
  String? detallePdf;
  String? emisor;
  int? factura;
  int facturada;
  DateTime fecha;
  dynamic historial;
  int? isAPi;
  bool isTerminada;
  List<ItemComanda> listaItems;
  String? mesa;
  num monto;
  num? montoTotal;
  String? notaInterna;
  num? numero;
  num? numeroFactura;
  bool paraLlevar;
  String? pdfRollo;
  int? sucursal;
  String? uuid;
  int anulada;

  Comanda(
      {required this.id,
      this.caja,
      required this.comandasPdf,
      required this.consumoInterno,
      required this.creado,
      this.custom,
      required this.descuentos,
      this.detallePdf,
      this.emisor,
      this.factura,
      required this.facturada,
      required this.fecha,
      this.historial,
      this.isAPi,
      this.almacen,
      required this.isTerminada,
      required this.listaItems,
      this.mesa,
      required this.anulada,
      required this.monto,
      this.montoTotal,
      this.notaInterna,
      this.numero,
      this.numeroFactura,
      required this.paraLlevar,
      this.pdfRollo,
      this.sucursal,
      this.uuid});

  Comanda copyWith({int? anulada, bool? consumoInterno}) {
    return Comanda(
        almacen: almacen,
        id: id,
        consumoInterno: consumoInterno ?? this.consumoInterno,
        creado: creado,
        descuentos: descuentos,
        facturada: facturada,
        fecha: fecha,
        isTerminada: isTerminada,
        listaItems: listaItems,
        anulada: anulada ?? this.anulada,
        monto: monto,
        paraLlevar: paraLlevar,
        sucursal: sucursal,
        caja: caja,
        comandasPdf: comandasPdf,
        custom: custom,
        detallePdf: detallePdf,
        emisor: emisor,
        factura: factura,
        historial: historial,
        isAPi: isAPi,
        mesa: mesa,
        montoTotal: montoTotal,
        notaInterna: notaInterna,
        numero: numero,
        numeroFactura: numeroFactura,
        pdfRollo: pdfRollo,
        uuid: uuid);
  }

  factory Comanda.fromJson(Map<String, dynamic> json) => Comanda(
      id: json["id"] ?? 0,
      almacen: json["almacen"],
      caja: json["caja"],
      comandasPdf: json["comandasPdf"] != null &&
              json["comandasPdf"] is Iterable<dynamic>
          ? List.from(json["comandasPdf"])
              .map((e) => ComandaPdf.fromJson(e))
              .toList()
          : [],
      consumoInterno: json["consumoInterno"] ?? false,
      creado: DateTime.tryParse(json["creado"]) ?? DateTime.now(),
      custom: json["custom"],
      descuentos: json["descuentos"] ?? 0,
      detallePdf: json["detallePdf"],
      emisor: json["emisor"],
      factura: json["factura"],
      facturada: json["facturada"] ?? 0,
      fecha: DateTime.tryParse(json["fecha"]) ?? DateTime.now(),
      historial: json["historial"],
      isAPi: json["isAPi"],
      isTerminada: json["isTerminada"] ?? false,
      listaItems: json["listaItems"] != null &&
              json["listaItems"] is Iterable<dynamic>
          ? List.from(json["listaItems"]).map((e) => ItemComanda.fromJson(e)).toList()
          : [],
      mesa: json["mesa"],
      monto: json["monto"] ?? 0,
      montoTotal: json["montoTotal"],
      notaInterna: json["notaInterna"],
      numero: json["numero"],
      numeroFactura: json["numeroFactura"],
      paraLlevar: json["paraLlevar"] ?? false,
      pdfRollo: json["pdfRollo"],
      sucursal: json["sucursal"],
      anulada: json["anulada"] ?? 0,
      uuid: json["uuid"]);
}

class ComandaPdf {
  int? centroProduccion;
  bool? generado;
  String? pdf;

  ComandaPdf({this.centroProduccion, this.generado, this.pdf});

  factory ComandaPdf.fromJson(Map<dynamic, dynamic> json) => ComandaPdf(
      centroProduccion: json["centroProduccion"],
      generado: json["generado"],
      pdf: json["pdf"]);
}

class ItemComanda {
  num? cantidad;
  String? codigo;
  dynamic customItem;
  String? descripcion;
  String? imagen;
  int? item;
  dynamic modificadores;
  dynamic modificadoresEdit;
  String nombre;
  int? ordenProduccion;
  num? precioModificadores;
  num? precioTotal;
  num? precioUnitario;
  num? valor;
  int? categoriaId;
  String? categoria;

  ItemComanda(
      {this.cantidad,
      this.codigo,
      this.customItem,
      this.descripcion,
      this.imagen,
      this.item,
      this.modificadores,
      this.modificadoresEdit,
      required this.nombre,
      this.ordenProduccion,
      this.precioModificadores,
      this.precioTotal,
      this.precioUnitario,
        this.categoriaId,
        this.categoria,
      this.valor});
  factory ItemComanda.fromJson(Map<dynamic, dynamic> json) => ItemComanda(
      nombre: json["nombre"] ?? "",
      cantidad: json["cantidad"],
      codigo: json["codigo"],
      customItem: json["customItem"],
      descripcion: json["descripcion"],
      imagen: json["imagen"],
      item: json["item"],
      modificadores: json["modificadores"],
      modificadoresEdit: json["modificadoresEdit"],
      ordenProduccion: json["ordenProduccion"],
      precioModificadores: json["precioModificadores"],
      precioTotal: json["precioTotal"],
      categoriaId: json["categoriaId"],
      categoria: json["categoria"],
      precioUnitario: json["precioUnitario"],
      valor: json["valor"]);
}
