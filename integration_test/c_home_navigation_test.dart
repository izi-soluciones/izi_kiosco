// E2E (c): tapping the home body opens the order flow for this device type.
//
// Works with either a restaurant or a retail-barcode kiosk token; the
// assertion branches on which order page renders.
//
//   fvm flutter test integration_test/c_home_navigation_test.dart \
//     -d <device> --dart-define=FLAVOR=stg --dart-define=E2E_TOKEN=<jwt>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_helpers.dart';
import 'helpers/e2e_strings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home tap navigates to the order screen', (tester) async {
    await bootToHome(tester);
    await tapKey(tester, const Key('home_start_area'));

    // Restaurant devices show the eat-here/take-away chooser; retail-barcode
    // devices show the scan-waiting screen.
    final orderScreen = find.byWidgetPredicate((w) {
      if (w is! Text) return false;
      final data = stripZwsp(w.data ?? '');
      return data.contains(S.selectWhere) ||
          data.contains(S.retailWaitingScan);
    });
    await pumpUntilFound(tester, orderScreen,
        timeout: const Duration(seconds: 45));
  });
}
