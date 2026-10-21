class CamposExtra {
  final int id;
  final int contribuyente;
  final String nombre;
  final String tipoCampo; // 'text', 'number', 'select', 'fijo'
  final bool visibleFactura;
  final bool visibleReporte;
  final String? valor;
  final bool isObligatorio;
  final DateTime creado;
  final String tipoModulo;
  final List<String>? values;

  CamposExtra({
    required this.id,
    required this.contribuyente,
    required this.nombre,
    required this.tipoCampo,
    required this.visibleFactura,
    required this.visibleReporte,
    this.valor,
    required this.isObligatorio,
    required this.creado,
    required this.tipoModulo,
    this.values,
  });

  factory CamposExtra.fromJson(Map<String, dynamic> json) {
    String tipo = json["tipoCampo"]?.toString() ?? "text";
    String rawValor = json["valor"]?.toString() ?? "";
    List<String>? parsedValues;
    if (tipo == 'select') {
      if (json["values"] is List) {
        parsedValues = List<String>.from(json["values"].map((e) => e.toString()));
      } else if (rawValor.isNotEmpty) {
        parsedValues = rawValor
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        parsedValues = [];
      }
    }

    return CamposExtra(
      id: json["id"] is int
          ? json["id"]
          : (int.tryParse(json["id"]?.toString() ?? "") ?? 0),
      contribuyente: json["contribuyente"] is int
          ? json["contribuyente"]
          : (int.tryParse(json["contribuyente"]?.toString() ?? "") ?? 0),
      nombre: (json["nombre"] ?? json["titulo"] ?? "").toString(),
      tipoCampo: tipo,
      visibleFactura: json["visibleFactura"] == true || json["visibleFactura"] == 1,
      visibleReporte: json["visibleReporte"] == true || json["visibleReporte"] == 1,
      valor: tipo == 'select' ? (json["valorSeleccionado"]?.toString()) : (json["valor"]?.toString()),
      isObligatorio: json["isObligatorio"] == true || json["isObligatorio"] == 1,
      creado: DateTime.tryParse(json["creado"]?.toString() ?? "") ?? DateTime.now(),
      tipoModulo: json["tipoModulo"]?.toString() ?? "",
      values: parsedValues,
    );
  }

  CamposExtra copyWith({
    String? Function()? valor,
    List<String>? values,
    bool? isObligatorio,
  }) =>
      CamposExtra(
        id: id,
        contribuyente: contribuyente,
        nombre: nombre,
        tipoCampo: tipoCampo,
        visibleFactura: visibleFactura,
        visibleReporte: visibleReporte,
        valor: valor != null ? valor() : this.valor,
        isObligatorio: isObligatorio ?? this.isObligatorio,
        creado: creado,
        tipoModulo: tipoModulo,
        values: values ?? this.values,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "contribuyente": contribuyente,
        "titulo": nombre,
        "nombre": nombre,
        "tipoCampo": tipoCampo,
        "visibleFactura": visibleFactura,
        "visibleReporte": visibleReporte,
        "isObligatorio": isObligatorio,
        "visibleVista": tipoCampo != 'fijo',
        "creado": creado.toIso8601String(),
        "valor": valor ?? (tipoCampo == 'fijo' ? "" : ""),
        if (values != null) "values": values,
        "tipoModulo": tipoModulo,
      };

  @override
  String toString() {
    return 'CamposExtra{id: $id, nombre: $nombre, tipoCampo: $tipoCampo, valor: $valor, isObligatorio: $isObligatorio, tipoModulo: $tipoModulo}';
  }
}
