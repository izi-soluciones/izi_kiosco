import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_activity.dart';

void main() {
  test('dos dueños: el que cierra no apaga el charging del otro', () {
    final activity = BmActivity();
    final a = Object();
    final b = Object();
    activity.paymentChanged(a, true);
    activity.paymentChanged(b, true);
    activity.paymentClosed(a);
    expect(activity.charging, isTrue);
    expect(activity.mode, 'paying');
    activity.paymentClosed(b);
    expect(activity.charging, isFalse);
    expect(activity.mode, 'idle');
  });

  test('paymentClosed después de un paymentChanged(true) tardío deja charging false', () {
    final activity = BmActivity();
    final a = Object();
    activity.paymentChanged(a, true);
    activity.paymentClosed(a);
    activity.paymentChanged(a, true);
    expect(activity.charging, isFalse);
  });

  test('mode ordering en la pantalla de pedido', () {
    final activity = BmActivity();
    expect(activity.mode, 'idle');
    activity.screenChanged('makeOrder');
    expect(activity.mode, 'ordering');
    activity.screenChanged('makeOrderRetail');
    expect(activity.mode, 'ordering');
    activity.screenChanged('home');
    expect(activity.mode, 'idle');
    activity.screenChanged(null);
    expect(activity.mode, 'idle');
  });

  test('paying gana sobre ordering', () {
    final activity = BmActivity();
    final a = Object();
    activity.screenChanged('makeOrder');
    activity.paymentChanged(a, true);
    expect(activity.mode, 'paying');
  });
}
