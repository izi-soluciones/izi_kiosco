// E2E (a): unauthenticated boot lands on the QR login screen.
//
// Needs NO credentials — safe first test to validate the harness:
//   fvm flutter test integration_test/a_unauthenticated_login_test.dart \
//     -d <device> --dart-define=FLAVOR=stg
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'helpers/e2e_helpers.dart';
import 'helpers/e2e_strings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boot without token shows the QR login screen', (tester) async {
    await bootApp(tester, authenticated: false);

    // LoginBloc creates a kiosk session against the backend and renders its
    // QR (or the "generating" placeholder first). Wait for the title, which
    // renders in both states.
    await pumpUntilFound(tester, findAppText(S.loginQrTitle),
        timeout: const Duration(seconds: 60));

    // The QR itself appears once the staging session id arrives.
    await pumpUntilFound(tester, find.byType(QrImageView),
        timeout: const Duration(seconds: 60));

    // The redirect guard kept us on /login — home must not be visible.
    expect(findAppText(S.homeClickToInit), findsNothing);
  });
}
