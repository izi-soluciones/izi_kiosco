import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/pos/card_charge_recovery.dart';

void main() {
  tearDown(CardChargeRecovery.active.clear);

  test('mode by screen', () {
    String mode(String? screen) => KioskActivity.modeOf(screen: screen);
    expect(mode(RoutesKeys.homeLink), KioskMode.idle);
    expect(mode(null), KioskMode.idle);
    expect(mode(RoutesKeys.makeOrderLink), KioskMode.ordering);
    expect(mode(RoutesKeys.makeOrderRetailLink), KioskMode.ordering);
    expect(mode(RoutesKeys.paymentLink), KioskMode.paying);
    expect(mode(RoutesKeys.posConfigLink), KioskMode.config);
    expect(mode(RoutesKeys.errorPaymentsLik), KioskMode.config);
    expect(mode(RoutesKeys.loginLink), KioskMode.login);
    expect(mode(RoutesKeys.kioskListLink), KioskMode.login);
  });

  test('a login error wins, then a charge on its way', () {
    expect(KioskActivity.modeOf(screen: RoutesKeys.paymentLink, authError: true), KioskMode.error);
    expect(KioskActivity.modeOf(screen: RoutesKeys.errorPaymentsLik, chargeInProgress: true),
        KioskMode.paying, reason: 'a retry from the transactions screen is a charge too');
  });

  test('a charge is in progress while the payment page waits, or a cut-off one is unsettled', () {
    final activity = KioskActivity()..screenChanged(RoutesKeys.paymentLink);
    expect(activity.chargeInProgress, isFalse);
    expect(activity.busy, isTrue, reason: 'paying');

    activity.paymentBusyChanged(true);
    expect(activity.chargeInProgress, isTrue);
    activity.paymentBusyChanged(false);
    expect(activity.chargeInProgress, isFalse);

    CardChargeRecovery.active.add('KOS-1');
    activity.screenChanged(RoutesKeys.homeLink);
    expect(activity.chargeInProgress, isTrue);
    expect(activity.mode, KioskMode.paying);
  });

  test('the screen is the route template; an empty one is no screen', () {
    final activity = KioskActivity()..screenChanged('  ');
    expect(activity.screen, isNull);
    activity.screenChanged('/payment/:id');
    expect(activity.screen, '/payment/:id');
  });
}
