import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/make_order_retail/make_order_retail_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';

class MockComandaRepository implements ComandaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBusinessRepository implements BusinessRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MakeOrderRetailBloc bloc;

  final testItem1 = Item.fromJson({
    "id": "item_1",
    "nombre": "Coca Cola 500ml",
    "codigoBarras": "7791234567890",
    "precioUnitario": 15.0,
    "cantidad": 1,
    "activo": true,
    "categoria": {"nombre": "Bebidas", "id": "10"},
    "preciosVenta": [],
    "subCategoria": "",
    "centroProduccion": 1,
    "kioscoOcultarAqui": false,
    "kioscoOcultarLlevar": false,
  });

  final testItem2 = Item.fromJson({
    "id": "item_2",
    "nombre": "Alfajor Triple",
    "codigoBarras": "abc-123",
    "precioUnitario": 10.0,
    "cantidad": 1,
    "activo": true,
    "categoria": {"nombre": "Snacks", "id": "11"},
    "preciosVenta": [],
    "subCategoria": "",
    "centroProduccion": 1,
    "kioscoOcultarAqui": false,
    "kioscoOcultarLlevar": false,
  });

  setUp(() {
    bloc = MakeOrderRetailBloc(
      MockComandaRepository(),
      MockBusinessRepository(),
    );
    // Seed items catalog in state
    bloc.emit(bloc.state.copyWith(
      items: [testItem1, testItem2],
      itemsSelected: [],
    ));
  });

  tearDown(() {
    bloc.close();
  });

  group('MakeOrderRetailBloc addItem barcode tests', () {
    test('Returns Item and adds to itemsSelected when barcode matches', () {
      final result = bloc.addItem(barCode: '7791234567890');

      expect(result, isNotNull);
      expect(result?.id, equals('item_1'));
      expect(result?.nombre, equals('Coca Cola 500ml'));
      expect(bloc.state.itemsSelected.length, equals(1));
      expect(bloc.state.itemsSelected.first.cantidad, equals(1));
    });

    test('Case-insensitive and trimmed barcode matching', () {
      final result = bloc.addItem(barCode: '  ABC-123  ');

      expect(result, isNotNull);
      expect(result?.id, equals('item_2'));
      expect(bloc.state.itemsSelected.length, equals(1));
      expect(bloc.state.itemsSelected.first.cantidad, equals(1));
    });

    test('Increments quantity when scanning an already added item', () {
      bloc.addItem(barCode: '7791234567890');
      final secondScan = bloc.addItem(barCode: '7791234567890');

      expect(secondScan, isNotNull);
      expect(bloc.state.itemsSelected.length, equals(1));
      expect(bloc.state.itemsSelected.first.cantidad, equals(2));
    });

    test('Returns null when barcode does not exist in catalog', () {
      final result = bloc.addItem(barCode: '9999999999999');

      expect(result, isNull);
      expect(bloc.state.itemsSelected, isEmpty);
    });

    test('Returns null for empty or whitespace-only barcode', () {
      final result1 = bloc.addItem(barCode: '');
      final result2 = bloc.addItem(barCode: '   ');

      expect(result1, isNull);
      expect(result2, isNull);
      expect(bloc.state.itemsSelected, isEmpty);
    });
  });
}
