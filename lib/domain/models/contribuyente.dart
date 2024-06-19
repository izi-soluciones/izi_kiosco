class Contribuyente {
  Contribuyente({
    this.id,
    this.nombre,
    this.razonSocial,
    this.administrador,
    this.nit,
    this.correoElectronico,
    this.plan,
    this.logo,
    this.logoId,
    this.logoOrientation,
    this.estado,
    this.creado,
    this.bloqueadoPago,
    this.apiClientId,
    this.sucursalApi,
    this.actividadApi,
    this.secretUuid,
    this.customData,
    this.habilitadoRestaurantes,
    this.habilitadoAnalitica,
    this.habilitadoVentas,
    this.habilitadoIntegracion,
    this.habilitadoInventarios,
    this.habilitadoTerceros,
    this.habilitadoCobros,
    this.habilitadoFacturacion,
    this.habilitadoTerminal,
    this.habilitadoMesas,
    this.usaSiat,
    this.configTerminada,
    this.configCobros,
    this.config,
    this.totalSucursales,
    this.sucursales,
    this.llaves,
    this.tiposFactura,
    this.camposExtra,
    this.autorizaciones,
    this.usuarios,
    required this.actividadesEconomicas,
    required this.autorizadosAPI
  });

  @override
  String toString() {
    return 'Contribuyente{id: $id, nombre: $nombre, razonSocial: $razonSocial, administrador: $administrador, nit: $nit, correoElectronico: $correoElectronico, plan: $plan, logo: $logo, logoId: $logoId, logoOrientation: $logoOrientation, estado: $estado, creado: $creado, bloqueadoPago: $bloqueadoPago, apiClientId: $apiClientId, sucursalApi: $sucursalApi, actividadApi: $actividadApi, secretUuid: $secretUuid, customData: $customData, habilitadoRestaurantes: $habilitadoRestaurantes, habilitadoAnalitica: $habilitadoAnalitica, habilitadoVentas: $habilitadoVentas, habilitadoIntegracion: $habilitadoIntegracion, habilitadoInventarios: $habilitadoInventarios, habilitadoTerceros: $habilitadoTerceros, habilitadoCobros: $habilitadoCobros, habilitadoFacturacion: $habilitadoFacturacion, usaSiat: $usaSiat, configTerminada: $configTerminada, configCobros: $configCobros, config: $config, totalSucursales: $totalSucursales, sucursales: $sucursales, actividadesEconomicas: $actividadesEconomicas, autorizadosAPI: $autorizadosAPI, llaves: $llaves, tiposFactura: $tiposFactura, camposExtra: $camposExtra, autorizaciones: $autorizaciones, usuarios: $usuarios}';
  }

  int? id;
  String? nombre;
  String? razonSocial;
  int? administrador;
  String? nit;
  String? correoElectronico;
  int? plan;
  String? logo;
  int? logoId;
  String? logoOrientation;
  int? estado;
  String? creado;
  bool? bloqueadoPago;
  int? apiClientId;
  int? sucursalApi;
  int? actividadApi;
  String? secretUuid;
  dynamic customData;
  bool? habilitadoRestaurantes;
  bool? habilitadoAnalitica;
  bool? habilitadoVentas;
  bool? habilitadoIntegracion;
  bool? habilitadoInventarios;
  bool? habilitadoTerceros;
  bool? habilitadoCobros;
  bool? habilitadoFacturacion;
  bool? habilitadoTerminal;
  bool? habilitadoMesas;
  bool? usaSiat;
  bool? configTerminada;
  dynamic configCobros;
  dynamic config;
  int? totalSucursales;
  List<Sucursal>? sucursales;
  dynamic actividadesEconomicas;
  dynamic autorizadosAPI;
  Llaves? llaves;
  dynamic tiposFactura;
  dynamic camposExtra;
  dynamic autorizaciones;
  List<Usuarios>? usuarios;

  factory Contribuyente.fromJsonList(Map<String, dynamic> json)=>Contribuyente(
    id : json['id'],
    nombre : json['nombre'],
    razonSocial : json['razonSocial'],
    administrador : json['administrador'],
    nit : json['nit'],
    correoElectronico : json['correoElectronico'],
    plan : json['plan'],
    logo : json["logo"]!=null?json['logo'].toString():null,
    logoId : json['logoId'],
    logoOrientation : json['logoOrientation'],
    estado : json['estado'],
    creado : json['creado'],
    bloqueadoPago : json['bloqueadoPago'],
    apiClientId : json["apiClientId "],
    sucursalApi : json['sucursalApi'],
    actividadApi : json['actividadApi'],
    secretUuid : json['secretUuid'],
    customData : json["customData"] is Map<String,dynamic>?json["customData"]:null,
    habilitadoRestaurantes : json['habilitadoRestaurantes'],
    habilitadoAnalitica : json['habilitadoAnalitica'],
    habilitadoVentas : json['habilitadoVentas'],
    habilitadoIntegracion : json['habilitadoIntegracion'],
    habilitadoInventarios : json['habilitadoInventarios'],
    habilitadoTerceros : json['habilitadoTerceros'],
    habilitadoCobros : json['habilitadoCobros'],
    habilitadoFacturacion : json['habilitadoFacturacion'],
    habilitadoTerminal : json['habilitadoTerminal'],
      habilitadoMesas : json['habilitadoMesas'],
    usaSiat : json['usaSiat'],
    configTerminada : json['configTerminada'],
    configCobros : json['configCobros'],
    config : json["config"],
    totalSucursales : json['totalSucursales'],
    sucursales : [],
    actividadesEconomicas : json["actividadesEconomicas"] ?? [],
    autorizadosAPI :  json["autorizadosAPI"] ?? [],
    llaves : null,
    tiposFactura : [],
    camposExtra : [],
    autorizaciones : json["autorizaciones"],
    usuarios : []
  );

  factory Contribuyente.fromJson(Map<String, dynamic> json)=>Contribuyente(
      id : json['id'],
      nombre : json['nombre'],
      razonSocial : json['razonSocial'],
      administrador : json['administrador'],
      nit : json['nit'],
      correoElectronico : json['correoElectronico'],
      plan : json['plan'],
      logo : json["logo"]!=null?json['logo'].toString():null,
      logoId : json['logoId'],
      logoOrientation : json['logoOrientation'],
      estado : json['estado'],
      creado : json['creado'],
      bloqueadoPago : json['bloqueadoPago'],
      apiClientId : json["apiClientId "],
      sucursalApi : json['sucursalApi'],
      actividadApi : json['actividadApi'],
      secretUuid : json['secretUuid'],
      customData : json["customData"],
      habilitadoRestaurantes : json['habilitadoRestaurantes'],
      habilitadoAnalitica : json['habilitadoAnalitica'],
      habilitadoVentas : json['habilitadoVentas'],
      habilitadoIntegracion : json['habilitadoIntegracion'],
      habilitadoInventarios : json['habilitadoInventarios'],
      habilitadoTerceros : json['habilitadoTerceros'],
      habilitadoCobros : json['habilitadoCobros'],
      habilitadoFacturacion : json['habilitadoFacturacion'],
      habilitadoTerminal : json['habilitadoTerminal'],
      habilitadoMesas : json['habilitadoMesas'],
      usaSiat : json['usaSiat'],
      configTerminada : json['configTerminada'],
      configCobros : json['configCobros'],
      config : json['config'],
      totalSucursales : json['totalSucursales'],
      sucursales : List.from(json["sucursales"] is Iterable?json["sucursales"]:[]).map((e) => Sucursal.fromJson(e)).toList(),
      actividadesEconomicas : json['actividadesEconomicas'],
      autorizadosAPI : [],
      llaves : null,
      tiposFactura : [],
      camposExtra : [],
      autorizaciones : json["autorizaciones"],
      usuarios : List.from(json["usuarios"] is Iterable?json["usuarios"]:[]).map((e) => Usuarios.fromJson(e)).toList()
  );


  factory Contribuyente.initCreate()=>Contribuyente(
    habilitadoFacturacion: false,
    habilitadoVentas: false,
    habilitadoCobros: false,
    plan: 3,
    razonSocial: "Izi Lite",
    actividadesEconomicas: [],
    autorizadosAPI: [],

  );

  Map<String,dynamic> toJsonCreate()=>{
    "administrador": administrador,
    "correoElectronico": correoElectronico,
    "habilitadoFacturacion": habilitadoFacturacion,
    "habilitadoVentas": habilitadoVentas,
    "nivelSoporte": 1,
    "habilitadoCobros":habilitadoCobros,
    "nombre": nombre,
    "plan": plan,
    "nit":nit,
    "razonSocial": razonSocial,
  };

  Map<String,dynamic> toJsonUpdate()=>{
    "nombre": nombre,
    "nit":nit,
  };
}

