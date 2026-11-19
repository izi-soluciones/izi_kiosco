import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/data/repositories/comanda/comanda_repository_http.dart';
import 'package:izi_kiosco/domain/dto/filters_comanda.dart';
import 'package:izi_kiosco/domain/dto/payment_attempt_dto.dart';
import 'package:izi_kiosco/domain/dto/payment_dto.dart';
import 'package:izi_kiosco/domain/models/charged_currency.dart';
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

  // What each payment rail is asked to charge in. The monitoring says a
  // charge was made in what its request names (ChargedCurrency): these pin
  // the requests as they are, so neither can move without the other.
  group('the money each charge request names', () {
    /// Every key anywhere in [json] that names a money.
    List<String> moneyKeys(Object? json) => [
          if (json is Map)
            for (final e in json.entries) ...[
              if (RegExp(r'moneda|currency', caseSensitive: false).hasMatch('${e.key}')) '${e.key}',
              ...moneyKeys(e.value),
            ],
          if (json is List)
            for (final v in json) ...moneyKeys(v),
        ];

    test('Linkser: /sale asks for bolivianos by number, cod_moneda 068', () async {
      when(() => dio.get(
            uri: any(named: 'uri'),
            baseUrl: any(named: 'baseUrl'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse(jsonEncode({'estado': 'False', 'mensaje': 'Aprobado'})));

      await repository.callCardPayment(amount: 1500000, ip: '10.0.0.8');

      final captured = verify(() => dio.get(
            uri: captureAny(named: 'uri'),
            baseUrl: captureAny(named: 'baseUrl'),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured;
      expect(captured[0], '/sale');
      expect(captured[1], 'http://10.0.0.8:8000');
      expect(captured[2], {'monto': '1500000', 'cod_moneda': '068'});
      expect(ChargedCurrency.linkser, 'BOB', reason: 'ISO 4217: 068 is the boliviano');
      expect(ChargedCurrency.linkserCode, '068');
    });

    test('ATC: the amount alone, no money named', () async {
      dotenv.testLoad(fileInput: '${EnvKeys.atcServerPOS}=http://atc.local');
      when(() => dio.get(
            uri: any(named: 'uri'),
            baseUrl: any(named: 'baseUrl'),
            cancelToken: any(named: 'cancelToken'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse({'status': true, 'data': {'mensaje': 'Aprobado'}}));

      for (final contactless in [true, false]) {
        await repository.callCardPaymentATC(
            amount: '150,00', ip: '10.0.0.9', cancelToken: CancelToken(), contactless: contactless);
      }

      final captured = verify(() => dio.get(
            uri: captureAny(named: 'uri'),
            baseUrl: any(named: 'baseUrl'),
            cancelToken: any(named: 'cancelToken'),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured;
      expect(captured, ['/v2/ctl/10.0.0.9/150,00/0', null, '/v2/chip/10.0.0.9/150,00/0', null]);
    });

    test('QR / Bre-B / card charge at iZi: no money named, iZi decides it', () async {
      when(() => dio.post(
            uri: any(named: 'uri'),
            body: any(named: 'body'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse({'id': 3, 'uuid': 'cobro-1', 'qr': 'iVBO'}));
      final ventaData = PaymentDtoVentaData(
          complemento: null, nit: '0', razonSocial: 'S/N', telefonoComprador: '59170000000');

      await repository.generatePayment(
          contribuyenteId: 1, payment: PaymentDto(orderId: 1, ventaData: ventaData, metodoPago: 2));
      await repository.generatePaymentAttempt(PaymentAttemptDto(
          metodoPago: 2, uuid: 'venta-1', nit: '0', razonSocial: 'S/N', telefonoComprador: null));

      final bodies = verify(() => dio.post(
            uri: any(named: 'uri'),
            body: captureAny(named: 'body'),
            options: any(named: 'options'),
          )).captured;
      expect(bodies, hasLength(2));
      for (final body in bodies) {
        expect(moneyKeys(jsonDecode(jsonEncode(body))), isEmpty, reason: '$body');
      }
    });
  });
}
