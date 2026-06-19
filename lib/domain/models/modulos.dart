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

  factory Modulos.fromJson(Map<String, dynamic> j) {
    final enabled = <String, bool>{};
    for (final m in Modulo.values) {
      final v = j[m.name];
      enabled[m.name] = v is Map && v['enabled'] == true;
    }
    return Modulos(
      enabled: enabled,
      bloqueadoPago: j['bloqueadoPago'] == true,
      habilitadoIA: j['habilitadoIA'] == true,
    );
  }
}
