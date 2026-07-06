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
      expect(m.ventasEnabled, isTrue);
      expect(m.facturacionEnabled, isFalse);
      expect(m.bloqueadoPago, isTrue);
      expect(m.habilitadoIA, isTrue);
    });
    test('defaults everything to false when keys missing or wrong type', () {
      final m = Modulos.fromJson({'ventas': true, 'facturacion': null});
      expect(m.ventasEnabled, isFalse);
      expect(m.facturacionEnabled, isFalse);
      expect(m.bloqueadoPago, isFalse);
      expect(m.habilitadoIA, isFalse);
    });
    test('nested enabled must be exactly true', () {
      final m = Modulos.fromJson({
        'ventas': {'enabled': 'true'},
      });
      expect(m.ventasEnabled, isFalse);
    });
  });
}
