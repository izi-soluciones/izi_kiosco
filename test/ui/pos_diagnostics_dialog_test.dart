import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_collector.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_heartbeat.dart';
import 'package:izi_kiosco/data/monitoring/pos_link_health.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
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

  testWidgets('the Kiosco tab shows the health the heartbeat reports', (tester) async {
    final link = PosLinkHealth(counters: () => KioskCounters());
    link.failed(address: '192.168.1.50:8081', cause: 'refused');
    final collector = KioskHealthCollector(
      link: () => link,
      session: (_) async => const IzifyPosSession(IzifyPosAddress('192.168.1.50'), 'tok'),
      posName: () async => 'izify-POS-1234',
      pendingCardErrors: () async => 3,
    );

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: PosDiagnosticsDialog(device: null, collector: collector))));
    await tester.pumpAndSettle();

    expect(find.text(LocaleKeys.posConfig_diagnostics_heartbeatStopped), findsOneWidget);
    final health = find.ancestor(
        of: find.textContaining('"provider": "izify"'), matching: find.byType(SelectableText));
    expect(health, findsOneWidget);
    final text = tester.widget<SelectableText>(health).data!;
    expect(text, contains('"status": "degraded"'));
    expect(text, contains('"lastCause": "refused"'));
    expect(text, contains('"pendingCardErrors": 3'));
    expect(text, isNot(contains('tok')));
    await tester.pump(const Duration(seconds: 3));
  });

  test('the heartbeat line', () {
    expect(describeHeartbeat(HeartbeatStatus.stopped),
        LocaleKeys.posConfig_diagnostics_heartbeatStopped);
    expect(describeHeartbeat(const HeartbeatStatus(running: true)),
        LocaleKeys.posConfig_diagnostics_heartbeatPending);
    expect(describeHeartbeat(const HeartbeatStatus(running: true, failures: 2, lastCause: 'timeout')),
        LocaleKeys.posConfig_diagnostics_heartbeatFailing);
    expect(describeHeartbeat(HeartbeatStatus(running: true, lastOkAt: DateTime(2026))),
        LocaleKeys.posConfig_diagnostics_heartbeatOk);
  });
}
