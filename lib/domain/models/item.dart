class Item {
  bool activo;
  num cantidad;
  String? categoria;
  String? categoriaId;
  int? centroProduccion;
  String? codigo;
  String? codigoBarras;
  dynamic customItem;
  String? descripcion;
  String? imagen;
  String id;
  List<Modifier> modificadores;
  dynamic modificadoresRaw;
  String nombre;
  num precioUnitario;
  num? valor;
  num precioModificadores;
  num precioModUnitario;
  String? detalle;

  List<PrecioVenta> preciosVenta;
  num taxPrice = 0;
  ParametrosFacturacionItem? parametrosFacturacion;





  Item(
      {required this.cantidad,
      required this.codigo,
      required this.customItem,
      required this.descripcion,
      required this.imagen,
        required this.detalle,
      required this.modificadores,
      required this.modificadoresRaw,
      required this.nombre,
      required this.valor,
      required this.activo,
      required this.id,
      required this.precioUnitario,
      required this.categoria,
      required this.categoriaId,
      required this.centroProduccion,
      required this.preciosVenta,
      this.precioModUnitario =0,
        this.precioModificadores = 0,
        this.parametrosFacturacion,
      required this.codigoBarras});
  factory Item.fromJson(Map<dynamic, dynamic> json) {
    List listModificadores =
        json["modificadores"] is List ? json["modificadores"] : [];
    listModificadores.removeWhere((element) => element.isEmpty);
    return Item(
        nombre: json["nombre"] ?? "",
        cantidad: json["cantidad"] ?? 0,
        codigo: json["codigo"],
        customItem: json["customItem"],
        descripcion: json["descripcion"],
        imagen: json["imagen"],
        detalle: json["detalle"],
        modificadores:
            listModificadores.map((e) => Modifier.fromJson(e)).toList(),
        modificadoresRaw: json["modificadores"],
        precioUnitario: json["precioUnitario"] ?? 0,
        activo: json["activo"] ?? false,
        categoria: json["categoria"]?["nombre"],
        categoriaId: json["categoria"]?["id"] ?? json["categoria"]?["_id"],
        centroProduccion: json["centroProduccion"],
        codigoBarras: json["codigoBarras"],
        preciosVenta: json["preciosVenta"] is List? List.from(json["preciosVenta"]).where((element) => element is Map && element["listaPrecio"] is String && element["precio"] is num).map((e) => PrecioVenta(listaPrecio: e["listaPrecio"], precio: e["precio"])).toList():[] ,
        parametrosFacturacion: json["parametrosFacturacion"] is Map?ParametrosFacturacionItem.fromJson(json["parametrosFacturacion"]) : null,
        id: json["id"] ?? 0,
        valor: json["valor"]);
  }

  Item copyWith() => Item(
      cantidad: cantidad,
      codigo: codigo,
      customItem: customItem,
      descripcion: descripcion,
      imagen: imagen,
      modificadores: modificadores.map((e) => e.copyWith()).toList(),
      modificadoresRaw: modificadoresRaw,
      nombre: nombre,
      valor: valor,
      activo: activo,
      id: id,
      detalle: detalle,
      precioUnitario: precioUnitario,
      categoria: categoria,
      categoriaId: categoriaId,
      preciosVenta: preciosVenta,
      centroProduccion: centroProduccion,
      parametrosFacturacion: parametrosFacturacion,
      codigoBarras: codigoBarras);

  Map<String,dynamic> toJson(){
    Map<String,dynamic> modificadoresNames= {};
    for(var mod in modificadores){
      List<String> carNames=[];
      for(var car in mod.caracteristicas){
        if(car.check){
          carNames.add(car.nombre);
        }
      }
      if(carNames.isNotEmpty){
        modificadoresNames[mod.nombre]=carNames;
      }
    }
    return {
      "cantidad": cantidad,
      if(detalle != null) "detalle":detalle,
      "modificadores": modificadoresNames,
      "item": id
    };
  }
}

class Modifier {
  String nombre;
  bool isIngreso;
  bool isMultiple;
  bool isObligatorio;
  int? isLimitado;
  List<ModifierItem> caracteristicas;

  Modifier(
      {required this.nombre,
      required this.isMultiple,
      required this.isObligatorio,
      required this.isIngreso,
        required this.isLimitado,
      required this.caracteristicas});

  factory Modifier.fromJson(Map<dynamic, dynamic> json) {
    List listCaracteristicas =
        json["caracteristicas"] is List ? json["caracteristicas"] : [];
    listCaracteristicas.removeWhere((element) => element.isEmpty);
    return Modifier(
        nombre: json["nombre"] ?? "",
        isLimitado: json["isLimitado"] is int?json["isLimitado"]:null,
        isIngreso: json["isIngreso"] ?? false,
        isMultiple: json["isMultiple"] ?? false,
        isObligatorio: json["isLimitado"] is int  &&  json["isLimitado"] > 0? true: (json["isObligatorio"] ?? false),
        caracteristicas:
        listCaracteristicas.map((e) => ModifierItem.fromJson(e)).toList());
  }
  Modifier copyWith() => Modifier(
      nombre: nombre,
      isMultiple: isMultiple,
      isLimitado: isLimitado,
      isObligatorio: isObligatorio,
      isIngreso: isIngreso,
      caracteristicas: caracteristicas.map((e) => e.copyWith()).toList());

