// E2E (e): pay for an order through the DEMO payment flow.
//
// The staging device MUST be provisioned with demo=true — the app then swaps
// the real payment gateway for the demo endpoints (no money moves). Creates a
// real (demo-paid) order in staging; guarded to FLAVOR=stg.
//
//   fvm flutter test integration_test/e_payment_demo_test.dart \
//     -d <device> --dart-define=FLAVOR=stg --dart-define=E2E_TOKEN=<jwt> \
//     --dart-define=E2E_ITEM_NAME="<catalog item name>"
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_helpers.dart';
import 'helpers/e2e_strings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo QR payment completes successfully', (tester) async {
    assertStagingFlavor();

    await placeRestaurantOrder(tester);

    // Choose QR. With facturación enabled the invoice-data form appears again
    // after picking the method (all fields optional) — proceed through it. On
    // a demo device the bloc then shows the demo page instead of a real QR.
    await tapPaymentMethod(tester, S.qrButton);
    await pumpUntilAny(tester, [
      findAppText(S.invoiceData),
      find.byKey(const Key('demo_proceed_btn')),
    ], timeout: const Duration(seconds: 45));
    if (findAppText(S.invoiceData).evaluate().isNotEmpty) {
      await proceedThroughInvoice(tester);
    }
    await tapKey(tester, const Key('demo_proceed_btn'),
        timeout: const Duration(seconds: 60));

    // Success arrives asynchronously (socket/polling): accept either the
    // payment-success or order-created outcome.
    await pumpUntilFound(
        tester, findAppTextAny([S.successPayment, S.successOrder]),
        timeout: const Duration(seconds: 90));

    // Post-payment reset: either tap "Realizar otra compra", or let the
    // success screen's own idle timer return to home — both end at home.
    if (findAppText(S.makeAnotherPurchase).evaluate().isNotEmpty) {
      await tapBtn(tester, S.makeAnotherPurchase);
    }
    await pumpUntilFound(tester, find.byKey(const Key('home_start_area')),
        timeout: const Duration(seconds: 45));
  });
}
