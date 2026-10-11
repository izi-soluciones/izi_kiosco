import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iZi and an ATC / Linkser terminal that approve, or fail with [failWith].
class _Comandas implements ComandaRepository {
  Object? failWith;

  @override
  Future<Charge> generatePaymentAttempt(dynamic paymentAttemptDto) async =>
      const Charge(qrUrl: null, uuid: 'cobro-1', id: 1, qrBase64: null, token: 'tok-cobro');

  Future<CardPayment> _charge() async {
    if (failWith != null) throw failWith!;
    return CardPayment(response: 'Aprobado', cardNumber: '****1111', date: '2026-10-12', hour: '14:00');
  }

  @override
  Future<CardPayment> callCardPaymentATC(
          {required String amount,
          required String ip,
          required CancelToken cancelToken,
          required bool contactless}) =>
      _charge();

  @override
  Future<CardPayment> callCardPayment({required int amount, required String ip}) => _charge();

  @override
  Future<void> markPaymentATC(String chargeUuid, int? internalId,
      {Map<String, dynamic>? transaccion, String? token}) async {}

  @override
  Future<void> cancelPaymentAttempt({required String uuid}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Unused implements BusinessRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Socket implements SocketRepository {
  final StreamController<dynamic> payments = StreamController.broadcast();

  @override
  Stream<dynamic> listenPayment({required Charge charge}) => payments.stream;

  @override
  closeQrListening() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Records, on every state, whether the monitoring saw a charge on its way.
class _Bloc extends PaymentBloc {
  final List<(PaymentStatus, bool)> busy = [];

  _Bloc(super.comandas, super.negocios, super.socket);

  void seed(PaymentState state) => emit(state);

  @override
  void onChange(Change<PaymentState> change) {
    super.onChange(change);
    busy.add((change.nextState.status, KioskActivity.instance.chargeInProgress));
  }
}

AuthState _auth(Map<String, dynamic> config) => AuthState.init().copyWith(
    currentContribuyente: Contribuyente.fromJson({'habilitadoFacturacion': false}),
    currentDevice: Device.fromJson(
        {'id': 1, 'sucursal': 1, 'nombre': 'totem', 'caja': 1, 'config': {'isRetail': true, ...config}}));

void main() {
  late _Comandas comandas;
  late _Socket socket;
  late _Bloc bloc;
  late KioskCounters counters;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    counters = KioskCounters();
    KioskCounters.install(counters);
    KioskActivity.install(KioskActivity());
    Telemetry.install(Telemetry(observers: [counters.observe]));
    comandas = _Comandas();
    socket = _Socket();
    bloc = _Bloc(comandas, _Unused(), socket)
      ..seed(PaymentState.init().copyWith(
          step: 1,
          paymentObj: PaymentObj(
              id: 1, custom: {}, amount: 10, isComanda: false, uuid: 'venta-1', items: [])));
  });

  tearDown(() async {
    await bloc.close();
    await socket.payments.close();
  });

  List<TelemetryEvent> events(String type) =>
      Telemetry.recent().reversed.where((e) => e.type == type).toList();

  test('an ATC charge is logged and counted; the kiosk is busy while it runs', () async {
    expect(await bloc.makeCardPayment(_auth({'ipAtc': '10.0.0.9'}), atc: true), isTrue);

    expect(events('charge.start').single.data['provider'], 'atc');
    final result = events('charge.result').single.data;
    expect(result['provider'], 'atc');
    expect(result['status'], 'success');
    expect(counters[KioskCounters.chargesStarted], 1);
    expect(counters[KioskCounters.chargesApproved], 1);

    expect(bloc.busy, contains((PaymentStatus.cardProcessing, true)));
    expect(bloc.busy, contains((PaymentStatus.processingOrder, true)));
    expect(KioskActivity.instance.chargeInProgress, isTrue,
        reason: 'charged: the order is still being registered');

    socket.payments.add({'statusVenta': 'success'});
    await Future<void>.delayed(Duration.zero);
    expect(KioskActivity.instance.chargeInProgress, isFalse, reason: 'the sale is done');
  });

  test('a Linkser failure is counted as an error, without its text', () async {
    comandas.failWith = 'Rechazada tarjeta 4111 1111 1111 1111';
    expect(await bloc.makeCardPayment(_auth({'ipLinkser': '10.0.0.8'}), linkser: true), isFalse);

    final result = events('charge.result').single.data;
    expect(result['provider'], 'linkser');
    expect(result['status'], 'failed');
    expect(counters[KioskCounters.chargesStarted], 1);
    expect(counters[KioskCounters.chargesError], 1);
    final logged = jsonEncode([for (final e in Telemetry.recent()) e.toJson()]);
    expect(logged, isNot(contains('4111')));
    expect(KioskActivity.instance.chargeInProgress, isFalse);
  });

  test('each order completed is counted once', () async {
    expect(await bloc.makeCardPayment(_auth({'ipAtc': '10.0.0.9'}), atc: true), isTrue);
    socket.payments.add({'statusVenta': 'success'});
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.step, 5);
    expect(bloc.state.status, PaymentStatus.paymentProcessed);
    expect(counters[KioskCounters.orders], 1);

    socket.payments.add({'statusVenta': 'success'});
    await Future<void>.delayed(Duration.zero);
    expect(counters[KioskCounters.orders], 1, reason: 'the same success screen');
  });

  test('closing the page mid-charge leaves no charge in progress behind', () async {
    bloc.seed(bloc.state.copyWith(status: PaymentStatus.cardProcessing));
    expect(KioskActivity.instance.chargeInProgress, isTrue);
    await bloc.close();
    expect(KioskActivity.instance.chargeInProgress, isFalse);
  });
}
