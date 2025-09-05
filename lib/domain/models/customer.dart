class Customer {
  final int? id;
  final String? nit;
  final String? razonSocial;
  final String? correoElectronico;
  final String? tipoNit;
  final String? telefono;
  final CustomerCustom? custom;

  Customer({
    this.id,
    this.nit,
    this.razonSocial,
    this.correoElectronico,
    this.tipoNit,
    this.telefono,
    this.custom,
  });

  // fromJson
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      nit: json['nit']?.toString(),
      razonSocial: json['razonSocial']?.toString(),
      correoElectronico: json['correoElectronico']?.toString(),
      tipoNit: json['tipoNit']?.toString(),
      telefono: json['telefono']?.toString(),
      custom: json['custom'] != null ? CustomerCustom.fromJson(json['custom']) : null,
    );
  }
}

class CustomerCustom {
  final CustomerCustomCo? co;

  CustomerCustom({this.co});

  factory CustomerCustom.fromJson(Map<String, dynamic> json) {
    return CustomerCustom(
      co: json['CO'] != null ? CustomerCustomCo.fromJson(json['CO']) : null,
    );
  }
}

class CustomerCustomCo {
  final String? tipoPersona;
  final String? responsabilidadIva;
  final String? responsabilidadFiscal;
  final String? tipoIdentificacion;

  CustomerCustomCo({
    this.tipoPersona,
    this.responsabilidadIva,
    this.tipoIdentificacion,
    this.responsabilidadFiscal
  });

  factory CustomerCustomCo.fromJson(Map<String, dynamic> json) {
    return CustomerCustomCo(
      tipoPersona: json['tipoPersona']?.toString(),
      responsabilidadIva: json['responsabilidadIva']?.toString(),
      tipoIdentificacion: json['tipoIdentificacion']?.toString(),
      responsabilidadFiscal: json['responsabilidadFiscal']?.toString(),
    );
  }
}