import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/invoice.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/print_log_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:izi_kiosco/domain/dto/new_order_dto.dart';
import 'package:izi_kiosco/domain/dto/payment_dto.dart';
import 'package:izi_kiosco/domain/dto/print_log_dto.dart';
import 'package:izi_kiosco/domain/utils/print/print_result.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockComandaRepository extends Mock implements ComandaRepository {}

class MockBusinessRepository extends Mock implements BusinessRepository {}

class MockSocketRepository extends Mock implements SocketRepository {}

class MockPrintLogRepository extends Mock implements PrintLogRepository {}

class MockPrintUtils extends Mock implements PrintUtils {}

class FakeCharge extends Fake implements Charge {}

class FakePaymentDto extends Fake implements PaymentDto {}

class FakeNewOrderDto extends Fake implements NewOrderDto {}

const int _checkNumberSimphony = 8801;
const int _numeroComanda = 412;
const int _numeroCustomSocket = 77;

void main() {
  late MockComandaRepository comandaRepository;
  late MockBusinessRepository businessRepository;
  late MockSocketRepository socketRepository;
  late MockPrintLogRepository printLogRepository;
  late MockPrintUtils printUtils;

  setUpAll(() {
    registerFallbackValue(<IziPrintItem>[]);
    registerFallbackValue(<PrintLogDto>[]);
    registerFallbackValue(FakeCharge());
    registerFallbackValue(FakePaymentDto());
    registerFallbackValue(FakeNewOrderDto());
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    comandaRepository = MockComandaRepository();
    businessRepository = MockBusinessRepository();
    socketRepository = MockSocketRepository();
    printLogRepository = MockPrintLogRepository();
    printUtils = MockPrintUtils();

    when(() => printLogRepository.sendLogs(
        eventos: any(named: 'eventos'),
        sucursalId: any(named: 'sucursalId'))).thenAnswer((_) async {});

    // Sin esto los timers de la pantalla de éxito mantienen el test vivo 10-30s.
    AppConstants.successScreenTime = const Duration(milliseconds: 5);
    AppConstants.successScreenTimePrintError = const Duration(milliseconds: 5);
  });

  AuthState authState({bool logImpresion = true}) => AuthState(
        status: AuthStatus.okAuth,
        currencies: const [],
        loadingContribuyente: false,
        terminalInit: false,
        devices: const [],
        video: null,
        catalog: null,
        currentContribuyente: Contribuyente(
            id: 1,
            razonSocial: "iZi Test",
            actividadesEconomicas: const [],
            autorizadosAPI: const []),
        currentSucursal: Sucursal(id: 3, nombre: "Casa Matriz"),
        currentDevice: Device(
          id: 7,
          sucursal: 3,
          nombre: "Kiosco 1",
          caja: 11,
          activo: true,
          enUso: true,
          config: ConfigDevice.fromJson({"logImpresion": logImpresion}),
        ),
      );

  Comanda comanda({dynamic custom, int? numero, int? factura}) => Comanda(
        id: 500,
        comandasPdf: const [],
        consumoInterno: false,
        creado: DateTime(2026, 8, 22),
        fecha: DateTime(2026, 8, 22),
        descuentos: 0,
        facturada: 0,
        isTerminada: false,
        listaItems: const [],
        anulada: 0,
        monto: 100,
        paraLlevar: false,
        custom: custom,
        numero: numero,
        factura: factura,
      );

  PaymentBloc buildBloc() => PaymentBloc(
        comandaRepository,
        businessRepository,
        socketRepository,
        printUtils: printUtils,
        printLogRepository: printLogRepository,
      );

  void printDevuelve(PrintResult resultado) {
    when(() => printUtils.print(any())).thenAnswer((_) async => resultado);
  }

  void printDevuelveEnSecuencia(List<PrintResult> resultados) {
    var i = 0;
    when(() => printUtils.print(any())).thenAnswer((_) async {
      var resultado = resultados[i.clamp(0, resultados.length - 1)];
      i++;
      return resultado;
    });
  }

  group('pago en caja (selectPayment)', () {
    blocTest<PaymentBloc, PaymentState>(
      'con impresión exitosa llega a step 5 sin marcar printFailed',
      setUp: () {
        printDevuelve(PrintResult.exito(PrintVia.webPdf, 120));
        when(() => comandaRepository.markAsCreated(any())).thenAnswer((_) async =>
            comanda(custom: {
              "simphony": {
                "header": {"checkNumber": _checkNumberSimphony}
              }
            }));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(PaymentType.cashRegister, authState()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.step, 5);
        expect(bloc.state.printFailed, isFalse);
        expect(bloc.state.orderNumber, _checkNumberSimphony);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'si la impresión falla igual llega a step 5, pero marca printFailed',
      setUp: () {
        printDevuelve(PrintResult.fallo(PrintVia.webPdf, 90, "sin impresora"));
        when(() => comandaRepository.markAsCreated(any())).thenAnswer((_) async =>
            comanda(custom: {
              "simphony": {
                "header": {"checkNumber": _checkNumberSimphony}
              }
            }));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(PaymentType.cashRegister, authState()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.step, 5);
        expect(bloc.state.printFailed, isTrue);
        expect(bloc.state.orderNumber, _checkNumberSimphony);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'un timeout de impresión no cuelga el flujo',
      setUp: () {
        printDevuelve(PrintResult.porTiempo(PrintVia.webPdf, 6000));
        when(() => comandaRepository.markAsCreated(any())).thenAnswer((_) async =>
            comanda(custom: {
              "simphony": {
                "header": {"checkNumber": _checkNumberSimphony}
              }
            }));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(PaymentType.cashRegister, authState()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.step, 5);
        expect(bloc.state.printFailed, isTrue);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'sin datos de Simphony toma el número de la comanda',
      setUp: () {
        printDevuelve(PrintResult.exito(PrintVia.webPdf, 120));
        when(() => comandaRepository.markAsCreated(any()))
            .thenAnswer((_) async => comanda(numero: _numeroComanda));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(PaymentType.cashRegister, authState()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.orderNumber, _numeroComanda);
      },
    );
  });

  group('reintento', () {
    blocTest<PaymentBloc, PaymentState>(
      'reintenta exactamente una vez cuando el primer intento falla',
      setUp: () {
        printDevuelve(PrintResult.fallo(PrintVia.webPdf, 90, "sin impresora"));
        when(() => comandaRepository.markAsCreated(any())).thenAnswer((_) async =>
            comanda(custom: {
              "simphony": {
                "header": {"checkNumber": _checkNumberSimphony}
              }
            }));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(PaymentType.cashRegister, authState()),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => printUtils.print(any())).called(2);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'no reintenta cuando el primer intento sale bien',
      setUp: () {
        printDevuelve(PrintResult.exito(PrintVia.webPdf, 120));
        when(() => comandaRepository.markAsCreated(any())).thenAnswer((_) async =>
            comanda(custom: {
              "simphony": {
                "header": {"checkNumber": _checkNumberSimphony}
              }
            }));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(PaymentType.cashRegister, authState()),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => printUtils.print(any())).called(1);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'si el reintento sale bien no marca printFailed',
      setUp: () {
        printDevuelveEnSecuencia([
          PrintResult.fallo(PrintVia.webPdf, 90, "primer intento falló"),
          PrintResult.exito(PrintVia.webPdf, 120),
        ]);
        when(() => comandaRepository.markAsCreated(any())).thenAnswer((_) async =>
            comanda(custom: {
              "simphony": {
                "header": {"checkNumber": _checkNumberSimphony}
              }
            }));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(PaymentType.cashRegister, authState()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.printFailed, isFalse);
        verify(() => printUtils.print(any())).called(2);
      },
    );
  });

  group('flag de logging', () {
    blocTest<PaymentBloc, PaymentState>(
      'con logImpresion en true envía un evento por intento',
      setUp: () {
        printDevuelve(PrintResult.fallo(PrintVia.webPdf, 90, "sin impresora"));
        when(() => comandaRepository.markAsCreated(any())).thenAnswer((_) async =>
            comanda(custom: {
              "simphony": {
                "header": {"checkNumber": _checkNumberSimphony}
              }
            }));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(PaymentType.cashRegister, authState()),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => printLogRepository.sendLogs(
            eventos: any(named: 'eventos'),
            sucursalId: any(named: 'sucursalId'))).called(2);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'con logImpresion en false no envía nada',
      setUp: () {
        printDevuelve(PrintResult.fallo(PrintVia.webPdf, 90, "sin impresora"));
        when(() => comandaRepository.markAsCreated(any())).thenAnswer((_) async =>
            comanda(custom: {
              "simphony": {
                "header": {"checkNumber": _checkNumberSimphony}
              }
            }));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(
          PaymentType.cashRegister, authState(logImpresion: false)),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verifyNever(() => printLogRepository.sendLogs(
            eventos: any(named: 'eventos'),
            sucursalId: any(named: 'sucursalId')));
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'el evento registra el número de orden y el resultado del intento',
      setUp: () {
        printDevuelve(PrintResult.fallo(PrintVia.webPdf, 90, "sin impresora"));
        when(() => comandaRepository.markAsCreated(any())).thenAnswer((_) async =>
            comanda(custom: {
              "simphony": {
                "header": {"checkNumber": _checkNumberSimphony}
              }
            }));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(PaymentType.cashRegister, authState()),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        var enviados = verify(() => printLogRepository.sendLogs(
                eventos: captureAny(named: 'eventos'),
                sucursalId: any(named: 'sucursalId')))
            .captured
            .expand((e) => e as List<PrintLogDto>)
            .toList();

        expect(enviados.map((e) => e.intento), [1, 2]);
        expect(enviados.every((e) => e.resultado == "ERROR"), isTrue);
        expect(enviados.every((e) => e.tipoDocumento == "ORDEN"), isTrue);
        expect(enviados.every((e) => e.numeroOrden == _checkNumberSimphony), isTrue);
        expect(enviados.every((e) => e.dispositivoId == 7), isTrue);
        expect(enviados.every((e) => e.cajaId == 11), isTrue);
        expect(enviados.map((e) => e.eventoId).toSet(), hasLength(2));
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'si el logging falla el flujo de pago continúa igual',
      setUp: () {
        printDevuelve(PrintResult.exito(PrintVia.webPdf, 120));
        when(() => printLogRepository.sendLogs(
                eventos: any(named: 'eventos'),
                sucursalId: any(named: 'sucursalId')))
            .thenThrow(Exception("backend caído"));
        when(() => comandaRepository.markAsCreated(any())).thenAnswer((_) async =>
            comanda(custom: {
              "simphony": {
                "header": {"checkNumber": _checkNumberSimphony}
              }
            }));
      },
      build: buildBloc,
      act: (bloc) => bloc.selectPayment(PaymentType.cashRegister, authState()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.step, 5);
        expect(bloc.state.printFailed, isFalse);
      },
    );
  });

  group('pago con QR (socket)', () {
    late StreamController<dynamic> socket;

    setUp(() {
      socket = StreamController<dynamic>.broadcast();
      when(() => socketRepository.listenPayment(charge: any(named: 'charge')))
          .thenAnswer((_) => socket.stream);
      when(() => socketRepository.closeQrListening()).thenAnswer((_) async {});
      when(() => comandaRepository.generatePayment(
              contribuyenteId: any(named: 'contribuyenteId'),
              payment: any(named: 'payment')))
          .thenAnswer((_) async => const Charge(
              qrUrl: "https://qr", uuid: "uuid-1", qrBase64: null, token: "tok", id: 1));
      when(() => comandaRepository.getInvoice(any())).thenAnswer((_) async =>
          Invoice(
              id: "900",
              comprador: "0",
              descuentos: 0,
              emisor: "1",
              fecha: "2026-08-22",
              prefactura: 0,
              razonSocial: "Cliente",
              razonSocialEmisor: "iZi Test",
              listaItems: const []));
      when(() => comandaRepository.getComanda(orderId: any(named: 'orderId')))
          .thenAnswer((_) async => comanda(numero: _numeroComanda));
      when(() => comandaRepository.editOrder(newOrder: any(named: 'newOrder')))
          .thenAnswer((_) async => comanda(numero: _numeroComanda));
    });

    tearDown(() => socket.close());

    blocTest<PaymentBloc, PaymentState>(
      'toma el numeroCustom del evento del socket como número de orden',
      setUp: () => printDevuelve(PrintResult.exito(PrintVia.webPdf, 120)),
      build: buildBloc,
      act: (bloc) async {
        bloc.emit(bloc.state.copyWith(
            // _validateInputs() exige teléfono, si no generateQR corta antes del socket.
            phoneNumber: bloc.state.phoneNumber.changeValue("77712345"),
            paymentObj: PaymentObj(
                id: 500,
                amount: 100,
                uuid: "uuid-order",
                custom: {},
                isComanda: true,
                items: const [])));
        await bloc.generateQR(authState());
        socket.add({
          "statusVenta": "success",
          "numeroOrden": 900,
          "numeroCustom": _numeroCustomSocket,
          "idFactura": 900,
        });
        await Future.delayed(const Duration(milliseconds: 30));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        expect(bloc.state.step, 5);
        expect(bloc.state.orderNumber, _numeroCustomSocket);
        expect(bloc.state.printFailed, isFalse);
      },
    );

    blocTest<PaymentBloc, PaymentState>(
      'imprime orden y factura, y si una falla marca printFailed',
      setUp: () => printDevuelveEnSecuencia([
        PrintResult.exito(PrintVia.webPdf, 120),
        PrintResult.fallo(PrintVia.webPdf, 90, "falló la factura"),
        PrintResult.fallo(PrintVia.webPdf, 90, "falló la factura"),
      ]),
      build: buildBloc,
      act: (bloc) async {
        bloc.emit(bloc.state.copyWith(
            // _validateInputs() exige teléfono, si no generateQR corta antes del socket.
            phoneNumber: bloc.state.phoneNumber.changeValue("77712345"),
            paymentObj: PaymentObj(
                id: 500,
                amount: 100,
                uuid: "uuid-order",
                custom: {},
                isComanda: true,
                items: const [])));
        await bloc.generateQR(authState());
        socket.add({
          "statusVenta": "success",
          "numeroOrden": 900,
          "numeroCustom": _numeroCustomSocket,
          "idFactura": 900,
        });
        await Future.delayed(const Duration(milliseconds: 30));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        expect(bloc.state.step, 5);
        expect(bloc.state.printFailed, isTrue);
      },
    );
  });
}