class Sucursal {
  Sucursal({
    this.id,
    this.contribuyente,
    this.nombre,
    this.direccion,
    this.zona,
    this.ciudad,
    this.telf,
    this.config,
    this.usaInventario,
    this.permiteSobreventas,
    this.estado,
    this.isCasaMatriz,
    this.canEmitirVentas,
    this.canSeeVentas,
    this.seeOwnVentas,
    this.canRegistrarCompras,
    this.canSeeCompras,
    this.canSeeFormularios,
    this.canAnular,
    this.canOpenCajas,
    this.canSeeReportes,
    this.canCreatePedidos,
    this.canAnularPedidos,
    this.canConfigCocinas,
    this.canConfigUsuarios,
    this.canConfigAlmacenes,
    this.canConfigImpresoras,
    this.canConfigCajas,
    this.canAdminCajas,
    this.canSeePedidos,
    this.canAdminCocinas,
    this.canFacturarPedidos,
    this.canAdminProductos,
    this.canSeeProductos,
    this.canMoveProductos,
    this.canGenerarCobros,
    this.canSeeCobros,
    this.canConfigSucursal,
    this.canConfigIntegraciones,
    this.canEditFechaFactura,
    this.canEditEstadoPago,
    this.canSeeInsumos,
    this.canAdminInsumos,
    this.canMoveInsumos,
    this.canEditValoresItems,
    this.administrador
  });
  int? id;
  int? administrador;
  int? contribuyente;
  String? nombre;
  String? direccion;
  String? zona;
  String? ciudad;
  String? telf;
  dynamic config;
  bool? usaInventario;
  bool? permiteSobreventas;
  int? estado;
  bool? isCasaMatriz;
  bool? canEmitirVentas;
  bool? canSeeVentas;
  bool? seeOwnVentas;
  bool? canRegistrarCompras;
  bool? canSeeCompras;
  bool? canSeeFormularios;
  bool? canAnular;
  bool? canOpenCajas;
  bool? canSeeReportes;
  bool? canCreatePedidos;
  bool? canAnularPedidos;
  bool? canConfigCocinas;
  bool? canConfigUsuarios;
  bool? canConfigAlmacenes;
  bool? canConfigImpresoras;
  bool? canConfigCajas;
  bool? canAdminCajas;
  bool? canSeePedidos;
  bool? canAdminCocinas;
  bool? canFacturarPedidos;
  bool? canAdminProductos;
  bool? canSeeProductos;
  bool? canMoveProductos;
  bool? canGenerarCobros;
  bool? canSeeCobros;
  bool? canConfigSucursal;
  bool? canConfigIntegraciones;
  bool? canEditFechaFactura;
  bool? canEditEstadoPago;
  bool? canSeeInsumos;
  bool? canAdminInsumos;
  bool? canMoveInsumos;
  bool? canEditValoresItems;

