// E2E (h): the kiosk inactivity overlay appears after ~30s without touches.
//
// SLOW: the inactivity timers are real wall-clock Timers (integration tests
// cannot fast-forward them), so this test idles for 30+ seconds. It is
// skipped unless you opt in:
//
//   fvm flutter test integration_test/h_inactivity_timer_test.dart \
//     -d <device> --dart-define=FLAVOR=stg --dart-define=E2E_TOKEN=<jwt> \
//     --dart-define=E2E_SLOW=true
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_helpers.dart';
import 'helpers/e2e_strings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'inactivity on the order screen shows the need-more-time overlay',
    (tester) async {
      await bootToHome(tester);

      // The inactivity timer starts when leaving home for the order flow.
      await tapKey(tester, const Key('home_start_area'));
      await pumpFor(tester, const Duration(seconds: 3));

      // Idle past the 30s timer; the overlay shows its countdown title.
      await pumpUntilFound(
        tester,
        findAppTextContaining(S.inactivityTitle),
        timeout: const Duration(seconds: 45),
      );

      // Touching the screen dismisses the overlay.
      await tester.tap(findAppTextContaining(S.inactivityTitle).first,
          warnIfMissed: false);
      await pumpUntilGone(tester, findAppTextContaining(S.inactivityTitle),
          timeout: const Duration(seconds: 15));
    },
    skip: !e2eSlow,
  );
}
