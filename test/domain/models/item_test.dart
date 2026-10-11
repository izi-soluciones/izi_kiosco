import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/item.dart';

void main() {
  group('Item.fromJson', () {
    test('parses core fields with defaults', () {
      final item = Item.fromJson({'id': 'i1', 'nombre': 'Coke'});
      expect(item.id, 'i1');
      expect(item.nombre, 'Coke');
      expect(item.cantidad, 0);
      expect(item.precioUnitario, 0);
      expect(item.activo, isFalse);
      expect(item.preciosVenta, isEmpty);
      expect(item.modificadores, isEmpty);
    });

    test('reads category name/id from nested map', () {
      final item = Item.fromJson({
        'id': 'i1',
        'nombre': 'x',
        'categoria': {'nombre': 'Drinks', 'id': 'c1'}
      });
      expect(item.categoria, 'Drinks');
      expect(item.categoriaId, 'c1');
    });

    test('categoriaId falls back to _id', () {
      final item = Item.fromJson({
        'id': 'i1',
        'nombre': 'x',
        'categoria': {'_id': 'c9'}
      });
      expect(item.categoriaId, 'c9');
    });

    test('preciosVenta keeps only well-typed entries', () {
      final item = Item.fromJson({
        'id': 'i1',
        'nombre': 'x',
        'preciosVenta': [
          {'listaPrecio': 'A', 'precio': 10},
          {'listaPrecio': 'B'}, // missing precio
          {'precio': 5}, // missing listaPrecio
          {'listaPrecio': 1, 'precio': 5}, // wrong type
          'garbage',
        ],
      });
      expect(item.preciosVenta.length, 1);
      expect(item.preciosVenta.first.listaPrecio, 'A');
      expect(item.preciosVenta.first.precio, 10);
    });

    test('kiosk visibility flags coerce non-bool to false', () {
      final item = Item.fromJson({
        'id': 'i1',
        'nombre': 'x',
        'kioscoOcultarAqui': true,
        'kioscoOcultarLlevar': 'nope',
      });
      expect(item.kioscoOcultarAqui, isTrue);
      expect(item.kioscoOcultarLlevar, isFalse);
    });
  });

  group('Item.nombreMostrar', () {
    Item make({String? comercial}) => Item.fromJson(
        {'id': 'i1', 'nombre': 'Base', 'nombreComercialKiosko': comercial});

    test('uses commercial name when present', () {
      expect(make(comercial: 'Fancy').nombreMostrar, 'Fancy');
    });
    test('falls back to nombre when commercial is null', () {
      expect(make().nombreMostrar, 'Base');
    });
    test('falls back to nombre when commercial is blank', () {
      expect(make(comercial: '   ').nombreMostrar, 'Base');
    });
  });

  group('Item.toJson', () {
    test('emits item id, quantity and checked modifier names', () {
      final item = Item.fromJson({
        'id': 'i1',
        'nombre': 'Burger',
        'cantidad': 2,
        'detalle': 'no onions',
        'modificadores': [
          {
            'nombre': 'Extras',
            'caracteristicas': [
              {'nombre': 'Cheese', 'check': true},
              {'nombre': 'Bacon', 'check': false},
            ]
          }
        ],
      });
      final json = item.toJson();
      expect(json['item'], 'i1');
      expect(json['cantidad'], 2);
      expect(json['detalle'], 'no onions');
      expect(json['modificadores'], {
        'Extras': ['Cheese']
      });
    });
  });
}
