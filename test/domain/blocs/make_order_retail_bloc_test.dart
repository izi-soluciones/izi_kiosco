import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order_retail/make_order_retail_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/models/sale_link.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

Item buildItem({required String id, String? barcode, num cantidad = 0}) =>
    Item.fromJson({
      'id': id,
      'nombre': 'Item $id',
      'codigoBarras': barcode,
      'cantidad': cantidad,
    });

void main() {
  setUpAll(registerCommonFallbacks);

  late MockComandaRepository comandaRepository;
  late MockBusinessRepository businessRepository;

  setUp(() {
    comandaRepository = MockComandaRepository();
    businessRepository = MockBusinessRepository();
  });

  MakeOrderRetailBloc build() =>
      MakeOrderRetailBloc(comandaRepository, businessRepository);

  group('addItem', () {
    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'adds a matching barcode item with quantity 1',
      build: build,
      seed: () => MakeOrderRetailState.init()
          .copyWith(items: [buildItem(id: 'a', barcode: '111')]),
      act: (bloc) => bloc.addItem(barCode: '111'),
      expect: () => [
        isA<MakeOrderRetailState>()
            .having((s) => s.itemsSelected.length, 'selected', 1)
            .having((s) => s.itemsSelected.first.cantidad, 'qty', 1),
      ],
    );

    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'matches barcodes case-insensitively',
      build: build,
      seed: () => MakeOrderRetailState.init()
          .copyWith(items: [buildItem(id: 'a', barcode: 'ABC')]),
      act: (bloc) => bloc.addItem(barCode: 'abc'),
      expect: () => [
        isA<MakeOrderRetailState>()
            .having((s) => s.itemsSelected.length, 'selected', 1),
      ],
    );

    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'increments quantity when the item is already selected',
      build: build,
      seed: () => MakeOrderRetailState.init().copyWith(
        items: [buildItem(id: 'a', barcode: '111')],
        itemsSelected: [buildItem(id: 'a', barcode: '111', cantidad: 1)],
      ),
      act: (bloc) => bloc.addItem(barCode: '111'),
      expect: () => [
        isA<MakeOrderRetailState>()
            .having((s) => s.itemsSelected.length, 'selected', 1)
            .having((s) => s.itemsSelected.first.cantidad, 'qty', 2),
      ],
    );

    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'emits nothing for an unknown barcode',
      build: build,
      seed: () => MakeOrderRetailState.init()
          .copyWith(items: [buildItem(id: 'a', barcode: '111')]),
      act: (bloc) => bloc.addItem(barCode: 'zzz'),
      expect: () => const <MakeOrderRetailState>[],
    );
  });

  group('removeItem / resetItems / changeStepStatus', () {
    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'removeItem drops the item by id',
      build: build,
      seed: () => MakeOrderRetailState.init().copyWith(
          itemsSelected: [buildItem(id: 'a'), buildItem(id: 'b')]),
      act: (bloc) => bloc.removeItem(buildItem(id: 'a')),
      expect: () => [
        isA<MakeOrderRetailState>()
            .having((s) => s.itemsSelected.map((e) => e.id).toList(),
                'remaining ids', ['b']),
      ],
    );

    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'resetItems clears the selection',
      build: build,
      seed: () => MakeOrderRetailState.init()
          .copyWith(itemsSelected: [buildItem(id: 'a')]),
      act: (bloc) => bloc.resetItems(),
      expect: () => [
        isA<MakeOrderRetailState>()
            .having((s) => s.itemsSelected, 'selected', isEmpty),
      ],
    );

    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'changeStepStatus updates the step',
      build: build,
      act: (bloc) => bloc.changeStepStatus(3),
      expect: () => [
        isA<MakeOrderRetailState>().having((s) => s.step, 'step', 3),
      ],
    );
  });

  group('emitOrder', () {
    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'returns the sale link and emits nothing on success',
      setUp: () {
        when(() => comandaRepository.createSaleLink(any())).thenAnswer(
            (_) async => SaleLink.fromJson({'contribuyente': 1, 'id': 2}));
      },
      build: build,
      act: (bloc) => bloc.emitOrder(AuthState.init()),
      expect: () => const <MakeOrderRetailState>[],
      verify: (_) =>
          verify(() => comandaRepository.createSaleLink(any())).called(1),
    );

    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'emits errorEmit -> successGet when createSaleLink throws',
      setUp: () {
        when(() => comandaRepository.createSaleLink(any()))
            .thenThrow(Exception('fail'));
      },
      build: build,
      act: (bloc) => bloc.emitOrder(AuthState.init()),
      expect: () => [
        isA<MakeOrderRetailState>().having(
            (s) => s.status, 'status', MakeOrderRetailStatus.errorEmit),
        isA<MakeOrderRetailState>().having(
            (s) => s.status, 'status', MakeOrderRetailStatus.successGet),
      ],
    );
  });

  group('init error branches', () {
    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'no open cash register -> errorCashRegisters -> waitingGet',
      setUp: () {
        when(() => comandaRepository.getSaleItems(
                catalog: any(named: 'catalog'),
                sortByPriority: any(named: 'sortByPriority')))
            .thenAnswer((_) async => <Item>[]);
        when(() => businessRepository.getCashRegisters(
                contribuyenteId: any(named: 'contribuyenteId'),
                sucursalId: any(named: 'sucursalId')))
            .thenAnswer((_) async => [buildCashRegister(abierta: false)]);
      },
      build: build,
      act: (bloc) => bloc.init(AuthState.init()),
      expect: () => [
        isA<MakeOrderRetailState>().having((s) => s.status, 'status',
            MakeOrderRetailStatus.errorCashRegisters),
        isA<MakeOrderRetailState>().having(
            (s) => s.status, 'status', MakeOrderRetailStatus.waitingGet),
      ],
    );

    blocTest<MakeOrderRetailBloc, MakeOrderRetailState>(
      'repository failure -> errorGet -> waitingGet',
      setUp: () {
        when(() => comandaRepository.getSaleItems(
                catalog: any(named: 'catalog'),
                sortByPriority: any(named: 'sortByPriority')))
            .thenThrow(Exception('down'));
      },
      build: build,
      act: (bloc) => bloc.init(AuthState.init()),
      expect: () => [
        isA<MakeOrderRetailState>()
            .having((s) => s.status, 'status', MakeOrderRetailStatus.errorGet),
        isA<MakeOrderRetailState>().having(
            (s) => s.status, 'status', MakeOrderRetailStatus.waitingGet),
      ],
    );
  });
}
