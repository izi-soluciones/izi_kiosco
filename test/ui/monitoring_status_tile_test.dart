import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:izi_kiosco/ui/pages/pos_config_page/widgets/monitoring_status_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/monitoring/monitoring_service_test.dart' show FakeMonitoringRepository, FakeTimers;

const _context = MonitoringContext(contribuyenteId: 5, dispositivoId: 7, deviceName: 'KIOSKO-01');

void main() {
  late FakeMonitoringRepository repository;
  late FakeTimers timers;
  late MonitoringService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Telemetry.install(Telemetry());
    repository = FakeMonitoringRepository();
    timers = FakeTimers();
    service = MonitoringService(
        repository: repository,
        store: MonitoringStore(),
        appInfo: () async => const MonitoringApp(version: '1', flavor: 'local', platform: 'web'),
        timer: timers.call);
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MonitoringStatusTile(service: service))));

  testWidgets('shows the state and retries the enrollment on demand', (tester) async {
    await pump(tester);
    // Not logged in: nothing to retry.
    expect(find.textContaining(LocaleKeys.posConfig_monitoring_stopped), findsOneWidget);
    final retry = find.ancestor(
        of: find.text(LocaleKeys.posConfig_monitoring_retry),
        matching: find.byWidgetPredicate((w) => w is TextButton));
    expect(tester.widget<TextButton>(retry).onPressed, isNull);

    await tester.runAsync(() async {
      repository.failWith(const MonitoringException('http_502'));
      await service.start(_context);
    });
    await tester.pump();
    expect(find.textContaining(LocaleKeys.posConfig_monitoring_pending), findsOneWidget);

    await tester.runAsync(() => timers.fire());
    await tester.pump();
    expect(find.textContaining(LocaleKeys.posConfig_monitoring_error), findsOneWidget);
    expect(find.textContaining(LocaleKeys.posConfig_monitoring_nextAttempt), findsOneWidget);

    repository.succeed();
    await tester.runAsync(() async {
      await tester.tap(retry);
      await pumpEventQueue();
    });
    await tester.pump();
    expect(repository.calls, hasLength(2));
    expect(find.textContaining(LocaleKeys.posConfig_monitoring_enrolled), findsOneWidget);
    expect(find.textContaining(LocaleKeys.posConfig_monitoring_device), findsOneWidget);
    expect(timers.active, isEmpty);
    // Lets the telemetry buffer's delayed save run.
    await tester.pump(const Duration(seconds: 3));
  });

  test('describes each state on one line', () {
    expect(
        MonitoringStatusTile.describe(const MonitoringStatus(
            state: MonitoringState.enrolled, deviceId: '65f0c0ffee')),
        '${LocaleKeys.posConfig_monitoring_title}: ${LocaleKeys.posConfig_monitoring_enrolled}'
        ' · ${LocaleKeys.posConfig_monitoring_device}');
    expect(
        MonitoringStatusTile.describe(
            const MonitoringStatus(state: MonitoringState.error, enrolling: true)),
        contains(LocaleKeys.posConfig_monitoring_enrolling));
  });
}
