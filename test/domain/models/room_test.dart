import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/room.dart';

void main() {
  group('Room.fromJson', () {
    test('reads id from _id and parses cajas + dimensions', () {
      final room = Room.fromJson({
        '_id': 'room-1',
        'nombre': 'Salon',
        'activo': true,
        'eliminado': false,
        'cajas': [1, 2, 'x'],
        'dimensiones': {
          'width': {r'$numberDecimal': '10'},
          'height': {r'$numberDecimal': '20'},
        },
      });
      expect(room.id, 'room-1');
      expect(room.nombre, 'Salon');
      expect(room.activo, isTrue);
      expect(room.cajas, [1, 2, 0]); // non-int coerced to 0
      expect(room.width, 10);
      expect(room.height, 20);
    });

    test('defaults dimensions to 0 when structure is absent', () {
      final room = Room.fromJson({'_id': 'r', 'nombre': 'n'});
      expect(room.width, 0);
      expect(room.height, 0);
      expect(room.cajas, isEmpty);
      expect(room.activo, isFalse);
      expect(room.eliminado, isFalse);
    });

    test('defaults id to empty string when _id missing', () {
      expect(Room.fromJson({}).id, '');
    });
  });
}