  Sucursal.fromJson(Map<String, dynamic> json){
    id = json['id'];
    contribuyente = json['contribuyente'];
    nombre = json['nombre'];
    direccion = json['direccion'];
    zona = json['zona'];
    ciudad = json['ciudad'];
    telf = json['telf'];
    config = json['config'];
    usaInventario = json['usaInventario'];
    permiteSobreventas = json['permiteSobreventas'];
    estado = json['estado'];
    isCasaMatriz = json['isCasaMatriz'];
    canEmitirVentas = json['canEmitirVentas'];
    canSeeVentas = json['canSeeVentas'];
    seeOwnVentas = json['seeOwnVentas'];
    canRegistrarCompras = json['canRegistrarCompras'];
    canSeeCompras = json['canSeeCompras'];
    canSeeFormularios = json['canSeeFormularios'];
    canAnular = json['canAnular'];
    canOpenCajas = json['canOpenCajas'];
    canSeeReportes = json['canSeeReportes'];
    canCreatePedidos = json['canCreatePedidos'];
    canAnularPedidos = json['canAnularPedidos'];
    canConfigCocinas = json['canConfigCocinas'];
    canConfigUsuarios = json['canConfigUsuarios'];
    canConfigAlmacenes = json['canConfigAlmacenes'];
    canConfigImpresoras = json['canConfigImpresoras'];
    canConfigCajas = json['canConfigCajas'];
    canAdminCajas = json['canAdminCajas'];
    canSeePedidos = json['canSeePedidos'];
    canAdminCocinas = json['canAdminCocinas'];
    canFacturarPedidos = json['canFacturarPedidos'];
    canAdminProductos = json['canAdminProductos'];
    canSeeProductos = json['canSeeProductos'];
    canMoveProductos = json['canMoveProductos'];
    canGenerarCobros = json['canGenerarCobros'];
    canSeeCobros = json['canSeeCobros'];
    canConfigSucursal = json['canConfigSucursal'];
    canConfigIntegraciones = json['canConfigIntegraciones'];
    canEditFechaFactura = json['canEditFechaFactura'];
    canEditEstadoPago = json['canEditEstadoPago'];
    canSeeInsumos = json['canSeeInsumos'];
    canAdminInsumos = json['canAdminInsumos'];
    canMoveInsumos = json['canMoveInsumos'];
    canEditValoresItems = json['canEditValoresItems'];
  }
  factory Sucursal.init()=>Sucursal(
    ciudad: "La Paz",
    direccion: "La Paz",
    isCasaMatriz: true,
    nombre: "Caza Matriz",
    telf: "70000000",
    zona: "La Paz"
  );
  Map<String, dynamic> toJsonCreate() =>{
    "administrador": administrador,
    "ciudad": ciudad,
    "direccion": direccion,
    "isCasaMatriz": isCasaMatriz,
    "nombre": nombre,
    "telf": telf,
    "zona": zona
  };

