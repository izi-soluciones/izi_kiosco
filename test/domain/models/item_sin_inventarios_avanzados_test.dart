import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/models/modulos.dart';
import 'package:izi_kiosco/domain/utils/variable_particionada.dart';

// Sin el módulo inventarios_advanced el kiosco elige el ítem como en beta: sin grilla de
// sabores (variable particionada) ni fotos por opción.
void main() {
  Map<String, dynamic> pizza() => {
        'id': 'pizza-int',
        'nombre': 'Pizza Interminable',
        'modificadores': [
          {
            'nombre': 'Sabores',
            'tipo': 'particionada',
            'partes': 4,
            'caracteristicas': [
              {'nombre': 'Hawaiana', 'modPrecio': 0, 'imagen': 'https://x/h.png'},
            ],
          },
        ],
      };

  test('quita la variable particionada y las fotos sin tocar el original', () {
    final original = Item.fromJson(pizza());
    final limpio = original.sinInventariosAvanzados();
    expect(limpio.modificadores.first.isParticionada, isFalse);
    expect(limpio.modificadores.first.caracteristicas.first.imagen, isNull);
    expect(original.modificadores.first.isParticionada, isTrue);
  });

  test('inventarios_advanced se lee con su clave de ms-auth y sin ella queda apagado', () {
    expect(Modulos.fromJson({}).isEnabled(Modulo.inventariosAdvanced.clave), isFalse);
    expect(Modulos.fromJson({'inventarios_advanced': {'enabled': true}}).isEnabled(Modulo.inventariosAdvanced.clave), isTrue);
  });
}
