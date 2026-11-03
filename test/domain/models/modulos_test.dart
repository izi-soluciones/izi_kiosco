import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/modulos.dart';

void main() {
  group('Modulos.fromJson', () {
    test('reads nested enabled flags', () {
      final m = Modulos.fromJson({
        'ventas': {'enabled': true},
        'facturacion': {'enabled': false},
        'bloqueadoPago': true,
        'habilitadoIA': true,
      });
      expect(m.isEnabled(Modulo.ventas.name), isTrue);
      expect(m.isEnabled(Modulo.facturacion.name), isFalse);
      expect(m.bloqueadoPago, isTrue);
      expect(m.habilitadoIA, isTrue);
    });
    test('defaults everything to false when keys missing or wrong type', () {
      final m = Modulos.fromJson({'ventas': true, 'facturacion': null});
      expect(m.isEnabled(Modulo.ventas.name), isFalse);
      expect(m.isEnabled(Modulo.facturacion.name), isFalse);
      expect(m.bloqueadoPago, isFalse);
      expect(m.habilitadoIA, isFalse);
    });
    test('nested enabled must be exactly true', () {
      final m = Modulos.fromJson({
        'ventas': {'enabled': 'true'},
      });
      expect(m.isEnabled(Modulo.ventas.name), isFalse);
    });
  });

  group('Modulos.fromJson', () {
    test('sin la clave, los módulos que antes no tenían flag siguen habilitados', () {
      final modulos = Modulos.fromJson({});
      for (final m in [Modulo.compras, Modulo.clientes, Modulo.proveedores, Modulo.pedidos, Modulo.reportes]) {
        expect(modulos.isEnabled(m.name), isTrue, reason: m.name);
      }
    });

    test('un enabled:false explícito los apaga', () {
      final modulos = Modulos.fromJson({
        'clientes': {'enabled': false},
        'reportes': {'enabled': false},
      });
      expect(modulos.isEnabled('clientes'), isFalse);
      expect(modulos.isEnabled('reportes'), isFalse);
    });

    test('los módulos con flag desde antes siguen apagados si falta la clave', () {
      final modulos = Modulos.fromJson({});
      for (final m in [Modulo.facturacion, Modulo.restaurantes, Modulo.retail, Modulo.inventarios, Modulo.dispositivos]) {
        expect(modulos.isEnabled(m.name), isFalse, reason: m.name);
      }
    });
  });
}
