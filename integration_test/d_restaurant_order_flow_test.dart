// E2E (d): full restaurant order flow up to the payment-methods screen.
//
// CREATES A REAL ORDER in the staging backend (guarded: refuses to run unless
// FLAVOR=stg). Requires a RESTAURANT kiosk token and a curated option-free
// catalog item.
//
//   fvm flutter test integration_test/d_restaurant_order_flow_test.dart \
//     -d <device> --dart-define=FLAVOR=stg --dart-define=E2E_TOKEN=<jwt> \
//     --dart-define=E2E_ITEM_NAME="<catalog item name>"
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_helpers.dart';
import 'helpers/e2e_strings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('order an item and reach the payment methods screen',
      (tester) async {
    assertStagingFlavor();

    await placeRestaurantOrder(tester);

    // On the payment-methods screen at least one method is offered.
    expect(findAppText(S.paymentMethods), findsOneWidget);
    expect(findAppTextAny([S.qrButton, S.checkoutButton]), findsWidgets);
  });
}
