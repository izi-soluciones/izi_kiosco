import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/repositories/comanda/comanda_repository_http.dart';
import 'package:izi_kiosco/domain/dto/filters_comanda.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerDioFallbacks);

  late MockDioClient dio;
  late ComandaRepositoryHttp repository;

  setUp(() {
    dio = MockDioClient();
    repository = ComandaRepositoryHttp(dioClient: dio);
  });

  group('getComandas', () {
    test('GET /comandas with pagination + filters, maps items', () async {
      when(() => dio.get(
            uri: any(named: 'uri'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse({
            'items': [
              // fecha/creado are required strings: Comanda.fromJson calls
              // DateTime.tryParse on them without a null guard.
              {'id': 1, 'fecha': '2024-01-01', 'creado': '2024-01-01'},
              {'id': 2, 'fecha': '2024-01-01', 'creado': '2024-01-01'},
            ]
          }));

      final list = await repository.getComandas(
          filters: FiltersComanda(status: 'ABIERTA'), page: 1);

      expect(list.length, 2);
      final captured = verify(() => dio.get(
            uri: captureAny(named: 'uri'),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured;
      expect(captured[0], '/comandas');
      final query = captured[1] as Map;
      expect(query['limit'], '15'); // AppConstants.paginationSize
      expect(query['offset'], '0'); // page 1 -> offset 0
      expect(query['estado'], 'ABIERTA');
    });

    test('throws raw data on non-200', () async {
      when(() => dio.get(
            uri: any(named: 'uri'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse('err', statusCode: 500));

      expect(
        () => repository.getComandas(filters: FiltersComanda(), page: 1),
        throwsA('err'),
      );
    });
  });

  group('getSaleItems', () {
    test('GET /items-inventarios maps items and sets kiosk query flags',
        () async {
      when(() => dio.get(
            uri: any(named: 'uri'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse([
            {'id': 'i1', 'nombre': 'A'},
            {'id': 'i2', 'nombre': 'B'},
          ]));

      final list = await repository.getSaleItems(
          catalog: 'cat-1', sortByPriority: false);

      expect(list.map((i) => i.id).toList(), ['i1', 'i2']);
      final captured = verify(() => dio.get(
            uri: captureAny(named: 'uri'),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured;
      expect(captured[0], '/items-inventarios');
      final query = captured[1] as Map;
      expect(query['catalogo'], 'cat-1');
      expect(query['seVende'], true);
      // items == null -> habilitadoKiosco true; sortByPriority false -> omitted
      expect(query['habilitadoKiosco'], true);
      expect(query.containsKey('sortPrioridadKiosco'), isFalse);
    });
  });

  group('getComanda', () {
    test('GET /comandas/uuid/{uuid} parses a single comanda', () async {
      when(() => dio.get(uri: any(named: 'uri'), options: any(named: 'options')))
          .thenAnswer((_) async => dioResponse(
              {'id': 42, 'fecha': '2024-01-01', 'creado': '2024-01-01'}));

      final comanda = await repository.getComanda(orderUuid: 'abc-uuid');

      expect(comanda.id, 42);
      final uri = verify(() =>
              dio.get(uri: captureAny(named: 'uri'), options: any(named: 'options')))
          .captured
          .single;
      expect(uri, '/comandas/uuid/abc-uuid');
    });
  });
}
