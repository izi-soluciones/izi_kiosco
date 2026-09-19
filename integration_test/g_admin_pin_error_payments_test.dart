// E2E (g): hidden admin entry — long-press the top-left corner, enter the
// PIN, land on the card-errors admin page. Also verifies the wrong-PIN error.
//
//   fvm flutter test integration_test/g_admin_pin_error_payments_test.dart \
//     -d <device> --dart-define=FLAVOR=stg --dart-define=E2E_TOKEN=<jwt> \
//     [--dart-define=E2E_PIN=<device pin, default 4321>]
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:izi_kiosco/ui/general/widgets/password_modal.dart';

import 'helpers/e2e_helpers.dart';
import 'helpers/e2e_strings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> typePin(WidgetTester tester, String pin) async {
    final modal = find.byType(PasswordModal);
    for (final digit in pin.split('')) {
      await tapBtn(tester, digit, within: modal);
    }
    await tapBtn(tester, S.pinConfirm, within: modal);
  }

  testWidgets('admin long-press + PIN opens the error payments page',
      (tester) async {
    await bootToHome(tester);

    await tester.longPress(find.byKey(const Key('home_admin_corner')),
        warnIfMissed: false);
    await pumpUntilFound(tester, find.byType(PasswordModal),
        timeout: const Duration(seconds: 15));

    // Wrong PIN first: modal stays and the warning snackbar appears.
    await typePin(tester, '0000');
    await pumpUntilFound(tester, findAppTextContaining(S.wrongPin),
        timeout: const Duration(seconds: 15));
    expect(find.byType(PasswordModal), findsOneWidget);

    // Let the warning snackbar clear — it overlaps the Confirmar button at the
    // bottom, so a second confirm tap would otherwise land on the snackbar.
    await pumpUntilGone(tester, findAppTextContaining(S.wrongPin),
        timeout: const Duration(seconds: 15));

    // Correct PIN: modal closes and the admin page renders its table headers.
    await typePin(tester, e2ePin);
    await pumpUntilFound(tester, findAppText(S.errorColStatus),
        timeout: const Duration(seconds: 30));
    expect(findAppText(S.errorColAction), findsOneWidget);
  });
}
