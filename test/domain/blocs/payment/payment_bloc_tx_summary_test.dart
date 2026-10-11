import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_izify_pos.dart';

/// iZi, and an ATC / Linkser terminal, steered by the test.
class _Comandas implements ComandaRepository {
  /// Thrown by ATC / Linkser instead of approving.
  Object? cardFailure;

  /// Thrown by the payment notice instead of accepting it.
  Object? markFailure;

  /// Thrown when the QR / Bre-B charge is asked for.
  Object? chargeFailure;

  /// Thrown when the order is sent to the counter.
  Object? orderFailure;
  int charges = 0;

  /// Holds the ATC / Linkser answer until completed (the customer still at
  /// the terminal), so the page can close meanwhile.
  Completer<void>? cardHeld;

  /// Holds the payment notice until completed (iZi still being told).
  Completer<void>? markHeld;

  /// Completes once the terminal is asked to charge / iZi is told.
  final charging = Completer<void>();
  final marking = Completer<void>();

  Charge _charge(String uuid) {
    charges++;
    if (chargeFailure != null) throw chargeFailure!;
    return Charge(qrUrl: null, uuid: uuid, id: charges, qrBase64: 'iVBO', token: 'tok-cobro');
  }

  @override
  Future<Charge> generatePaymentAttempt(dynamic paymentAttemptDto) async => _charge('venta-1');

  @override
  Future<Charge> generatePayment({required int contribuyenteId, required dynamic payment}) async =>
      _charge('cobro-orden-1');

  Future<CardPayment> _card() async {
    if (!charging.isCompleted) charging.complete();
    await cardHeld?.future;
    if (cardFailure != null) throw cardFailure!;
    return CardPayment(response: 'Aprobado', cardNumber: '****1111', date: '2026-10-12', hour: '14:00');
  }

  @override
  Future<CardPayment> callCardPaymentATC(
          {required String amount,
          required String ip,
          required CancelToken cancelToken,
          required bool contactless}) =>
      _card();

  @override
  Future<CardPayment> callCardPayment({required int amount, required String ip}) => _card();

  @override
  Future<void> markPaymentATC(String chargeUuid, int? internalId,
      {Map<String, dynamic>? transaccion, String? token}) async {
    if (!marking.isCompleted) marking.complete();
    await markHeld?.future;
    if (markFailure != null) throw markFailure!;
  }

  @override
  Future<void> reportTerminalResult(String chargeUuid, int? internalId, Map<String, dynamic> transaccion,
      {String? token}) async {}

  @override
  Future<Comanda> markAsCreated(String orderUuid) async {
    if (orderFailure != null) throw orderFailure!;
    return Comanda.fromJson({'creado': '2026-10-12', 'fecha': '2026-10-12', 'uuid': orderUuid});
  }