  Map<String,dynamic> toJson()=>{
    "nombre": nombre,
    "isMultiple": isMultiple,
    "isLimitado": isLimitado,
    "isObligatorio": isObligatorio,
    "isIngreso": isIngreso,
    "caracteristicas": caracteristicas.map((e) => e.toJson()).toList()
  };
}

class ModifierItem {
  String nombre;
  num modPrecio;
  bool defaultValue;
  bool check;
  List<ModifierIngredient> ingredientes;

  ModifierItem(
      {required this.nombre,
      this.check = false,
      required this.modPrecio,
        required this.defaultValue,
      required this.ingredientes});

  factory ModifierItem.fromJson(Map<dynamic, dynamic> json) {
    List listIngredientes =
        json["ingredientes"] is List ? json["ingredientes"] : [];
    listIngredientes.removeWhere((element) => element.isEmpty);

    return ModifierItem(
        nombre: json["nombre"] ?? "",
        modPrecio: json["modPrecio"] ?? 0,
        check: json["check"] ?? false,
        defaultValue: json["default"] ?? false,
        ingredientes: []//listIngredientes
            .map((e) => ModifierIngredient.fromJson(e))
            .toList());
  }
  ModifierItem copyWith() => ModifierItem(
      nombre: nombre,
      modPrecio: modPrecio,
      check: check,
      defaultValue: defaultValue,
      ingredientes: ingredientes.map((e) => e.copyWith()).toList());

  Map<String,dynamic> toJson()=>{
    "nombre": nombre,
    "modPrecio": modPrecio,
    "check": check,
    "ingredientes": ingredientes.map((e) => e.toJson()).toList()
  };
}

class ModifierIngredient {
  String articulo;
  num cantidad;
  int item;
  String tipoUnidad;

  ModifierIngredient(
      {required this.articulo,
      required this.cantidad,
      required this.item,
      required this.tipoUnidad});

  factory ModifierIngredient.fromJson(Map<dynamic, dynamic> json) =>
      ModifierIngredient(
          articulo: json["articulo"] ?? "",
          cantidad: json["cantidad"] ?? 0,
          item: json["item"],
          tipoUnidad: json["tipoUnidad"]);

  ModifierIngredient copyWith() => ModifierIngredient(
      articulo: articulo,
      cantidad: cantidad,
      item: item,
      tipoUnidad: tipoUnidad);

  Map<String,dynamic> toJson()=>{
    "articulo": articulo,
    "cantidad": cantidad,
    "item": item,
    "tipoUnidad": tipoUnidad
  };
}

class PrecioVenta{
  String listaPrecio;
  num precio;

  PrecioVenta({required this.listaPrecio, required this.precio});
}
class ParametrosFacturacionItem{
  ParametrosFacturacionCoItem? co;
  ParametrosFacturacionItem({
    required this.co
  });
  factory ParametrosFacturacionItem.fromJson(Map json){
    return ParametrosFacturacionItem(
      co: json["CO"] is Map?ParametrosFacturacionCoItem.fromJson(json["CO"]):null
    );
  }

}

class ParametrosFacturacionCoItem{
  Map impuestosCalculados;
  bool impuestosIn;
  List<ParametrosFacturacionCoImpuestosItem> impuestos;
  ParametrosFacturacionCoItem({
    required this.impuestos,
    required this.impuestosIn,
    required this.impuestosCalculados
  });
  factory ParametrosFacturacionCoItem.fromJson(Map json){
    List listImpuestos =
        json["impuestos"] is List ? json["impuestos"] : [];
    listImpuestos.removeWhere((element) => element.isEmpty);
    return ParametrosFacturacionCoItem(
      impuestos: listImpuestos.map((e) => ParametrosFacturacionCoImpuestosItem.fromJson(e)).toList(),
      impuestosIn: json["impuestosIn"] is bool? json["impuestosIn"]:false,
      impuestosCalculados: json["impuestosCalculados"] is Map? json["impuestosCalculados"]:{},
    );
  }
}

class ParametrosFacturacionCoImpuestosItem{
  num rate;
  num monto;
  bool isFixed;
  bool isAmount;
  String codigo;
  String nombre;
  String id;

  ParametrosFacturacionCoImpuestosItem({
    required this.rate,
    required this.monto,
    required this.isFixed,
    required this.isAmount,
    required this.codigo,
    required this.nombre,
    required this.id,
  });
  factory ParametrosFacturacionCoImpuestosItem.fromJson(Map json){
    return ParametrosFacturacionCoImpuestosItem(
      rate: json["rate"] is num? json["rate"]:0,
      monto: json["monto"] is num? json["monto"]:0,
      isFixed: json["isFixed"] is bool? json["isFixed"]:false,
      isAmount: json["isAmount"] is bool? json["isAmount"]:false,
      codigo: json["codigo"] is String? json["codigo"]:"",
      nombre: json["nombre"] is String? json["nombre"]:"",
      id: json["id"] is String? json["id"]:"");
  }
}


