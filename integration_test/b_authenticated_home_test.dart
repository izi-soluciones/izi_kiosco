// E2E (b): a pre-seeded kiosk JWT bypasses the QR login and lands on home.
//
//   fvm flutter test integration_test/b_authenticated_home_test.dart \
//     -d <device> --dart-define=FLAVOR=stg --dart-define=E2E_TOKEN=<jwt>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boot with seeded token lands on the home screen',
      (tester) async {
    await bootToHome(tester);

    // The tappable start area is the canonical home marker (the promo text is
    // replaced by a spinner on devices configured with an attract video).
    expect(find.byKey(const Key('home_start_area')), findsWidgets);

    // And the admin hotspot exists for test (g).
    expect(find.byKey(const Key('home_admin_corner')), findsOneWidget);
  });
}