  Map<String, dynamic> toJsonUpdate() =>{
    "ciudad": ciudad,
    "direccion": direccion,
    "telf": telf,
    "usaInventario": 0,
    "zona": zona
  };

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['contribuyente'] = contribuyente;
    data['nombre'] = nombre;
    data['direccion'] = direccion;
    data['zona'] = zona;
    data['ciudad'] = ciudad;
    data['telf'] = telf;
    data['config'] = config?.toJson();
    data['usaInventario'] = usaInventario;
    data['permiteSobreventas'] = permiteSobreventas;
    data['estado'] = estado;
    data['isCasaMatriz'] = isCasaMatriz;
    data['canEmitirVentas'] = canEmitirVentas;
    data['canSeeVentas'] = canSeeVentas;
    data['seeOwnVentas'] = seeOwnVentas;
    data['canRegistrarCompras'] = canRegistrarCompras;
    data['canSeeCompras'] = canSeeCompras;
    data['canSeeFormularios'] = canSeeFormularios;
    data['canAnular'] = canAnular;
    data['canOpenCajas'] = canOpenCajas;
    data['canSeeReportes'] = canSeeReportes;
    data['canCreatePedidos'] = canCreatePedidos;
    data['canAnularPedidos'] = canAnularPedidos;
    data['canConfigCocinas'] = canConfigCocinas;
    data['canConfigUsuarios'] = canConfigUsuarios;
    data['canConfigAlmacenes'] = canConfigAlmacenes;
    data['canConfigImpresoras'] = canConfigImpresoras;
    data['canConfigCajas'] = canConfigCajas;
    data['canAdminCajas'] = canAdminCajas;
    data['canSeePedidos'] = canSeePedidos;
    data['canAdminCocinas'] = canAdminCocinas;
    data['canFacturarPedidos'] = canFacturarPedidos;
    data['canAdminProductos'] = canAdminProductos;
    data['canSeeProductos'] = canSeeProductos;
    data['canMoveProductos'] = canMoveProductos;
    data['canGenerarCobros'] = canGenerarCobros;
    data['canSeeCobros'] = canSeeCobros;
    data['canConfigSucursal'] = canConfigSucursal;
    data['canConfigIntegraciones'] = canConfigIntegraciones;
    data['canEditFechaFactura'] = canEditFechaFactura;
    data['canEditEstadoPago'] = canEditEstadoPago;
    data['canSeeInsumos'] = canSeeInsumos;
    data['canAdminInsumos'] = canAdminInsumos;
    data['canMoveInsumos'] = canMoveInsumos;
    data['canEditValoresItems'] = canEditValoresItems;
    return data;
  }
}

