import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';

class _FakeBusinessRepository extends Fake implements BusinessRepository {}

class _FakeComandaRepository extends Fake implements ComandaRepository {}

// Dos pizzas con los mismos sabores en distinto orden de selección no se fusionan en el carrito:
// el orden decide el reparto de partes, así que son pedidos distintos.
void main() {
  Item pizza(Map<String, int> ordenPorSabor) => Item.fromJson({
        'id': 'pizza-int',
        'nombre': 'Pizza Interminable',
        'categoriaId': 'cat-1',
        'precioUnitario': 10,
        'cantidad': 1,
        'modificadores': [
          {
            'nombre': 'Sabores',
            'tipo': 'particionada',
            'partes': 4,
            'caracteristicas': [
              for (final s in ['A', 'B', 'C'])
                {
                  'nombre': s,
                  'modPrecio': 0,
                  'check': ordenPorSabor.containsKey(s),
                  'orden': ordenPorSabor[s],
                },
            ],
          },
        ],
      });

  MakeOrderBloc crearBloc() => MakeOrderBloc(_FakeComandaRepository(), _FakeBusinessRepository());

  test('mismos sabores en distinto orden no se fusionan', () {
    final bloc = crearBloc();
    bloc.addItem(item: pizza({'A': 1, 'B': 2, 'C': 3}));
    bloc.addItem(item: pizza({'C': 1, 'A': 2, 'B': 3}));
    final items = bloc.state.itemsSelected.expand((c) => c.items).toList();
    expect(items.length, 2);
    expect(items.map((i) => i.cantidad), [1, 1]);
  });

  test('mismos sabores en el mismo orden sí se fusionan', () {
    final bloc = crearBloc();
    bloc.addItem(item: pizza({'A': 1, 'B': 2, 'C': 3}));
    bloc.addItem(item: pizza({'A': 1, 'B': 2, 'C': 3}));
    final items = bloc.state.itemsSelected.expand((c) => c.items).toList();
    expect(items.length, 1);
    expect(items.first.cantidad, 2);
  });
}
