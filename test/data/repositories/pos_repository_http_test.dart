import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/repositories/pos/pos_repository_http.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerDioFallbacks);

  late MockDioClient dio;
  late PosRepositoryHttp repository;

  setUp(() {
    dio = MockDioClient();
    repository = PosRepositoryHttp(dioClient: dio);
  });

  group('getPos', () {
    test('hits /terminales and parses a Pos when data is a map', () async {
      when(() => dio.get(
            uri: any(named: 'uri'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async =>
          dioResponse({'id': 4, 'activo': true, 'uuid': 'abc'}));

      final pos = await repository.getPos(contribuyente: 1, sucursal: 2);

      expect(pos, isNotNull);
      expect(pos!.id, 4);
      expect(pos.activo, isTrue);
      final captured = verify(() => dio.get(
            uri: captureAny(named: 'uri'),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured;
      expect(captured[0], '/terminales');
      expect(captured[1], {'contribuyente': 1, 'sucursal': 2});
    });

    test('returns null when the payload is not a map', () async {
      when(() => dio.get(
            uri: any(named: 'uri'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse('not-a-map'));

      expect(await repository.getPos(contribuyente: 1, sucursal: 2), isNull);
    });

    test('throws the server message on a non-200 status', () async {
      when(() => dio.get(
            uri: any(named: 'uri'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse(
          {'status': true, 'data': 'terminal missing'},
          statusCode: 400));

      expect(
        () => repository.getPos(contribuyente: 1, sucursal: 2),
        throwsA('terminal missing'),
      );
    });
  });

  group('activatePos', () {
    test('posts activation body and parses the Pos', () async {
      when(() => dio.post(
            uri: any(named: 'uri'),
            body: any(named: 'body'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse({'id': 9, 'activo': true}));

      final pos = await repository.activatePos(
          contribuyente: 3, sucursal: 5, isTest: true);

      expect(pos.id, 9);
      final captured = verify(() => dio.post(
            uri: captureAny(named: 'uri'),
            body: captureAny(named: 'body'),
            options: any(named: 'options'),
          )).captured;
      expect(captured[0], '/terminales/activar');
      expect(captured[1],
          {'contribuyente': 3, 'sucursal': 5, 'isPruebas': true});
    });
  });

  group('updateEnvironment', () {
    test('puts to /terminales/{id} with the isPruebas flag', () async {
      when(() => dio.put(
            uri: any(named: 'uri'),
            body: any(named: 'body'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse({'id': 7, 'isPruebas': false}));

      final pos = await repository.updateEnvironment(posId: 7, isTest: false);

      expect(pos.id, 7);
      final captured = verify(() => dio.put(
            uri: captureAny(named: 'uri'),
            body: captureAny(named: 'body'),
            options: any(named: 'options'),
          )).captured;
      expect(captured[0], '/terminales/7');
      expect(captured[1], {'isPruebas': false});
    });
  });
}
