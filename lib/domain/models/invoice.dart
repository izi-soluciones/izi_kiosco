class Invoice {

  int? isIzi;
  String? uuid;
  int? tipoFactura;
  int? isApi;
  dynamic actividadEconomica;
  String? contribuyenteApi;
  String? emisor;
  String? razonSocialEmisor;
  String? comprador;
  String? razonSocial;
  String? correoElectronicoComprador;
  int? caja;
  num? descuentos;
  num? descuentosImpuesto;
  int? tipoCompra;
  String? terminosPago;
  int? prefactura;
  num? giftCards;
  num? contribuyente;
  num? giftCardsImpuesto;
  int? anulada;
  String? notaInterna;
  bool? isCuentaCobro;
  String? fechaPago;
  String fecha;
  bool? isPruebas;
  int? pagada;
  int? sucursal;
  String? sucursalDireccion;
  dynamic customFactura;
  List<Items>? listaItems;
  num? monto;
  num? montoImpuesto;
  num? montoTotalImpuesto;
  num? sincredito;
  num? sincreditoImpuesto;
  num? montoTotal;
  String? pdfCarta;
  String? pdfRollo;
  int? usuarioPreCreacion;
  int? numero;
  int? numeroPrefactura;
  String? autorizacion;
  String? validadorUnico;
  String? id;
  String? qr;
  num? iceVariable;
  num? iceFijo;
  String? control;
  String? concepto;
  int? contingencia;
  int? sucursalCompra;
  String? customCasosEspeciales;
  String? creado;
  int? almacen;
  int? usuarioCreacion;
  int? usuarioAnulacion;
  int? usuarioModificacion;
  int? usuarioCobro;
  int? usuarioPago;
  String? usuarioPreCreacionNombre;
  String? usuarioCreacionNombre;
  String? usuarioAnulacionNombre;
  String? usuarioModificacionNombre;
  String? usuarioCobroNombre;
  String? usuarioPagoNombre;
  bool? desdeInventario;
  int? clienteId;
  int? numeroOrden;
  int? numeroCustom;

  Invoice(
      {
        required this.comprador,
        required this.descuentos,
        required this.emisor,
        required this.fecha,
        this.fechaPago,
        this.isCuentaCobro,
        required this.prefactura,
        required this.razonSocial,
        required this.razonSocialEmisor,
        this.sucursal,
        this.sucursalDireccion,
        this.tipoFactura,
        required this.listaItems,
        this.customFactura,

        this.desdeInventario,
        this.isIzi,
        this.uuid,
        this.isApi,
        this.clienteId,
        this.contribuyenteApi,
        this.correoElectronicoComprador,
        this.caja,
        this.tipoCompra,
        this.terminosPago,
        this.anulada,
        this.notaInterna,
        this.isPruebas,
        this.pagada,
        this.monto,
        this.montoTotal,
        this.pdfCarta,
        this.pdfRollo,
        this.usuarioPreCreacion,
        this.numero,
        this.autorizacion,
        this.validadorUnico,
        this.id,
        this.qr,
        this.iceVariable,
        this.iceFijo,
        this.control,
        this.concepto,
        this.contingencia,
        this.sucursalCompra,
        this.customCasosEspeciales,
        this.creado,
        this.almacen,
        this.usuarioCreacion,
        this.usuarioAnulacion,
        this.usuarioModificacion,
        this.usuarioCobro,
        this.usuarioPago,
        this.usuarioPreCreacionNombre,
        this.usuarioCreacionNombre,
        this.usuarioAnulacionNombre,
        this.usuarioModificacionNombre,
        this.usuarioCobroNombre,
        this.usuarioPagoNombre,
        this.actividadEconomica,
        this.numeroPrefactura,
        this.montoImpuesto,
        this.sincredito,
        this.sincreditoImpuesto,
        this.descuentosImpuesto,
        this.giftCards,
        this.giftCardsImpuesto,
        this.montoTotalImpuesto,
        this.contribuyente,
        this.numeroOrden,
        this.numeroCustom
      });




  factory Invoice.fromJson(Map<String, dynamic> json){
    return Invoice(
      listaItems :json["listaItems"]!=null && json["listaItems"] is Iterable<dynamic>?List.from(json["listaItems"]).map((e) => Items.fromJson(e)).toList():null,
      isIzi : json['isIzi'],
      uuid : json['uuid'],
      tipoFactura : json['tipoFactura'],
      isApi : json['isApi'],
      contribuyenteApi : json["contribuyenteApi"],
      emisor : json['emisor'],
      razonSocialEmisor : json['razonSocialEmisor'],
      comprador : json['comprador'],
      razonSocial : json['razonSocial'],
      correoElectronicoComprador : json["correoElectronicoComprador"],
      caja : json["caja"],
      descuentos : json['descuentos'],
      tipoCompra : json['tipoCompra'],
      terminosPago : json["terminosPago"],
      prefactura : json['prefactura'],
      anulada : json['anulada'],
      notaInterna : json["notaInterna"],
      isCuentaCobro : json['isCuentaCobro'],
      fechaPago : json['fechaPago'],
      fecha : json['fecha']??"2001-01-01",
      isPruebas : json['isPruebas'],
      pagada : json['pagada'],
      sucursal : json['sucursal'],
      sucursalDireccion : json['sucursalDireccion'],
      customFactura : json['customFactura'],
      monto : json['monto'],
        montoImpuesto : json['montoImpuesto'],
      montoTotal : json['montoTotal'],
      pdfCarta : json['pdfCarta'],
      pdfRollo : json['pdfRollo'],
      usuarioPreCreacion : json['usuarioPreCreacion'],
      numero : json['numero'],
      autorizacion : json['autorizacion'],
      validadorUnico : json['validadorUnico'],
      id : json["id"]!=null?json['id'].toString():null,
      qr : json["qr"],
      iceVariable : json["iceVariable"],
      iceFijo : json["iceFijo"],
      control : json["control"],
      concepto : json["concepto"],
      contingencia : json['contingencia'],
      sucursalCompra : json["sucursalCompra"],
      customCasosEspeciales : json["customCasosEspeciales"],
      creado : json['creado'],
      almacen : json["almacen"],
      usuarioCreacion : json["usuarioCreacion"],
      usuarioAnulacion : json["usuarioAnulacion"],
      usuarioModificacion : json["usuarioModificacion"],
      usuarioCobro : json["usuarioCobro"],
      usuarioPago : json["usuarioPago"],
      usuarioPreCreacionNombre : json['usuarioPreCreacionNombre'],
      usuarioCreacionNombre : json['usuarioCreacionNombre'],
      usuarioAnulacionNombre : json['usuarioAnulacionNombre'],
      usuarioModificacionNombre : json['usuarioModificacionNombre'],
      usuarioCobroNombre : json['usuarioCobroNombre'],
      usuarioPagoNombre : json['usuarioPagoNombre'],
      numeroPrefactura: json['numeroPrefactura'],
      clienteId: json['clienteId'],
      sincredito: json['sincredito'],
      sincreditoImpuesto: json['sincreditoImpuesto'],
      descuentosImpuesto: json['descuentosImpuesto'],
      giftCards: json["giftCards"],
        giftCardsImpuesto: json["giftCardsImpuesto"],
      montoTotalImpuesto: json["montoTotalImpuesto"],
      contribuyente: json["contribuyente"],
      numeroOrden: json["numeroOrden"],
      numeroCustom: json["numeroCustom"] is int?json["numeroCustom"]:null,
      actividadEconomica: json["actividadEconomica"],
    );
  }

  @override
  String toString() {
    return 'Invoice{isIzi: $isIzi, uuid: $uuid, tipoFactura: $tipoFactura, isApi: $isApi, actividadEconomica: $actividadEconomica, contribuyenteApi: $contribuyenteApi, emisor: $emisor, razonSocialEmisor: $razonSocialEmisor, comprador: $comprador, razonSocial: $razonSocial, correoElectronicoComprador: $correoElectronicoComprador, caja: $caja, descuentos: $descuentos, descuentosImpuesto: $descuentosImpuesto, tipoCompra: $tipoCompra, terminosPago: $terminosPago, prefactura: $prefactura, giftCards: $giftCards, giftCardsImpuesto: $giftCardsImpuesto, anulada: $anulada, notaInterna: $notaInterna, isCuentaCobro: $isCuentaCobro, fechaPago: $fechaPago, fecha: $fecha, isPruebas: $isPruebas, pagada: $pagada, sucursal: $sucursal, sucursalDireccion: $sucursalDireccion, customFactura: $customFactura, listaItems: $listaItems, monto: $monto, montoImpuesto: $montoImpuesto, montoTotalImpuesto: $montoTotalImpuesto, sincredito: $sincredito, sincreditoImpuesto: $sincreditoImpuesto, montoTotal: $montoTotal, pdfCarta: $pdfCarta, pdfRollo: $pdfRollo, usuarioPreCreacion: $usuarioPreCreacion, numero: $numero, numeroPrefactura: $numeroPrefactura, autorizacion: $autorizacion, validadorUnico: $validadorUnico, id: $id, qr: $qr, iceVariable: $iceVariable, iceFijo: $iceFijo, control: $control, concepto: $concepto, contingencia: $contingencia, sucursalCompra: $sucursalCompra, customCasosEspeciales: $customCasosEspeciales, creado: $creado, almacen: $almacen, usuarioCreacion: $usuarioCreacion, usuarioAnulacion: $usuarioAnulacion, usuarioModificacion: $usuarioModificacion, usuarioCobro: $usuarioCobro, usuarioPago: $usuarioPago, usuarioPreCreacionNombre: $usuarioPreCreacionNombre, usuarioCreacionNombre: $usuarioCreacionNombre, usuarioAnulacionNombre: $usuarioAnulacionNombre, usuarioModificacionNombre: $usuarioModificacionNombre, usuarioCobroNombre: $usuarioCobroNombre, usuarioPagoNombre: $usuarioPagoNombre, desdeInventario: $desdeInventario, clienteId: $clienteId}';
  }
}

