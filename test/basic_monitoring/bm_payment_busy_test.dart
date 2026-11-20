import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_activity.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_payment_busy.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';

class _FakeComanda implements ComandaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBusiness implements BusinessRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSocket implements SocketRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ThrowingActivity extends BmActivity {
  int calls = 0;

  @override
  void paymentChanged(Object owner, bool charging) {
    calls++;
    throw StateError('boom');
  }

  @override
  void paymentClosed(Object owner) {
    calls++;
    throw StateError('boom');
  }
}

PaymentBloc _bloc() => PaymentBloc(_FakeComanda(), _FakeBusiness(), _FakeSocket());

void main() {
  tearDown(() {
    PaymentBloc.bmActivity = () => BmActivity.instance;
  });

  test('bmIsCharging es false en successInvoice y true en step 5 con paymentProcessed', () {
    final init = PaymentState.init();
    expect(bmIsCharging(init.copyWith(status: PaymentStatus.successInvoice)), isFalse);
    expect(bmIsCharging(init.copyWith(status: PaymentStatus.waitingGet)), isFalse);
    expect(bmIsCharging(init.copyWith(status: PaymentStatus.errorGet)), isFalse);
    expect(bmIsCharging(init.copyWith(step: 5, status: PaymentStatus.paymentProcessed)), isTrue);
  });

  test('si BmActivity lanza dentro de onChange, el PaymentBloc emite igual el nuevo estado', () {
    final activity = _ThrowingActivity();
    PaymentBloc.bmActivity = () => activity;
    final bloc = _bloc();
    final emitted = <PaymentStatus>[];
    final sub = bloc.stream.listen((s) => emitted.add(s.status));
    bloc.emit(bloc.state.copyWith(status: PaymentStatus.paymentProcessed));
    expect(bloc.state.status, PaymentStatus.paymentProcessed);
    expect(activity.calls, 1);
    return Future<void>.delayed(Duration.zero).then((_) {
      expect(emitted, [PaymentStatus.paymentProcessed]);
      sub.cancel();
    });
  });

  test('si BmActivity lanza dentro de close, el PaymentBloc se cierra igual', () async {
    final activity = _ThrowingActivity();
    PaymentBloc.bmActivity = () => activity;
    final bloc = _bloc();
    await bloc.close();
    expect(bloc.isClosed, isTrue);
    expect(activity.calls, 1);
  });

  test('onChange informa a BmActivity y close libera al dueño', () async {
    final activity = BmActivity();
    PaymentBloc.bmActivity = () => activity;
    final bloc = _bloc();
    bloc.emit(bloc.state.copyWith(status: PaymentStatus.paymentProcessed));
    expect(activity.charging, isTrue);
    await bloc.close();
    expect(activity.charging, isFalse);
  });
}