class Config {
  Config({
    this.pasosConfig,
    this.usaInventario,
    this.configPrefactura,
    this.permiteSobreventas,
    this.restaurantPagoAdelantado,
  });
  PasosConfig? pasosConfig;
  bool? usaInventario;
  Map<String,dynamic>? configPrefactura;
  bool? permiteSobreventas;
  bool? restaurantPagoAdelantado;

  Config.fromJson(Map<String, dynamic> json){
    pasosConfig = json["pasosConfig"]!=null?PasosConfig.fromJson(json['pasosConfig']):null;
    usaInventario = json['usaInventario'];
    configPrefactura = json['configPrefactura'] is String?{}:json["configPrefactura"];
    permiteSobreventas = json['permiteSobreventas'];
    restaurantPagoAdelantado = json['restaurantPagoAdelantado'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['pasosConfig'] = pasosConfig?.toJson();
    data['usaInventario'] = usaInventario;
    data['configPrefactura'] = configPrefactura;
    data['permiteSobreventas'] = permiteSobreventas;
    data['restaurantPagoAdelantado'] = restaurantPagoAdelantado;
    return data;
  }
}

class PasosConfig {
  PasosConfig({
    this.pasoDatos,
    this.pasoActividades,
    this.pasoDosificacion,
  });
  bool? pasoDatos;
  bool? pasoActividades;
  bool? pasoDosificacion;

  PasosConfig.fromJson(Map<String, dynamic> json){
    pasoDatos = json['pasoDatos'];
    pasoActividades = json['pasoActividades'];
    pasoDosificacion = json['pasoDosificacion'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['pasoDatos'] = pasoDatos;
    data['pasoActividades'] = pasoActividades;
    data['pasoDosificacion'] = pasoDosificacion;
    return data;
  }
}

class Llaves {
  Llaves();

  Llaves.fromJson(Map json);

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    return data;
  }
}

class Usuarios {
  Usuarios({
    required this.id,
    required this.nombreCompleto,
  });
  late final int id;
  late final String nombreCompleto;

  Usuarios.fromJson(Map<String, dynamic> json){
    id = json['id'];
    nombreCompleto = json['nombreCompleto'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['nombreCompleto'] = nombreCompleto;
    return data;
  }
}