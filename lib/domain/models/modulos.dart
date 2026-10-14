enum Modulo {
  ventas,
  facturacion,
  contabilidad,
  restaurantes,
  cajas,
  mesas,
  integraciones,
  inventarios,
  cobros,
  terminal,
  retail,
  compras,
  clientes,
  proveedores,
  pedidos,
  reportes,
  dispositivos,
}

class Modulos {
  final Map<String, bool> _enabled;
  final bool bloqueadoPago;
  final bool habilitadoIA;

  Modulos({
    Map<String, bool>? enabled,
    this.bloqueadoPago = false,
    this.habilitadoIA = false,
  }) : _enabled = enabled ?? const {};

  bool isEnabled(String key) => _enabled[key] == true;

  // Antes de los módulos no tenían flag y se veían siempre: si el documento no trae la clave,
  // siguen habilitados. Solo un enabled:false explícito los apaga.
  static const _sinFlagAntes = {
    Modulo.compras,
    Modulo.clientes,
    Modulo.proveedores,
    Modulo.pedidos,
    Modulo.reportes,
  };

  factory Modulos.fromJson(Map<String, dynamic> j) {
    final enabled = <String, bool>{};
    for (final m in Modulo.values) {
      final v = j[m.name];
      enabled[m.name] = v == null && _sinFlagAntes.contains(m)
          ? true
          : v is Map && v['enabled'] == true;
    }
    return Modulos(
      enabled: enabled,
      bloqueadoPago: j['bloqueadoPago'] == true,
      habilitadoIA: j['habilitadoIA'] == true,
    );
  }
}
