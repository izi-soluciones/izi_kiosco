// Imagen en las opciones de una variable (ClickUp 86e3qauam): el ítem que llega de
// ms-inventario trae la URL en modificadores[].caracteristicas[].imagen.
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/item.dart';

void main() {
  group('ModifierItem.imagen', () {
    test('lee la URL de la opción', () {
      final opcion = ModifierItem.fromJson({
        'nombre': 'Hawaiana',
        'modPrecio': 0,
        'imagen': 'https://s3.izi/logos-items/hawaiana.png',
      });
      expect(opcion.imagen, 'https://s3.izi/logos-items/hawaiana.png');
    });

    test('una opción sin imagen, con null o vacía, queda en null', () {
      expect(ModifierItem.fromJson({'nombre': 'Jugoso', 'modPrecio': 0}).imagen, isNull);
      expect(ModifierItem.fromJson({'nombre': 'Jugoso', 'modPrecio': 0, 'imagen': null}).imagen, isNull);
      expect(ModifierItem.fromJson({'nombre': 'Jugoso', 'modPrecio': 0, 'imagen': ''}).imagen, isNull);
    });

    test('la imagen sobrevive a copyWith y a toJson → fromJson', () {
      final opcion = ModifierItem.fromJson({'nombre': 'Hawaiana', 'modPrecio': 0, 'imagen': 'https://x/h.png'});
      expect(opcion.copyWith().imagen, 'https://x/h.png');
      expect(ModifierItem.fromJson(opcion.toJson()).imagen, 'https://x/h.png');
    });

    test('toJson no agrega la clave si no hay imagen', () {
      expect(ModifierItem.fromJson({'nombre': 'Jugoso', 'modPrecio': 0}).toJson().containsKey('imagen'), isFalse);
    });
  });
}
