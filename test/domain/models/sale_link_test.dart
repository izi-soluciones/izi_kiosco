import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/sale_link.dart';

void main() {
  group('SaleLink.fromJson', () {
    test('parses base fields and nested venta items', () {
      final link = SaleLink.fromJson({
        'contribuyente': 3,
        'id': 9,
        'uuid': 'abc',
        'monto': 250,
        'monedaId': 1,
        'ventaData': {
          'listaItems': [
            {'id': 'i1', 'nombre': 'A', 'cantidad': 2},
            {'id': 'i2', 'nombre': 'B', 'cantidad': 1},
          ]
        }
      });
      expect(link.contribuyente, 3);
      expect(link.id, 9);
      expect(link.uuid, 'abc');
      expect(link.monto, 250);
      expect(link.monedaId, 1);
      expect(link.items.length, 2);
      expect(link.items.first.nombre, 'A');
    });

    test('defaults monedaId to the app default and items to empty', () {
      final link = SaleLink.fromJson({'contribuyente': 1, 'id': 2});
      expect(link.monedaId, 150);
      expect(link.items, isEmpty);
      expect(link.uuid, '');
      expect(link.monto, 0);
    });
  });
}
