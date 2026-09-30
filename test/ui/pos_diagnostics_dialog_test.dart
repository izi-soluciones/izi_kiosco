import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/ui/pages/pos_config_page/widgets/pos_diagnostics_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Telemetry.install(Telemetry());
  });

  testWidgets('shows what the kiosk recorded, and why the terminal cannot be asked',
      (tester) async {
    Telemetry.event('pos.health_failed',
        level: TelemetryLevel.warning, data: {'cause': 'timeout', 'rid': 'abc123'});
    Telemetry.event('charge.start', chargeId: 'CHG-1', reference: 'KOS-1');

    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PosDiagnosticsDialog(device: null))));
    await tester.pumpAndSettle();

    expect(find.textContaining('pos.health_failed'), findsOneWidget);
    expect(find.textContaining('rid=abc123'), findsOneWidget);
    expect(find.textContaining('CHG-1 KOS-1'), findsOneWidget);

    // No terminal paired: the terminal tab says so instead of failing.
    await tester.tap(find.text(LocaleKeys.posConfig_diagnostics_terminalTab));
    await tester.pumpAndSettle();
    expect(find.text(LocaleKeys.posConfig_diagnostics_notPaired), findsOneWidget);
    // Lets the buffer's delayed save run.
    await tester.pump(const Duration(seconds: 3));
  });
}
