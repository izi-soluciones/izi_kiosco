import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/local/local_storage_atc_pending.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/atc_payment_error.dart';
import 'package:izi_kiosco/domain/models/atc_payment_status.dart';
import 'package:izi_kiosco/domain/models/atc_pending_payment.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AtcCall {
  final String amount;
  final String ip;
  final String? ref;
  final CancelToken cancelToken;
  final List<AtcPendingPayment> pendingAtCall;
  _AtcCall(this.amount, this.ip, this.ref, this.cancelToken, this.pendingAtCall);
}

class _FakeComandaRepository implements ComandaRepository {
  final List<_AtcCall> atcCalls = [];
  final List<String> confirmed = [];
  final List<List<Object?>> marked = [];
  final List<String> statusQueries = [];

  /// Lo que hace el POS con cada llamada a /v2/ctl.
  Future<CardPayment> Function(_AtcCall call) onAtc =
      (call) async => _approvedCard();

  /// Respuestas de GET /v2/pago/:ref, en orden; la última se repite.
  List<Object> statuses = [];

  /// Respuesta fija de GET /v2/pago/:ref para un ref puntual (gana sobre statuses).
  final Map<String, Object> statusByRef = {};
  bool confirmFails = false;
  bool markFails = false;
  int attemptsGenerated = 0;
  int paymentsGenerated = 0;

  @override
  Future<Charge> generatePaymentAttempt(dynamic paymentAttemptDto) async {
    attemptsGenerated++;
    return const Charge(
        qrUrl: null,
        uuid: 'venta-1',
        id: 77,
        intentoPago: 77,
        qrBase64: null,
        token: null);
  }

  @override
  Future<Charge> generatePayment(
      {required int contribuyenteId, required dynamic payment}) async {
    paymentsGenerated++;
    return const Charge(
        qrUrl: null, uuid: 'cobro-9', id: 9, qrBase64: null, token: null);
  }

  @override
  Future<CardPayment> callCardPaymentATC(
      {required String amount,
      required String ip,
      required CancelToken cancelToken,
      required bool contactless,
      String? ref}) async {
    final call = _AtcCall(amount, ip, ref, cancelToken,
        await LocalStorageAtcPending.getPending());
    atcCalls.add(call);
    return onAtc(call);
  }

  @override
  Future<AtcPaymentStatus> getPaymentStatusATC(String ref) async {
    statusQueries.add(ref);
    final next = statusByRef[ref] ??
        (statuses.length > 1 ? statuses.removeAt(0) : statuses.first);
    if (next is AtcPaymentStatus) {
      return next;
    }
    throw next;
  }

  @override
  Future<void> confirmPaymentATC(String ref) async {
    confirmed.add(ref);
    if (confirmFails) {
      throw 'Network Error';
    }
  }

  @override
  Future<void> markPaymentATC(String chargeUuid, int? internalId) async {
    if (markFails) {
      throw 'Network Error';
    }
    marked.add([chargeUuid, internalId]);
  }

