// La pregunta del voucher y la pantalla de bloqueado tienen que volver solas a inicio
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/atc_payment_error.dart';
import 'package:izi_kiosco/domain/models/atc_payment_status.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/modulos.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/repositories/auth_repository.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:izi_kiosco/ui/pages/payment_page/payment_page.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_invoice.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_selection.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_card_atc_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeComandaRepository implements ComandaRepository {
  @override
  Future<Charge> generatePaymentAttempt(dynamic dto) async => const Charge(
      qrUrl: null,
      uuid: 'venta-1',
      id: 77,
      intentoPago: 77,
      qrBase64: null,
      token: null);

  @override
  Future<CardPayment> callCardPaymentATC(
          {required String amount,
          required String ip,
          required CancelToken cancelToken,
          required bool contactless,
          String? ref}) async =>
      throw const AtcPaymentError(AtcPaymentErrorType.uncertain, 'timeout');

  @override
  Future<AtcPaymentStatus> getPaymentStatusATC(String ref) async =>
      AtcPaymentStatus(
          ref: ref,
          estado: AtcPaymentStatus.inProgress,
          resultado: null,
          confirmado: false);

  @override
  Future<void> confirmPaymentATC(String ref) async {}

  @override
  Future<void> cancelPaymentAttempt({required String uuid}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBusinessRepository extends Fake implements BusinessRepository {}

class _FakeAuthRepository extends Fake implements AuthRepository {}

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
  _TestPaymentBloc(super.comandas, super.negocios, super.socket)
      : super(
            atcPollInterval: const Duration(milliseconds: 5),
            atcVerifyTimeout: const Duration(milliseconds: 40));

  void seed(PaymentState state) => emit(state);
}

class _TestAuthBloc extends AuthBloc {
  _TestAuthBloc() : super(_FakeAuthRepository(), _FakeBusinessRepository());

  void seed(AuthState state) => emit(state);
}

AuthState _authState({required bool facturacion}) => AuthState.init().copyWith(
    currentContribuyente:
        Contribuyente.fromJson({"modulos": {"facturacion": {"enabled": facturacion}}}),
    currentDevice: Device.fromJson({
      "id": 1,
      "sucursal": 1,
      "nombre": "totem",
      "caja": 1,
      "config": {"isRetail": true, "ipAtc": "192.168.0.101"}
    }));

class _Harness {
  final AuthState authState;
  final _TestAuthBloc auth = _TestAuthBloc();
  final PageUtilsBloc pageUtils = PageUtilsBloc(_FakeBusinessRepository());
  final _TestPaymentBloc bloc = _TestPaymentBloc(_FakeComandaRepository(),
      _FakeBusinessRepository(), _FakeSocketRepository());

  _Harness(this.authState) {
    auth.seed(authState);
  }

  Future<void> pump(WidgetTester tester, {required bool isComanda}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: auth),
        BlocProvider<PageUtilsBloc>.value(value: pageUtils),
        BlocProvider<PaymentBloc>.value(value: bloc),
      ],
      child: MaterialApp(home: Scaffold(body: PaymentPage())),
    ));
    await tester.pump();
    bloc.seed(bloc.state.copyWith(
        step: authState.currentContribuyente?.tieneModulo(Modulo.facturacion) == true ? 2 : 1,
        status: PaymentStatus.successGet,
        phoneNumber: bloc.state.phoneNumber.copyWith(value: '71234567'),
        paymentObj: PaymentObj(
            id: 5,
            custom: {},
            amount: 30,
            isComanda: isComanda,
            uuid: isComanda ? 'comanda-5' : 'venta-1',
            items: [])));
    await tester.pump();
    await tester.pump();
  }

  // Lo que pasa después de la pantalla: el temporizador vence y el kiosko queda inactivo
  Future<void> expectReturnsHomeAlone(WidgetTester tester) async {
    expect(pageUtils.timer, isNotNull,
        reason: 'sin temporizador de inactividad el kiosko no vuelve solo a inicio');
    // 90 s de timePayment; otra emisión del bloc en la misma pantalla (qrWait a los 15 s) lo reinicia una vez
    for (var i = 0; i < 150 && pageUtils.state.screenActive; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(pageUtils.state.screenActive, isFalse);
  }

  Future<void> dispose(WidgetTester tester) async {
    bloc.timerManual?.cancel();
    bloc.timerQR?.cancel();
    await tester.pump(const Duration(seconds: 91));
    await tester.pumpWidget(const SizedBox());
    await bloc.close();
    await pageUtils.close();
    await auth.close();
  }
}

// Sin fondos ni assets reales: overflow y assets que no cargan no son lo que se mide
void _ignoreLayoutNoise() {
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (!text.contains('overflowed') && !text.contains('Unable to load asset')) {
      onError?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = onError);
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 400 && !done(); i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 2)));
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  for (final facturacion in [false, true]) {
    testWidgets(
        'retail (facturación $facturacion): la pregunta del voucher y el bloqueado vuelven solos a inicio',
        (tester) async {
      _ignoreLayoutNoise();
      final harness = _Harness(_authState(facturacion: facturacion));
      await harness.pump(tester, isComanda: false);

      // Lo mismo que hacen _paymentCardATC de la selección y de la factura antes de cobrar
      final pageContext = facturacion
          ? tester.element(find.byType(PaymentPageInvoice))
          : tester.element(find.byType(PaymentPageSelection));
      pageContext.read<PageUtilsBloc>().closeScreenActive();
      var done = false;
      harness.bloc
          .makeCardPayment(harness.authState, atc: true, contactless: true)
          .whenComplete(() => done = true);
      await _pumpUntil(tester, () => done);
      await tester.pump();

      expect(harness.bloc.state.status, PaymentStatus.cardUncertain);
      expect(find.byType(PaymentCardAtcStatus), findsOneWidget);
      expect(harness.pageUtils.timer, isNotNull);

      harness.pageUtils.closeScreenActive();
      harness.bloc.answerAtcVoucher(harness.authState, true);
      await tester.pump();

      expect(harness.bloc.state.status, PaymentStatus.cardBlocked);
      await harness.expectReturnsHomeAlone(tester);
      await harness.dispose(tester);
    });

    testWidgets(
        'comanda (facturación $facturacion): la pregunta del voucher y el bloqueado vuelven solos a inicio',
        (tester) async {
      _ignoreLayoutNoise();
      final harness = _Harness(_authState(facturacion: facturacion));
      await harness.pump(tester, isComanda: true);
      harness.pageUtils.closeScreenActive();

      harness.bloc.seed(harness.bloc.state
          .copyWith(step: 4, status: PaymentStatus.cardVerifying));
      await tester.pump();
      harness.bloc.seed(harness.bloc.state
          .copyWith(status: PaymentStatus.cardUncertain, atcCode: 'abc123'));
      await tester.pump();

      expect(find.byType(PaymentCardAtcStatus), findsOneWidget);
      expect(harness.pageUtils.timer, isNotNull);

      harness.pageUtils.closeScreenActive();
      harness.bloc.seed(harness.bloc.state
          .copyWith(status: PaymentStatus.cardBlocked, atcBlocked: true));
      await tester.pump();

      await harness.expectReturnsHomeAlone(tester);
      await harness.dispose(tester);
    });
  }
}
