import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/local/local_storage_print_logs.dart';
import 'package:izi_kiosco/domain/dto/print_log_dto.dart';
import 'package:izi_kiosco/domain/repositories/print_log_repository.dart';
import 'package:izi_kiosco/domain/utils/print/print_result.dart';
import 'package:izi_kiosco/domain/utils/print/print_tracking_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPrintLogRepository extends Mock implements PrintLogRepository {}

class FakePrintLogDto extends Fake implements PrintLogDto {}

void main() {
  late MockPrintLogRepository repository;
  late PrintTrackingService service;

  setUpAll(() {
    registerFallbackValue(<PrintLogDto>[]);
    registerFallbackValue(FakePrintLogDto());
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    repository = MockPrintLogRepository();
    service = PrintTrackingService(repository);
  });

  PrintLogDto evento({String tipoDocumento = "ORDEN"}) =>
      service.construirEvento(
        resultado: PrintResult.exito(PrintVia.webPdf, 120),
        tipoDocumento: tipoDocumento,
        intento: 1,
        dispositivoId: 7,
        comandaId: 99,
        numeroOrden: 412,
      );

  group('registrar', () {
    test('envía el evento y no deja nada en el buffer', () async {
      when(() => repository.sendLogs(
          eventos: any(named: 'eventos'),
          sucursalId: any(named: 'sucursalId'))).thenAnswer((_) async {});

      await service.registrar(evento(), sucursalId: 3, habilitado: true);

      verify(() => repository.sendLogs(
          eventos: any(named: 'eventos'), sucursalId: 3)).called(1);
      expect(await LocalStoragePrintLogs.getAll(), isEmpty);
    });

    test('con el flag deshabilitado no envía ni bufferea', () async {
      await service.registrar(evento(), sucursalId: 3, habilitado: false);

      verifyNever(() => repository.sendLogs(
          eventos: any(named: 'eventos'),
          sucursalId: any(named: 'sucursalId')));
      expect(await LocalStoragePrintLogs.getAll(), isEmpty);
    });

    test('si el envío falla el evento queda en el buffer local', () async {
      when(() => repository.sendLogs(
              eventos: any(named: 'eventos'),
              sucursalId: any(named: 'sucursalId')))
          .thenThrow(Exception("sin red"));

      await service.registrar(evento(), sucursalId: 3, habilitado: true);

      var pendientes = await LocalStoragePrintLogs.getAll();
      expect(pendientes, hasLength(1));
      expect(jsonDecode(pendientes.first)["numeroOrden"], 412);
    });

    test('un fallo de envío nunca propaga la excepción', () async {
      when(() => repository.sendLogs(
              eventos: any(named: 'eventos'),
              sucursalId: any(named: 'sucursalId')))
          .thenThrow(Exception("boom"));

      await expectLater(
          service.registrar(evento(), sucursalId: 3, habilitado: true),
          completes);
    });
  });

  group('flush', () {
    test('envía los pendientes en un solo lote y limpia el buffer', () async {
      when(() => repository.sendLogs(
              eventos: any(named: 'eventos'),
              sucursalId: any(named: 'sucursalId')))
          .thenThrow(Exception("sin red"));
      await service.registrar(evento(), sucursalId: 3, habilitado: true);
      await service.registrar(evento(tipoDocumento: "FACTURA"),
          sucursalId: 3, habilitado: true);
      expect(await LocalStoragePrintLogs.getAll(), hasLength(2));

      reset(repository);
      when(() => repository.sendLogs(
          eventos: any(named: 'eventos'),
          sucursalId: any(named: 'sucursalId'))).thenAnswer((_) async {});

      await service.flush(sucursalId: 3, habilitado: true);

      var capturados = verify(() => repository.sendLogs(
              eventos: captureAny(named: 'eventos'), sucursalId: 3))
          .captured
          .single as List<PrintLogDto>;
      expect(capturados, hasLength(2));
      expect(await LocalStoragePrintLogs.getAll(), isEmpty);
    });

    test('si el flush falla los pendientes se conservan', () async {
      when(() => repository.sendLogs(
              eventos: any(named: 'eventos'),
              sucursalId: any(named: 'sucursalId')))
          .thenThrow(Exception("sin red"));
      await service.registrar(evento(), sucursalId: 3, habilitado: true);

      await service.flush(sucursalId: 3, habilitado: true);

      expect(await LocalStoragePrintLogs.getAll(), hasLength(1));
    });

    test('una entrada corrupta se descarta y no bloquea el buffer', () async {
      await LocalStoragePrintLogs.add("{esto no es json}");
      when(() => repository.sendLogs(
          eventos: any(named: 'eventos'),
          sucursalId: any(named: 'sucursalId'))).thenAnswer((_) async {});

      await service.flush(sucursalId: 3, habilitado: true);

      expect(await LocalStoragePrintLogs.getAll(), isEmpty);
    });

    test('con el flag deshabilitado no envía', () async {
      await service.flush(sucursalId: 3, habilitado: false);

      verifyNever(() => repository.sendLogs(
          eventos: any(named: 'eventos'),
          sucursalId: any(named: 'sucursalId')));
    });

    test('cada evento recibe un eventoId distinto', () {
      var ids = List.generate(50, (_) => service.generarEventoId()).toSet();
      expect(ids, hasLength(50));
    });
  });

  group('buffer local', () {
    test('conserva solo los últimos 50 pendientes', () async {
      for (var i = 0; i < 60; i++) {
        await LocalStoragePrintLogs.add('{"n":$i}');
      }

      var pendientes = await LocalStoragePrintLogs.getAll();
      expect(pendientes, hasLength(50));
      expect(jsonDecode(pendientes.first)["n"], 10);
      expect(jsonDecode(pendientes.last)["n"], 59);
    });
  });
}