  @override
  Future<void> cancelPaymentAttempt({required String uuid}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Unused implements BusinessRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// iZi's payment socket: tests push what it would say.
class _Socket implements SocketRepository {
  final StreamController<dynamic> payments = StreamController.broadcast();

  @override
  Stream<dynamic> listenPayment({required Charge charge}) => payments.stream;

  @override
  closeQrListening() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Bloc extends PaymentBloc {
  _Bloc(super.comandas, super.negocios, super.socket, {super.izifyPosClient});

  void seed(PaymentState state) => emit(state);
}

void main() {
  late _Comandas comandas;
  late _Socket socket;
  late _Bloc bloc;
  late KioskCounters counters;

  AuthState auth(Map<String, dynamic> config) => AuthState.init().copyWith(
      currentContribuyente: Contribuyente.fromJson({'habilitadoFacturacion': false}),
      currentDevice: Device.fromJson({
        'id': 7,
        'sucursal': 1,
        'nombre': 'KIOSKO-TEST',
        'caja': 1,
        'config': {'isRetail': true, 'noPrintRollo': true, ...config},
      }));

  PaymentState order({bool isComanda = false}) => PaymentState.init().copyWith(
      step: 1,
      paymentObj: PaymentObj(
          id: 1, custom: {}, amount: 15000, isComanda: isComanda, uuid: 'venta-1', items: []));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    counters = KioskCounters();
    KioskCounters.install(counters);
    KioskActivity.install(KioskActivity());
    Telemetry.install(Telemetry(observers: [counters.observe]));
    comandas = _Comandas();
    socket = _Socket();
    bloc = _Bloc(comandas, _Unused(), socket)..seed(order());
  });

  tearDown(() async {
    await bloc.close();
    await socket.payments.close();
  });

  List<Map<String, Object?>> summaries() => [
        for (final e in Telemetry.recent().reversed)
          if (e.type == 'tx.summary') e.data,
      ];

  Future<void> paid([Map<String, dynamic> event = const {'statusVenta': 'success'}]) async {
    socket.payments.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  group('a card charge on an ATC / Linkser terminal', () {
    test('approved: summed up once iZi says the sale is done, with its invoice', () async {
      expect(await bloc.makeCardPayment(auth({'ipAtc': '10.0.0.9'}), atc: true), isTrue);
      expect(summaries(), isEmpty, reason: 'iZi is still making the sale');

      await paid({'statusVenta': 'success', 'uuidFactura': 'factura-1'});
      final tx = summaries().single;
      expect(tx['method'], 'card');
      expect(tx['status'], 'approved');
      expect(tx['chargeId'], startsWith('CHG-'));
      expect(tx['amount'], 15000);
      expect(tx['comandaId'], 'venta-1');
      expect(tx['facturaId'], 'factura-1');
      expect(tx['attempts'], 1);
      expect(tx['msToVerdict'], isA<int>());
      expect(tx['verdictVia'], isNull, reason: 'ATC answers the request itself');

      await paid();
      expect(summaries(), hasLength(1));
      expect(counters[KioskCounters.chargesApproved], 1, reason: 'counted by charge.result only');
    });

    test('a failure is an error', () async {
      comandas.cardFailure = 'Rechazada';
      expect(await bloc.makeCardPayment(auth({'ipLinkser': '10.0.0.8'}), linkser: true), isFalse);
      final tx = summaries().single;
      expect(tx['status'], 'error');
      expect(tx['attempts'], 1);
      expect(counters[KioskCounters.chargesError], 1, reason: 'not counted twice');
    });

    test('cancelled from the payment page', () async {
      comandas.cardFailure = DioException(
          requestOptions: RequestOptions(path: '/'), type: DioExceptionType.cancel);
      expect(await bloc.makeCardPayment(auth({'ipAtc': '10.0.0.9'}), atc: true), isFalse);
      expect(summaries().single['status'], 'cancelled');
    });

    test('charged and not registered in iZi', () async {
      comandas.markFailure = const PaymentConflict('otro pago');
      expect(await bloc.makeCardPayment(auth({'ipAtc': '10.0.0.9'}), atc: true), isFalse);
      expect(summaries().single['status'], 'unregistered');
    });

    test('iZi could not start the charge: an error, nothing sent', () async {
      comandas.chargeFailure = StateError('sin red');
      expect(await bloc.makeCardPayment(auth({'ipAtc': '10.0.0.9'}), atc: true), isFalse);
      final tx = summaries().single;
      expect(tx['status'], 'error');
      expect(tx['attempts'], 0);
    });

    test('the page closing after the charge, before iZi answered, keeps it approved', () async {
      expect(await bloc.makeCardPayment(auth({'ipAtc': '10.0.0.9'}), atc: true), isTrue);
      await bloc.close();
      expect(summaries().single['status'], 'approved');
    });

    // The kiosk closes the page mid-charge: IziScreenInactive sends it home.
    group('the page closing mid-charge', () {
      test('while iZi is told: without a verdict for now, approved once iZi takes it', () async {
        comandas.markHeld = Completer();
        final flow = bloc.makeCardPayment(auth({'ipAtc': '10.0.0.9'}), atc: true);
        await comandas.marking.future;
        await bloc.close();
        expect(summaries().single['status'], 'timeout', reason: 'charged, never cancelled');

        comandas.markHeld!.complete();
        await flow.catchError((_) => false);
        final txs = summaries();
        expect([for (final tx in txs) tx['status']], ['timeout', 'approved']);
        expect(txs.last['chargeId'], txs.first['chargeId']);
      });

      test('while iZi is told, and iZi does not take it: unregistered', () async {
        comandas.markHeld = Completer();
        comandas.markFailure = const PaymentConflict('otro pago');
        final flow = bloc.makeCardPayment(auth({'ipAtc': '10.0.0.9'}), atc: true);
        await comandas.marking.future;
        await bloc.close();
        comandas.markHeld!.complete();
        await flow.catchError((_) => false);
        expect([for (final tx in summaries()) tx['status']], ['timeout', 'unregistered']);
      });

      test('while the customer is at the terminal: without a verdict, not an error', () async {
        comandas.cardHeld = Completer();
        final flow = bloc.makeCardPayment(auth({'ipAtc': '10.0.0.9'}), atc: true);
        await comandas.charging.future;
        await bloc.close();
        comandas.cardHeld!.complete();
        // The flow stops at the next screen it can no longer show.
        await flow.catchError((_) => false);
        final tx = summaries().single;
        expect(tx['status'], 'timeout');
        expect(tx['attempts'], 1);
      });
    });
  });

  group('a QR payment', () {
    test('paid: approved by iZi\'s socket, and counted as a charge', () async {
      expect(await bloc.generateQR(auth({})), isTrue);
      expect(summaries(), isEmpty);

      await paid({'statusVenta': 'success', 'uuidFactura': 'factura-2'});
      final tx = summaries().single;
      expect(tx['method'], 'qr');
      expect(tx['status'], 'approved');
      expect(tx['verdictVia'], 'ws');
      expect(tx['facturaId'], 'factura-2');
      expect(tx['comandaId'], 'venta-1');
      expect(tx['attempts'], 1);
      expect(tx['msToAck'], isNull);
      expect(counters[KioskCounters.chargesStarted], 1);
      expect(counters[KioskCounters.chargesApproved], 1);
      expect(counters[KioskCounters.orders], 1);
    });

    test('paid while iZi still makes the sale: approved, even if the page closes first', () async {
      await bloc.generateQR(auth({}));
      await paid({'statusVenta': 'error'});
      // The success screen comes 60 s later.
      expect(summaries(), isEmpty);
      await bloc.close();
      final tx = summaries().single;
      expect(tx['status'], 'approved');
      expect(tx['verdictVia'], 'ws');
    });

    test('the customer cancelled it', () async {
      await bloc.generateQR(auth({}));
      bloc.cancelQR(auth({}));
      final tx = summaries().single;
      expect(tx['status'], 'cancelled');
      expect(counters[KioskCounters.chargesStarted], 1);
      expect(counters[KioskCounters.chargesDeclined], 1);

      bloc.cancelQR(auth({}));
      expect(summaries(), hasLength(1));
    });

    test('the customer went for the card instead: the QR is cancelled', () async {
      await bloc.generateQR(auth({}));
      await bloc.makeCardPayment(auth({'ipAtc': '10.0.0.9'}), atc: true);
      await paid();
      expect([for (final tx in summaries()) '${tx['method']}:${tx['status']}'],
          ['qr:cancelled', 'card:approved']);
    });

    test('the page closed with the QR on screen', () async {
      await bloc.generateQR(auth({}));
      await bloc.close();
      expect(summaries().single['status'], 'cancelled');
    });

    test('iZi could not make the QR', () async {
      comandas.chargeFailure = StateError('sin red');
      expect(await bloc.generateQR(auth({})), isFalse);
      final tx = summaries().single;
      expect(tx['status'], 'error');
      expect(tx['attempts'], 0);
    });

    test('an order paid by QR', () async {
      bloc.seed(order(isComanda: true));
      expect(await bloc.generateQR(auth({})), isTrue);
      await paid({'statusVenta': 'success', 'uuidFactura': 'factura-3'});
      final tx = summaries().single;
      expect(tx['status'], 'approved');
      expect(tx['facturaId'], 'factura-3');
    });
  });

  group('a Bre-B payment', () {
    test('paid', () async {
      expect(await bloc.generateBREB(auth({})), isTrue);
      await paid();
      final tx = summaries().single;
      expect(tx['method'], 'breb');
      expect(tx['status'], 'approved');
    });

    test('the customer cancelled it', () async {
      await bloc.generateBREB(auth({}));
      bloc.cancelBREB(auth({}));
      expect(summaries().single['status'], 'cancelled');
    });
  });

  group('an order paid at the counter', () {
    test('sent to the counter', () async {
      await bloc.selectPayment(PaymentType.cashRegister, auth({}));
      final tx = summaries().single;
      expect(tx['method'], 'cash');
      expect(tx['status'], 'approved');
      expect(tx['comandaId'], 'venta-1');
      expect(counters[KioskCounters.chargesStarted], 0, reason: 'nothing is charged here');
      expect(counters[KioskCounters.orders], 1);
    });

    test('iZi could not take it', () async {
      comandas.orderFailure = StateError('sin red');
      await bloc.selectPayment(PaymentType.cashRegister, auth({}));
      expect(summaries().single['status'], 'error');
    });
  });

  test('a demo kiosk charges nothing and sums up nothing', () async {
    await bloc.generateQR(auth({'demo': true}));
    await bloc.makeCardPayment(auth({'ipAtc': '10.0.0.9', 'demo': true}), atc: true);
    await bloc.close();
    expect(summaries(), isEmpty);
  });

  group('a card charge on an Izify POS', () {
    late FakeIzifyPos pos;
    late AuthState izify;

    setUp(() async {
      pos = await FakeIzifyPos.start();
      await bloc.close();
      bloc = _Bloc(comandas, _Unused(), socket, izifyPosClient: IzifyPosClient())..seed(order());
      izify = auth({
        'ipEcopay': pos.hostPort,
        'pin': '4826',
        'ecopayConfig': {'mqttClientId': 'CAJA1', 'mqttUserName': 1, 'mqttPassword': 'x', 'commerceId': 2, 'cajaId': 1},
      });
    });

    tearDown(() => pos.close());

    test('approved and registered', () async {
      expect(await bloc.makeCardPayment(izify, izify: true), isTrue);
      await paid({'statusVenta': 'success', 'uuidFactura': 'factura-4'});

      final tx = summaries().single;
      final charge = pos.charges.single;
      expect(tx['method'], 'card');
      expect(tx['status'], 'approved');
      expect(tx['chargeId'], charge['correlationId']);
      expect(tx['reference'], charge['reference']);
      expect(tx['currency'], 'COP');
      expect(tx['amount'], 15000);
      expect(tx['verdictVia'], anyOf('ws', 'poll'));
      expect(tx['msToAck'], isA<int>());
      expect(tx['msToVerdict'], isA<int>());
      expect(tx['attempts'], 1);
      expect(tx['facturaId'], 'factura-4');
    });

    test('declined by the acquirer', () async {
      pos.outcome = 'ERROR';
      expect(await bloc.makeCardPayment(izify, izify: true), isFalse);
      final tx = summaries().single;
      expect(tx['status'], 'declined');
      expect(tx['verdictVia'], anyOf('ws', 'poll'));
    });

    test('left pending by the terminal: no verdict', () async {
      pos.outcome = 'PENDING';
      expect(await bloc.makeCardPayment(izify, izify: true), isFalse);
      expect(summaries().single['status'], 'timeout');
    });

    test('charged, and iZi does not know', () async {
      comandas.markFailure = const PaymentConflict('otro pago');
      expect(await bloc.makeCardPayment(izify, izify: true), isFalse);
      expect(summaries().single['status'], 'unregistered');
      expect(counters[KioskCounters.chargesUnregistered], 1, reason: 'by charge.register_failed only');
    });

    test('the terminal cannot charge: an error, nothing sent', () async {
      pos.ecopayInstalled = false;
      expect(await bloc.makeCardPayment(izify, izify: true), isFalse);
      final tx = summaries().single;
      expect(tx['status'], 'error');
      expect(tx['attempts'], 0);
      expect(pos.charges, isEmpty);
    });

    group('the page closing mid-charge', () {
      Future<List<String>> statuses() async {
        final prefs = await SharedPreferences.getInstance();
        return [
          for (final row in prefs.getStringList('cardErrors') ?? const <String>[])
            (jsonDecode(row) as Map)['estado'] as String
        ];
      }

      test('approved, while iZi is told: approved once iZi takes it', () async {
        comandas.markHeld = Completer();
        final flow = bloc.makeCardPayment(izify, izify: true);
        await comandas.marking.future;
        await bloc.close();
        expect(summaries().single['status'], 'timeout');

        comandas.markHeld!.complete();
        await flow.catchError((_) => false);
        final txs = summaries();
        expect([for (final tx in txs) tx['status']], ['timeout', 'approved']);
        expect(txs.last['chargeId'], pos.charges.single['correlationId']);
        expect(txs.last['verdictVia'], anyOf('ws', 'poll'));
        expect(await statuses(), ['SUCCESS']);
      });

      test('while the terminal decides: the decline it gives replaces the timeout', () async {
        pos.outcome = 'ERROR';
        pos.chargeDuration = const Duration(milliseconds: 600);
        final flow = bloc.makeCardPayment(izify, izify: true);
        while (pos.charges.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        await bloc.close();
        expect(summaries().single['status'], 'timeout');

        // The terminal wait outlives the page; its error screen cannot show.
        await flow.catchError((_) => false);
        final txs = summaries();
        expect([for (final tx in txs) tx['status']], ['timeout', 'declined']);
        expect(txs.last['reference'], pos.charges.single['reference']);
        expect(txs.last['msToVerdict'], isA<int>());
        expect(await statuses(), ['ERROR']);
      });
    });

    test('the stored charge remembers its order, for the recovery', () async {
      pos.outcome = 'ERROR';
      await bloc.makeCardPayment(izify, izify: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('cardErrors')!.single, contains('"comandaUuid":"venta-1"'));
    });
  });
}