class Items {
  String articulo;
  num? cantidad;
  num? precioUnitario;
  num? precioTotal;
  num? valor;
  num? valorTotal;
  num? precioUnitarioImpuesto;
  num? descuento;
  num? descuentoImpuesto;
  num? precioTotalImpuesto;
  dynamic codigoInventario;
  dynamic codigo;


  Items({
    required this.articulo,
    required this.cantidad,
    this.precioUnitario,
    this.precioTotal,
    this.valor,
    this.valorTotal,
    this.descuento,
    this.descuentoImpuesto,
    this.precioUnitarioImpuesto,
    this.precioTotalImpuesto,
    this.codigoInventario,
    this.codigo
  });



  @override
  String toString() {
    return 'Items{articulo: $articulo, cantidad: $cantidad, precioUnitario: $precioUnitario, precioTotal: $precioTotal, valor: $valor, valorTotal: $valorTotal}';
  }

  Map<String, dynamic> toJsonSale() => {
    "articulo": articulo,
    "cantidad": cantidad,
    "precioUnitario": precioUnitario
  };
  Map<String, dynamic> toJsonExpense() => {
    "articulo": articulo,
    "cantidad": cantidad,
    "valor":valor,
    "valorTotal":valorTotal
  };


  factory Items.fromJson(Map<String, dynamic> json){
    return Items(
        articulo : json['articulo'],
        cantidad : json['cantidad'] is String?0:json["cantidad"],
        precioTotal : json['precioTotal'],
        precioUnitario : json['precioUnitario'] is String?0:json["precioUnitario"],
        valorTotal: json["valorTotal"],
        valor: json["valor"],
      descuento: json["descuento"],
        descuentoImpuesto: json["descuentoImpuesto"],
      precioUnitarioImpuesto: json["precioUnitarioImpuesto"],
      precioTotalImpuesto: json["precioTotalImpuesto"],
      codigo: json["codigo"],
      codigoInventario: json["codigoInventario"]
    );
  }


}
