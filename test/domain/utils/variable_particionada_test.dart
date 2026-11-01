// Variable particionada en el kiosco (ClickUp 86e3qauf1). La regla de reparto es la misma que la
// del POS y la del backbone; los casos son los de la tarea.
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/utils/variable_particionada.dart';

Map<String, dynamic> sabores(int partes) => {
      'nombre': 'Sabores',
      'tipo': 'particionada',
      'partes': partes,
      'isLimitado': partes,
      'caracteristicas': [
        {'nombre': 'Suprema', 'modPrecio': 0},
        {'nombre': 'Jamón', 'modPrecio': 0},
        {'nombre': 'Napolitana', 'modPrecio': 0},
        {'nombre': 'Hawaiana', 'modPrecio': 0},
      ],
    };

Item pizza(int partes) => Item.fromJson({
      'nombre': 'Pizza',
      'precioUnitario': 309,
      'id': 'pizza-int',
      'modificadores': [
        sabores(partes),
        {
          'nombre': 'Extras',
          'isMultiple': true,
          'caracteristicas': [
            {'nombre': 'Extra pepperoni', 'modPrecio': 8},
          ],
        },
      ],
    });

ModifierItem sabor(Modifier m, String nombre) => m.caracteristicas.firstWhere((c) => c.nombre == nombre);

void main() {
  test('el reparto es el mismo que en el POS y el backbone', () {
    expect(repartirPartes(4, 3), [2, 1, 1]);
    expect(repartirPartes(4, 1), [4]);
    expect(repartirPartes(2, 2), [1, 1]);
    expect(etiquetaPorciones(2, 4), '1/2');
    expect(etiquetaPorciones(1, 4), '1/4');
    expect(etiquetaPorciones(4, 4), '2 × 1/2');
    expect(etiquetaPorciones(1, 1), 'entera');
  });

  test('lee tipo y partes de la variable', () {
    final m = pizza(4).modificadores.first;
    expect(m.isParticionada, isTrue);
    expect(m.partes, 4);
    expect(pizza(4).modificadores.last.isParticionada, isFalse);
  });

  test('Interminable: Suprema, Jamón y Napolitana quedan 1, 2 y 3 con 1/2, 1/4 y 1/4', () {
    final m = pizza(4).modificadores.first;
    for (final n in ['Suprema', 'Jamón', 'Napolitana']) {
      expect(m.alternarSabor(sabor(m, n)), isTrue);
    }
    expect(m.reparto.entries.map((r) => '${r.key.orden}. ${r.key.nombre} ${etiquetaPorciones(r.value, 4)}'),
        ['1. Suprema 1/2', '2. Jamón 1/4', '3. Napolitana 1/4']);
  });

  test('Mediana con 2 sabores no deja elegir un tercero', () {
    final m = pizza(2).modificadores.first;
    m.alternarSabor(sabor(m, 'Suprema'));
    m.alternarSabor(sabor(m, 'Jamón'));
    expect(m.alternarSabor(sabor(m, 'Napolitana')), isFalse);
    expect(sabor(m, 'Napolitana').check, isFalse);
  });

  test('quitar un sabor renumera los demás', () {
    final m = pizza(4).modificadores.first;
    for (final n in ['Suprema', 'Jamón', 'Napolitana']) {
      m.alternarSabor(sabor(m, n));
    }
    m.alternarSabor(sabor(m, 'Suprema'));
    expect(m.seleccionOrdenada.map((c) => '${c.orden}. ${c.nombre}'), ['1. Jamón', '2. Napolitana']);
  });

  test('la comanda recibe los sabores en orden de selección y una vez cada uno; los extras como hoy', () {
    final item = pizza(4);
    final m = item.modificadores.first;
    for (final n in ['Napolitana', 'Suprema', 'Jamón']) {
      m.alternarSabor(sabor(m, n));
    }
    item.modificadores.last.caracteristicas.first.check = true;
    final json = item.toJson();
    expect(json['modificadores']['Sabores'], ['Napolitana', 'Suprema', 'Jamón']);
    expect(json['modificadores']['Extras'], ['Extra pepperoni']);
  });

  test('copyWith conserva el tipo, las partes y el orden', () {
    final item = pizza(4);
    final m = item.modificadores.first;
    m.alternarSabor(sabor(m, 'Jamón'));
    m.alternarSabor(sabor(m, 'Suprema'));
    final copia = item.copyWith().modificadores.first;
    expect(copia.isParticionada, isTrue);
    expect(copia.seleccionOrdenada.map((c) => c.nombre), ['Jamón', 'Suprema']);
  });

  test('con más sabores elegidos que partes se quedan los primeros', () {
    final m = Modifier.fromJson({
      ...sabores(2),
      'caracteristicas': [
        {'nombre': 'Suprema', 'modPrecio': 0, 'check': true, 'orden': 1},
        {'nombre': 'Jamón', 'modPrecio': 0, 'check': true, 'orden': 2},
        {'nombre': 'Napolitana', 'modPrecio': 0, 'check': true, 'orden': 3},
      ],
    })..normalizarSeleccion();
    expect(m.seleccionOrdenada.map((c) => c.nombre), ['Suprema', 'Jamón']);
  });

  test('una variable normal sigue igual que hoy', () {
    final item = Item.fromJson({
      'nombre': 'Lomo',
      'id': 'lomo',
      'modificadores': [
        {
          'nombre': 'Término',
          'caracteristicas': [
            {'nombre': 'Jugoso', 'modPrecio': 0, 'check': true},
            {'nombre': 'Cocido', 'modPrecio': 0},
          ],
        },
      ],
    });
    expect(item.modificadores.first.isParticionada, isFalse);
    expect(item.toJson()['modificadores']['Término'], ['Jugoso']);
  });
}
