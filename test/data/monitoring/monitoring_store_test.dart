import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('creates a v4 installation id once and keeps it in prefs', () async {
    final id = await MonitoringStore().installationId();
    expect(MonitoringStore.isUuidV4(id), isTrue, reason: id);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('monitoring.installationId'), id);
    // A new launch reads the same one.
    expect(await MonitoringStore().installationId(), id);
  });

  test('replaces a stored installation id that is not a UUID', () async {
    SharedPreferences.setMockInitialValues({'monitoring.installationId': 'garbage'});
    final id = await MonitoringStore().installationId();
    expect(MonitoringStore.isUuidV4(id), isTrue);
  });

  test('UUIDs are random and well formed', () {
    final ids = {for (var i = 0; i < 200; i++) MonitoringStore.newUuidV4()};
    expect(ids, hasLength(200));
    expect(ids.every(MonitoringStore.isUuidV4), isTrue);
  });

  test('keeps the enrollment, and forgets it without losing the installation', () async {
    final store = MonitoringStore();
    final id = await store.installationId();
    expect(await store.enrollment(), isNull);

    await store.saveEnrollment(const MonitoringEnrollmentRecord(
        deviceToken: 'izd_x', deviceId: 'd1', applianceId: 'a1', contribuyenteId: 5, dispositivoId: 7));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('monitoring.deviceToken'), 'izd_x');
    final saved = (await MonitoringStore().enrollment())!;
    expect(saved.deviceToken, 'izd_x');
    expect(saved.deviceId, 'd1');
    expect(saved.applianceId, 'a1');
    expect(saved.isFor(contribuyenteId: 5, dispositivoId: 7), isTrue);
    expect(saved.isFor(contribuyenteId: 6, dispositivoId: 7), isFalse);
    expect(saved.isFor(contribuyenteId: 5, dispositivoId: 8), isFalse);

    await store.clearEnrollment(onlyToken: 'izd_older');
    expect((await store.enrollment())!.deviceToken, 'izd_x', reason: 'a newer token stays');

    await store.clearEnrollment();
    expect(await store.enrollment(), isNull);
    expect(await MonitoringStore().installationId(), id);
  });
}
