import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/repositories/auth/auth_repository_http.dart';
import 'package:izi_kiosco/domain/dto/add_kiosk_dto.dart';
import 'package:izi_kiosco/domain/models/login/login_request.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(registerDioFallbacks);

  late MockDioClient dio;
  late AuthRepositoryHttp repository;

  setUp(() {
    dio = MockDioClient();
    repository = AuthRepositoryHttp(dioClient: dio);
  });

  void stubGet(Response<dynamic> response) {
    when(() => dio.get(uri: any(named: 'uri'), options: any(named: 'options')))
        .thenAnswer((_) async => response);
  }

  group('getContribuyentes', () {
    test('GET /contribuyentes and maps the contribuyentes array', () async {
      stubGet(dioResponse({
        'contribuyentes': [
          {'id': 1, 'nombre': 'Uno'},
          {'id': 2, 'nombre': 'Dos'},
        ]
      }));

      final list = await repository.getContribuyentes();

      expect(list.length, 2);
      expect(list.first.id, 1);
      final uri = verify(() =>
              dio.get(uri: captureAny(named: 'uri'), options: any(named: 'options')))
          .captured
          .single;
      expect(uri, '/contribuyentes');
    });

    test('throws the raw payload on a non-200', () async {
      stubGet(dioResponse({'message': 'boom'}, statusCode: 500));
      expect(() => repository.getContribuyentes(),
          throwsA({'message': 'boom'}));
    });
  });

  group('login', () {
    test('POST /login parses token + nested user', () async {
      when(() => dio.post(
            uri: any(named: 'uri'),
            body: any(named: 'body'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse({
            'token': 'tok',
            'refreshToken': 'rt',
            'usuario': {'id': 'u1', 'nombres': 'Ana'},
          }));

      final res = await repository.login(LoginRequest.init());

      expect(res.token, 'tok');
      expect(res.user.nombres, 'Ana');
      final uri = verify(() => dio.post(
            uri: captureAny(named: 'uri'),
            body: any(named: 'body'),
            options: any(named: 'options'),
          )).captured.single;
      expect(uri, '/login');
    });
  });

  group('kiosk session', () {
    test('createKioskSession accepts 201 and returns sessionId', () async {
      when(() => dio.post(uri: any(named: 'uri'), options: any(named: 'options')))
          .thenAnswer((_) async =>
              dioResponse({'sessionId': 'sess-1'}, statusCode: 201));

      expect(await repository.createKioskSession(), 'sess-1');
    });

    test('pollKioskSession returns the raw response map', () async {
      stubGet(dioResponse({'status': 'pending'}));
      final res = await repository.pollKioskSession('sess-1');
      expect(res['status'], 'pending');
    });
  });

  group('device management', () {
    test('getDevicesByContribuyente GETs /dispositivos with query', () async {
      when(() => dio.get(
            uri: any(named: 'uri'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse(const []));

      final devices = await repository.getDevicesByContribuyente(9);

      expect(devices, isEmpty);
      final captured = verify(() => dio.get(
            uri: captureAny(named: 'uri'),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured;
      expect(captured[0], '/dispositivos');
      expect(captured[1], {'contribuyente': 9});
    });

    test('addDevice completes on 200', () async {
      when(() => dio.post(
            uri: any(named: 'uri'),
            body: any(named: 'body'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse({}, statusCode: 200));

      await expectLater(
        repository.addDevice(AddKioskDto(
            name: 'K', branchOffice: 1, cashRegister: 1, business: 1)),
        completes,
      );
    });

    test('addDevice throws (stringified) on a non-200', () async {
      when(() => dio.post(
            uri: any(named: 'uri'),
            body: any(named: 'body'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => dioResponse('nope', statusCode: 400));

      expect(
        () => repository.addDevice(AddKioskDto(
            name: 'K', branchOffice: 1, cashRegister: 1, business: 1)),
        throwsA(isA<String>()),
      );
    });
  });
}
