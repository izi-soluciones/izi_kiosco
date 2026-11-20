import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_activity.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_payment_busy.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/charge.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';

class _FakeComandaRepository implements ComandaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBusinessRepository implements BusinessRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSocketRepository implements SocketRepository {
  @override
  Stream<dynamic> listenPayment({required Charge charge}) => const Stream.empty();

  @override
  closeQrListening() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _ThrowingActivity extends BmActivity {
  @override
  void paymentChanged(Object owner, bool charging) => throw StateError('boom');

  @override
  void paymentClosed(Object owner) => throw StateError('boom close');
}

class _TestPaymentBloc extends PaymentBloc {
  _TestPaymentBloc() : super(_FakeComandaRepository(), _FakeBusinessRepository(), _FakeSocketRepository());

  void seed(PaymentState state) => emit(state);
}

void main() {
  group('bmIsCharging', () {
    const resting = [
      PaymentStatus.successInvoice,
      PaymentStatus.waitingGet,
      PaymentStatus.errorActivity,
      PaymentStatus.errorCashRegisters,
      PaymentStatus.errorGet,
    ];
    for (final status in resting) {
      test('es false en $status', () {
        expect(bmIsCharging(PaymentState.init().copyWith(status: status)), isFalse);
      });
    }

    for (final status in [PaymentStatus.cardVerifying, PaymentStatus.cardUncertain, PaymentStatus.cardBlocked, PaymentStatus.cardPosBusy, PaymentStatus.brebLoading]) {
      test('bmIsCharging true en $status', () {
        expect(bmIsCharging(PaymentState.init().copyWith(status: status)), isTrue);
      });
    }

    test('bmIsCharging true en el paso 7 de Bre-B', () {
      expect(bmIsCharging(PaymentState.init().copyWith(status: PaymentStatus.successGet, step: 7)), isTrue);
    });

    test('es true en paymentProcessed del paso 5', () {
      expect(bmIsCharging(PaymentState.init().copyWith(status: PaymentStatus.paymentProcessed, step: 5)), isTrue);
    });
  });

  group('PaymentBloc y BmActivity', () {
    test('si BmActivity lanza dentro de onChange, el PaymentBloc emite igual', () async {
      final bloc = _TestPaymentBloc();
      bloc.bmActivity = _ThrowingActivity();

      expect(() => bloc.seed(PaymentState.init().copyWith(status: PaymentStatus.cardVerifying)), returnsNormally);

      expect(bloc.state.status, PaymentStatus.cardVerifying);
      await bloc.close();
    });

    test('si BmActivity lanza dentro de close, el PaymentBloc se cierra igual', () async {
      final bloc = _TestPaymentBloc();
      bloc.bmActivity = _ThrowingActivity();

      await bloc.close();

      expect(bloc.isClosed, isTrue);
    });

    test('onChange avisa a BmActivity y close la libera', () async {
      final activity = BmActivity();
      final bloc = _TestPaymentBloc();
      bloc.bmActivity = activity;

      bloc.seed(PaymentState.init().copyWith(status: PaymentStatus.cardVerifying));
      expect(activity.charging, isTrue);

      await bloc.close();
      expect(activity.charging, isFalse);
    });
  });
}
