// E2E (f): retail flow — simulated barcode scans build the cart.
//
// Requires a RETAIL kiosk token (isRetail=true, isRetailBarcode=true) and a
// curated staging barcode. The scanner is simulated with raw key events (the
// scan views listen on a KeyboardListener; a USB scanner types + Enter).
//
// By default this test only exercises scanning (no backend writes). Pass
// --dart-define=E2E_RETAIL_FULL=true to also finish the purchase through the
// demo payment (device must have demo=true).
//
//   fvm flutter test integration_test/f_retail_scan_test.dart \
//     -d <device> --dart-define=FLAVOR=stg --dart-define=E2E_TOKEN=<jwt> \
//     --dart-define=E2E_BARCODE=<barcode> \
//     --dart-define=E2E_BARCODE_NAME="<product name>"
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_helpers.dart';
import 'helpers/e2e_strings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scanning barcodes adds products to the retail cart',
      (tester) async {
    if (e2eRetailFull) assertStagingFlavor();

    await bootToHome(tester);
    await tapKey(tester, const Key('home_start_area'));

    // Waiting-for-scan screen; keys are ignored while the catalog loads, so
    // wait for the prompt before "scanning".
    await pumpUntilFound(tester, findAppTextContaining(S.retailWaitingScan),
        timeout: const Duration(seconds: 60));
    await pumpFor(tester, const Duration(seconds: 2));

    // First scan → scan view with the product listed.
    await enterBarcode(tester, e2eBarcode);
    await pumpUntilFound(tester, findAppText(S.productsScanned),
        timeout: const Duration(seconds: 30));
    if (e2eBarcodeName.isNotEmpty) {
      await pumpUntilFound(tester, findAppTextContaining(e2eBarcodeName),
          timeout: const Duration(seconds: 15));
    }

    // Second scan of the same product must not add a second row.
    await enterBarcode(tester, e2eBarcode);
    await pumpFor(tester, const Duration(seconds: 2));
    if (e2eBarcodeName.isNotEmpty) {
      expect(findAppTextContaining(e2eBarcodeName), findsOneWidget);
    }

    // Reset guard-rail: "Empezar de nuevo" asks for confirmation; cancel it.
    await tapBtn(tester, S.retailInitAgain);
    await pumpUntilFound(tester, findAppTextContaining(S.retailInitAgainWarning),
        timeout: const Duration(seconds: 15));
    await tapBtn(tester, 'Cancelar');
    await pumpUntilFound(tester, findAppText(S.productsScanned),
        timeout: const Duration(seconds: 15));

    if (e2eRetailFull) {
      // Full purchase through demo payment (writes to staging).
      await tapKey(tester, const Key('retail_finish_btn'));
      await proceedToPaymentMethods(tester);
      await tapPaymentMethod(tester, S.qrButton);
      await tapKey(tester, const Key('demo_proceed_btn'));
      await pumpUntilFound(
          tester, findAppTextAny([S.successPayment, S.successOrder]),
          timeout: const Duration(seconds: 90));
    }
  });
}
