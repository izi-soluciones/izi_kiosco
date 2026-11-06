import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';

import '../../helpers/mocks.dart';

Item buildItem({
  required String id,
  String categoriaId = 'c1',
  num precio = 10,
  num cantidad = 1,
}) =>
    Item.fromJson({
      'id': id,
      'nombre': 'Item $id',
      'precioUnitario': precio,
      'cantidad': cantidad,
      'categoria': {'id': categoriaId, 'nombre': 'Cat'},
    });

void main() {
  late MockComandaRepository comandaRepository;
  late MockBusinessRepository businessRepository;

  setUp(() {
    comandaRepository = MockComandaRepository();
    businessRepository = MockBusinessRepository();
  });

  MakeOrderBloc build() =>
      MakeOrderBloc(comandaRepository, businessRepository);

  group('simple state transitions', () {
    blocTest<MakeOrderBloc, MakeOrderState>(
      'changeStepStatus updates step',
      build: build,
      act: (bloc) => bloc.changeStepStatus(2),
      expect: () =>
          [isA<MakeOrderState>().having((s) => s.step, 'step', 2)],
    );
    blocTest<MakeOrderBloc, MakeOrderState>(
      'changeCategory updates indexCategory',
      build: build,
      act: (bloc) => bloc.changeCategory(4),
      expect: () => [
        isA<MakeOrderState>().having((s) => s.indexCategory, 'index', 4)
      ],
    );
    blocTest<MakeOrderBloc, MakeOrderState>(
      'changeTakeAway toggles the flag',
      build: build,
      act: (bloc) => bloc.changeTakeAway(false),
      expect: () => [
        isA<MakeOrderState>().having((s) => s.takeAway, 'takeAway', false)
      ],
    );
    blocTest<MakeOrderBloc, MakeOrderState>(
      'changeDiscountAmount updates the discount',
      build: build,
      act: (bloc) => bloc.changeDiscountAmount(15),
      expect: () => [
        isA<MakeOrderState>().having((s) => s.discountAmount, 'discount', 15)
      ],
    );
  });

  group('addItem', () {
    blocTest<MakeOrderBloc, MakeOrderState>(
      'creates a category and computes tax price (qty * unit price)',
      build: build,
      act: (bloc) => bloc.addItem(item: buildItem(id: 'a', precio: 10)),
      expect: () => [
        isA<MakeOrderState>()
            .having((s) => s.itemsSelected.length, 'categories', 1)
            .having((s) => s.itemsSelected.first.items.length, 'items', 1)
            .having((s) => s.itemsSelected.first.items.first.taxPrice,
                'taxPrice', 10),
      ],
    );

    blocTest<MakeOrderBloc, MakeOrderState>(
      'adding the identical item again increments quantity, not count',
      build: build,
      act: (bloc) {
        bloc.addItem(item: buildItem(id: 'a', precio: 10));
        bloc.addItem(item: buildItem(id: 'a', precio: 10));
      },
      skip: 1, // check state after the second add
      expect: () => [
        isA<MakeOrderState>()
            .having((s) => s.itemsSelected.first.items.length, 'items', 1)
            .having((s) => s.itemsSelected.first.items.first.cantidad, 'qty', 2)
            .having((s) => s.itemsSelected.first.items.first.taxPrice,
                'taxPrice', 20),
      ],
    );

    blocTest<MakeOrderBloc, MakeOrderState>(
      'items in different categories create separate groups',
      build: build,
      act: (bloc) {
        bloc.addItem(item: buildItem(id: 'a', categoriaId: 'c1'));
        bloc.addItem(item: buildItem(id: 'b', categoriaId: 'c2'));
      },
      skip: 1,
      expect: () => [
        isA<MakeOrderState>()
            .having((s) => s.itemsSelected.length, 'categories', 2),
      ],
    );
  });

  group('removeItem / resetItems', () {
    blocTest<MakeOrderBloc, MakeOrderState>(
      'removing the last item in a category drops the category',
      build: build,
      act: (bloc) {
        bloc.addItem(item: buildItem(id: 'a'));
        bloc.removeItem(0, 0);
      },
      skip: 1,
      expect: () => [
        isA<MakeOrderState>()
            .having((s) => s.itemsSelected, 'selected', isEmpty),
      ],
    );

    blocTest<MakeOrderBloc, MakeOrderState>(
      'resetItems clears selection and resets category index',
      build: build,
      act: (bloc) {
        bloc.addItem(item: buildItem(id: 'a'));
        bloc.resetItems();
      },
      skip: 1,
      expect: () => [
        isA<MakeOrderState>()
            .having((s) => s.itemsSelected, 'selected', isEmpty)
            .having((s) => s.indexCategory, 'index', 0),
      ],
    );
  });
}
