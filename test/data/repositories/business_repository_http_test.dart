import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/repositories/business/business_repository_http.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerDioFallbacks);

  late MockDioClient dio;
  late BusinessRepositoryHttp repository;

  setUp(() {
    dio = MockDioClient();
    repository = BusinessRepositoryHttp(dioClient: dio);
  });

  void stubGet(Response<dynamic> response) {
    when(() => dio.get(uri: any(named: 'uri'), options: any(named: 'options')))
        .thenAnswer((_) async => response);
  }

  group('getCashRegisters', () {
    test('builds the nested path and maps the list', () async {
      stubGet(dioResponse([
        {'id': 1, 'nombre': 'Caja', 'estado': true, 'abierta': true},
      ]));

      final list = await repository.getCashRegisters(
          contribuyenteId: 3, sucursalId: 7);

      expect(list.length, 1);
      expect(list.first.abierta, isTrue);
      final uri = verify(() =>
              dio.get(uri: captureAny(named: 'uri'), options: any(named: 'options')))
          .captured
          .single;
      expect(uri, '/contribuyentes/3/sucursales/7/cajas/simple');
    });

    test('throws the server data field on a non-200 with status flag',
        () async {
      stubGet(dioResponse({'status': true, 'data': 'denied'}, statusCode: 403));
      expect(
        () => repository.getCashRegisters(contribuyenteId: 1, sucursalId: 1),
        throwsA('denied'),
      );
    });
  });

  group('getCurrencies', () {
    test('GET /monedas-contribuyente maps currencies', () async {
      stubGet(dioResponse([
        {'id': 1, 'simbolo': r'$'},
        {'id': 2, 'simbolo': 'Bs'},
      ]));

      final list = await repository.getCurrencies(contribuyenteId: 1);
      expect(list.map((c) => c.simbolo).toList(), [r'$', 'Bs']);
    });
  });

  group('getDocumentTypes', () {
    test('reads the nested "datos" array', () async {
      stubGet(dioResponse({
        'datos': [
          {'codigoClasificador': 1, 'descripcion': 'CI'},
          {'codigoClasificador': 2, 'descripcion': 'NIT'},
        ]
      }));

      final list = await repository.getDocumentTypes();
      expect(list.length, 2);
      expect(list.first.descripcion, 'CI');
    });
  });

  group('getEconomicActivities', () {
    test('wraps a single (non-iterable) object in a list', () async {
      when(() => dio.get(
            uri: any(named: 'uri'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse(
          {'codigoCaeb': '620100', 'descripcion': 'Software'}));

      final list = await repository.getEconomicActivities(
          contribuyenteId: 1, sucursalId: 2);

      expect(list.length, 1);
      expect(list.first.codigoCaeb, '620100');
    });
  });

  group('getPayments', () {
    test('GET /comandas/{id}/pagos maps payments', () async {
      stubGet(dioResponse([
        {'id': 1, 'monto': 10},
        {'id': 2, 'monto': 20},
      ]));

      final list = await repository.getPayments(orderId: 55);
      expect(list.length, 2);
      expect(list.last.monto, 20);
      final uri = verify(() =>
              dio.get(uri: captureAny(named: 'uri'), options: any(named: 'options')))
          .captured
          .single;
      expect(uri, '/comandas/55/pagos');
    });
  });
}
