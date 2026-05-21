class Modulos {
  final bool ventasEnabled;
  final bool facturacionEnabled;
  final bool bloqueadoPago;
  final bool habilitadoIA;

  Modulos({
    this.ventasEnabled = false,
    this.facturacionEnabled = false,
    this.bloqueadoPago = false,
    this.habilitadoIA = false,
  });

  factory Modulos.fromJson(Map<String, dynamic> j) => Modulos(
        ventasEnabled: j['ventas'] is Map && j['ventas']['enabled'] == true,
        facturacionEnabled:
            j['facturacion'] is Map && j['facturacion']['enabled'] == true,
        bloqueadoPago: j['bloqueadoPago'] == true,
        habilitadoIA: j['habilitadoIA'] == true,
      );
}