  @override
  Future<void> cancelPaymentAttempt({required String uuid}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBusinessRepository implements BusinessRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSocketRepository implements SocketRepository {
  @override
  Stream<dynamic> listenPayment({required Charge charge}) =>
      const Stream.empty();

  @override
  closeQrListening() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _TestPaymentBloc extends PaymentBloc {
  // onChange corre dentro de emit: el stream entrega tarde y saltea estados iguales
  final List<PaymentStatus> statuses = [];

  _TestPaymentBloc(super.comandas, super.negocios, super.socket)
      : super(
            atcPollInterval: const Duration(milliseconds: 5),
            atcVerifyTimeout: const Duration(milliseconds: 60));

  void seed(PaymentState state) => emit(state);

  @override
  void onChange(Change<PaymentState> change) {
    super.onChange(change);
    statuses.add(change.nextState.status);
  }
}

CardPayment _approvedCard() => CardPayment.fromJsonATC({
      "codigo_autorizacion": "413715",
      "ult_4_digitos": "4167",
      "fecha_transac": "1021",
      "hora_transac": "1456",
      "cod_respuesta": "00"
    });

AtcPaymentStatus _status(String estado, {Object? resultado, bool confirmado = false}) =>
    AtcPaymentStatus(
        ref: 'r', estado: estado, resultado: resultado, confirmado: confirmado);

final _approvedResult = {
  "status": true,
  "data": {
    "codigo_autorizacion": "413715",
    "ult_4_digitos": "4167",
    "fecha_transac": "1021",
    "hora_transac": "1456",
    "cod_respuesta": "00"
  }
};

final _rejectedResult = {
  "status": false,
  "data": {
    "error": {"cod_error": "51", "mensaje_error": "FONDOS INSUFICIENTES"}
  }
};

AuthState _authState() {
  return AuthState.init().copyWith(
      currentContribuyente:
          Contribuyente.fromJson({"modulos": {"facturacion": {"enabled": false}}}),
      currentDevice: Device.fromJson({
        "id": 1,
        "sucursal": 1,
        "nombre": "totem",
        "caja": 1,
        "config": {"isRetail": true, "ipAtc": "192.168.0.101"}
      }));
}

// Un intento de una cobranza anterior, guardado como lo guarda el kiosko
Future<void> _seedPending(String ref,
    {required String uuid,
    required int? intentoPago,
    required String kind,
    required String orderUuid}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('atcPendingPayments', [
    ...prefs.getStringList('atcPendingPayments') ?? [],
    jsonEncode({
      "ref": ref,
      "uuid": uuid,
      "intentoPago": intentoPago,
      "kind": kind,
      "orderUuid": orderUuid,
      "amount": "30.00",
      "createdAt": DateTime.now().toIso8601String()
    })
  ]);
}

Future<CardPayment> Function(_AtcCall) _throws(AtcPaymentErrorType type) =>
    (call) async => throw AtcPaymentError(type, 'POS');

void main() {
  late _FakeComandaRepository comandas;
  late _TestPaymentBloc bloc;
  late List<PaymentStatus> statuses;
  final authState = _authState();

  void seedOrder({required bool isComanda}) {
    bloc.seed(bloc.state.copyWith(
        step: 1,
        status: PaymentStatus.successGet,
        paymentObj: PaymentObj(
            id: 5,
            custom: {},
            amount: 30,
            isComanda: isComanda,
            uuid: isComanda ? 'comanda-5' : 'venta-1',
            items: [])));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    comandas = _FakeComandaRepository();
    bloc = _TestPaymentBloc(
        comandas, _FakeBusinessRepository(), _FakeSocketRepository());
    statuses = bloc.statuses;
  });

  tearDown(() async {
    bloc.timerManual?.cancel();
    bloc.timerQR?.cancel();
    await bloc.close();
  });

  Future<bool> payAtc() => bloc.makeCardPayment(authState, atc: true);
  // Future.sync: espera el borrado del intento si answerAtcVoucher devuelve un Future
  Future<void> answerVoucher(bool hasVoucher) =>
      Future.sync(() => bloc.answerAtcVoucher(authState, hasVoucher));

  group('retail', () {
    setUp(() => seedOrder(isComanda: false));

    test('guarda el intento antes de llamar al POS y le manda su ref', () async {
      await payAtc();

      final call = comandas.atcCalls.single;
      expect(call.ref, isNotNull);
      expect(call.ref, startsWith('venta-1-77-'));
      expect(call.ref, matches(RegExp(r'^[A-Za-z0-9_-]{1,64}$')));
      final pending = call.pendingAtCall.single;
      expect(pending.ref, call.ref);
      expect(pending.uuid, 'venta-1');
      expect(pending.intentoPago, 77);
      expect(pending.kind, AtcPaymentKind.retail);
      expect(pending.amount, call.amount);
    });

    test('aprobado inmediato: marca el pago, confirma y borra el intento', () async {
      final result = await payAtc();

      expect(result, isTrue);
      expect(comandas.marked, [
        ['venta-1', 77]
      ]);
      expect(comandas.confirmed, [comandas.atcCalls.single.ref]);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
      expect(comandas.statusQueries, isEmpty);
    });

    test('aprobado inmediato: un fallo al confirmar no rompe el pago', () async {
      comandas.confirmFails = true;

      final result = await payAtc();

      expect(result, isTrue);
      expect(statuses, isNot(contains(PaymentStatus.cardError)));
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });

    test('rechazado: error actual, confirma y borra el intento', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.rejected);

      final result = await payAtc();

      expect(result, isFalse);
      expect(statuses, contains(PaymentStatus.cardError));
      expect(comandas.confirmed, [comandas.atcCalls.single.ref]);
      expect(comandas.marked, isEmpty);
      expect(comandas.statusQueries, isEmpty);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });

    test('pagoEnCurso: mensaje propio, no es un pago incierto', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.paymentInProgress);

      final result = await payAtc();

      expect(result, isFalse);
      expect(statuses, contains(PaymentStatus.cardPosBusy));
      expect(statuses, isNot(contains(PaymentStatus.cardVerifying)));
      expect(statuses, isNot(contains(PaymentStatus.cardUncertain)));
      expect(statuses, isNot(contains(PaymentStatus.cardError)));
      expect(comandas.statusQueries, isEmpty);
      expect(comandas.marked, isEmpty);
      expect(bloc.state.step, 1);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });

    test('timeout y la consulta dice aprobado: marca el pago con uuid e intentoPago', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.uncertain);
      comandas.statuses = [
        _status(AtcPaymentStatus.inProgress),
        _status(AtcPaymentStatus.approved, resultado: _approvedResult)
      ];

      final result = await payAtc();

      expect(result, isTrue);
      expect(statuses, contains(PaymentStatus.cardVerifying));
      expect(comandas.statusQueries,
          everyElement(comandas.atcCalls.single.ref));
      expect(comandas.statusQueries.length, 2);
      expect(comandas.marked, [
        ['venta-1', 77]
      ]);
      expect(comandas.confirmed, [comandas.atcCalls.single.ref]);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });

    test('timeout y la consulta dice rechazado: error actual y confirma', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.uncertain);
      comandas.statuses = [
        _status(AtcPaymentStatus.rejected, resultado: _rejectedResult)
      ];

      final result = await payAtc();

      expect(result, isFalse);
      expect(statuses, contains(PaymentStatus.cardVerifying));
      expect(statuses.last, PaymentStatus.successGet);
      expect(statuses, contains(PaymentStatus.cardError));
      expect(comandas.marked, isEmpty);
      expect(comandas.confirmed, [comandas.atcCalls.single.ref]);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });

    test('timeout y la consulta dice noEncontrado: error actual sin confirmar', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.uncertain);
      comandas.statuses = [_status(AtcPaymentStatus.notFound)];

      final result = await payAtc();

      expect(result, isFalse);
      expect(statuses, contains(PaymentStatus.cardVerifying));
      expect(comandas.statusQueries, [comandas.atcCalls.single.ref]);
      expect(statuses, contains(PaymentStatus.cardError));
      expect(comandas.marked, isEmpty);
      expect(comandas.confirmed, isEmpty);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });

    test('timeout y sigue enCurso hasta el límite: pago incierto con el código corto', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.uncertain);
      comandas.statuses = [
        _status(AtcPaymentStatus.inProgress),
        'Network Error',
        _status(AtcPaymentStatus.noResponse)
      ];

      final result = await payAtc();

      final ref = comandas.atcCalls.single.ref!;
      expect(result, isFalse);
      expect(bloc.state.status, PaymentStatus.cardUncertain);
      expect(bloc.state.atcCode, ref.substring(ref.length - 6));
      expect(statuses, isNot(contains(PaymentStatus.cardError)));
      expect(comandas.statusQueries.length, greaterThan(3));
      expect(comandas.marked, isEmpty);
      expect(comandas.confirmed, isEmpty);
      expect((await LocalStorageAtcPending.getPending()).single.ref, ref);
    });

    test('voucher Sí: queda bloqueado y no deja reintentar con tarjeta', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.uncertain);
      comandas.statuses = [_status(AtcPaymentStatus.noResponse)];
      await payAtc();

      await answerVoucher(true);

      expect(bloc.state.status, PaymentStatus.cardBlocked);
      expect(bloc.state.atcBlocked, isTrue);
      expect(await payAtc(), isFalse);
      expect(comandas.atcCalls.length, 1);
    });

    test('voucher Sí: el intento sale de la resolución automática sin confirmar', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.uncertain);
      comandas.statuses = [_status(AtcPaymentStatus.noResponse)];
      await payAtc();

      await answerVoucher(true);

      expect(await LocalStorageAtcPending.getPending(), isEmpty);
      expect(comandas.confirmed, isEmpty);
      expect(comandas.marked, isEmpty);
    });

    test('voucher No: error actual y puede reintentar', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.uncertain);
      comandas.statuses = [_status(AtcPaymentStatus.noResponse)];
      await payAtc();

      await answerVoucher(false);

      expect(statuses, contains(PaymentStatus.cardError));
      expect(bloc.state.status, PaymentStatus.successGet);
      expect(bloc.state.step, 1);
      expect(bloc.state.atcBlocked, isFalse);
      expect((await LocalStorageAtcPending.getPending()).length, 1);

      comandas.onAtc = (call) async => _approvedCard();
      expect(await payAtc(), isTrue);
      expect(comandas.atcCalls.length, 2);
      expect(comandas.atcCalls.last.ref, isNot(comandas.atcCalls.first.ref));
    });

    test('cancelación del cliente: consulta y si el POS cobró sigue como pago exitoso', () async {
      comandas.onAtc = (call) async {
        await call.cancelToken.whenCancel;
        throw const AtcPaymentError(AtcPaymentErrorType.uncertain, 'cancel');
      };
      comandas.statuses = [
        _status(AtcPaymentStatus.approved, resultado: _approvedResult)
      ];

      final payment = payAtc();
      await Future.delayed(const Duration(milliseconds: 10));
      bloc.cancelPaymentCard();
      final result = await payment;

      expect(result, isTrue);
      expect(comandas.statusQueries, [comandas.atcCalls.single.ref]);
      expect(comandas.marked, [
        ['venta-1', 77]
      ]);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });
  });

  group('retail, ronda 2', () {
    setUp(() => seedOrder(isComanda: false));

    test('timeout y la consulta dice rechazado aunque resultado traiga status true: no se marca', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.uncertain);
      comandas.statuses = [
        _status(AtcPaymentStatus.rejected, resultado: _approvedResult)
      ];

      final result = await payAtc();

      expect(result, isFalse);
      expect(comandas.marked, isEmpty);
      expect(statuses, contains(PaymentStatus.cardError));
      expect(comandas.confirmed, [comandas.atcCalls.single.ref]);
    });

    test('timeout y aprobado sin cod_respuesta 00: no se marca y termina incierto', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.uncertain);
      comandas.statuses = [
        _status(AtcPaymentStatus.approved, resultado: {
          "status": true,
          "data": {"codigo_autorizacion": "", "cod_respuesta": "51"}
        })
      ];

      final result = await payAtc();

      expect(result, isFalse);
      expect(comandas.marked, isEmpty);
      expect(bloc.state.status, PaymentStatus.cardUncertain);
    });

    for (final preventa in <String, Object>{
      'texto "El IP no existe"': 'El IP no existe o el POS no está conectado',
      'JSON "El número IP … no existe"': {
        "resp": "El número IP192.168.0.101 no existe"
      },
      'texto "El monto debe ser…"':
          'El monto debe ser un numero entero mayor a cero',
      'codigo refInvalido': {
        "ipcaja": "192.168.0.101",
        "status": "error",
        "codigo": "refInvalido",
        "resp": "Referencia de pago inválida"
      },
    }.entries) {
      test('${preventa.key}: error actual sin verificar ni preguntar por el voucher', () async {
        comandas.onAtc =
            (call) async => throw AtcPaymentError.fromResponse(preventa.value);

        final result = await payAtc();

        expect(result, isFalse);
        expect(statuses, contains(PaymentStatus.cardError));
        expect(statuses, isNot(contains(PaymentStatus.cardVerifying)));
        expect(comandas.statusQueries, isEmpty);
        expect(comandas.confirmed, isEmpty);
        expect(await LocalStorageAtcPending.getPending(), isEmpty);
      });
    }

    test('codigo refRepetido se verifica como incierto', () async {
      comandas.onAtc = (call) async => throw AtcPaymentError.fromResponse({
            "ipcaja": "192.168.0.101",
            "status": "error",
            "codigo": "refRepetido",
            "resp": "Ese intento de pago ya se envió al POS",
            "estado": "enCurso"
          });
      comandas.statuses = [
        _status(AtcPaymentStatus.approved, resultado: _approvedResult)
      ];

      final result = await payAtc();

      expect(result, isTrue);
      expect(statuses, contains(PaymentStatus.cardVerifying));
    });

    test('un intento anterior aprobado de la misma orden se completa sin volver a cobrar', () async {
      await _seedPending('venta-1-70-old',
          uuid: 'venta-1', intentoPago: 70, kind: 'retail', orderUuid: 'venta-1');
      comandas.statusByRef['venta-1-70-old'] =
          _status(AtcPaymentStatus.approved, resultado: _approvedResult);

      final result = await payAtc();

      expect(result, isTrue);
      expect(comandas.atcCalls, isEmpty);
      expect(comandas.attemptsGenerated, 0);
      expect(comandas.marked, [
        ['venta-1', 70]
      ]);
      expect(comandas.confirmed, ['venta-1-70-old']);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });

    test('un intento anterior de la misma orden en curso: POS ocupado, no se cobra', () async {
      await _seedPending('venta-1-70-old',
          uuid: 'venta-1', intentoPago: 70, kind: 'retail', orderUuid: 'venta-1');
      comandas.statusByRef['venta-1-70-old'] =
          _status(AtcPaymentStatus.inProgress);

      final result = await payAtc();

      expect(result, isFalse);
      expect(statuses, contains(PaymentStatus.cardPosBusy));
      expect(comandas.atcCalls, isEmpty);
      expect(comandas.marked, isEmpty);
    });

    test('un intento aprobado de otra orden no cuenta: se cobra normal', () async {
      await _seedPending('venta-2-50-old',
          uuid: 'venta-2', intentoPago: 50, kind: 'retail', orderUuid: 'venta-2');
      comandas.statusByRef['venta-2-50-old'] =
          _status(AtcPaymentStatus.approved, resultado: _approvedResult);

      final result = await payAtc();

      expect(result, isTrue);
      expect(comandas.atcCalls.length, 1);
      expect(comandas.marked, [
        ['venta-1', 77]
      ]);
      expect((await LocalStorageAtcPending.getPending()).single.ref,
          'venta-2-50-old');
    });
  });

  group('markPaymentATC falla los 10 reintentos', () {
    for (final isComanda in [false, true]) {
      testWidgets(
          '${isComanda ? 'comanda' : 'retail'}: errores de tarjeta y paso 6, borra el intento sin confirmar',
          (tester) async {
        seedOrder(isComanda: isComanda);
        comandas.markFails = true;
        bool? result;
        payAtc().then((value) => result = value);
        for (var i = 0; i < 400 && result == null; i++) {
          await tester.pump(const Duration(seconds: 1));
        }

        expect(result, isFalse);
        expect(bloc.state.step, 6);
        expect(comandas.confirmed, isEmpty);
        expect(await LocalStorageAtcPending.getPending(), isEmpty);
        expect((await LocalStorageCardErrors.getErrors()).length, 1);
        // Vacía los temporizadores del flujo (paso 6 → inicio, y los 5 min de la comanda)
        bloc.timerManual?.cancel();
        await tester.pump(const Duration(minutes: 6));
      });
    }
  });

  group('comanda', () {
    setUp(() => seedOrder(isComanda: true));

    test('aprobado inmediato: marca el cobro, confirma y borra el intento', () async {
      final result = await payAtc();

      final call = comandas.atcCalls.single;
      expect(result, isTrue);
      expect(call.ref, startsWith('cobro-9-'));
      expect(call.pendingAtCall.single.kind, AtcPaymentKind.comanda);
      expect(call.pendingAtCall.single.uuid, 'cobro-9');
      expect(call.pendingAtCall.single.intentoPago, isNull);
      expect(comandas.marked, [
        ['cobro-9', null]
      ]);
      expect(comandas.confirmed, [call.ref]);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });

    test('un intento anterior aprobado de la misma orden se completa sin volver a cobrar', () async {
      await _seedPending('cobro-old-x',
          uuid: 'cobro-old', intentoPago: null, kind: 'comanda', orderUuid: 'comanda-5');
      comandas.statusByRef['cobro-old-x'] =
          _status(AtcPaymentStatus.approved, resultado: _approvedResult);

      final result = await payAtc();

      expect(result, isTrue);
      expect(comandas.atcCalls, isEmpty);
      expect(comandas.paymentsGenerated, 0);
      expect(comandas.marked, [
        ['cobro-old', null]
      ]);
      expect(comandas.confirmed, ['cobro-old-x']);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });

    test('timeout y la consulta dice aprobado: marca el cobro sin intentoPago', () async {
      comandas.onAtc = _throws(AtcPaymentErrorType.uncertain);
      comandas.statuses = [
        _status(AtcPaymentStatus.approved, resultado: _approvedResult)
      ];

      final result = await payAtc();

      expect(result, isTrue);
      expect(comandas.marked, [
        ['cobro-9', null]
      ]);
      expect(comandas.confirmed, [comandas.atcCalls.single.ref]);
      expect(await LocalStorageAtcPending.getPending(), isEmpty);
    });
  });
}
