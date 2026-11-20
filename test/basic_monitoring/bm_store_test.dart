import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_store.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_web_signals.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('installationId es un UUID v4 y no cambia entre dos BmStore sobre las mismas prefs', () async {
    final prefs = await SharedPreferences.getInstance();
    final a = BmStore(prefs).installationId();
    final b = BmStore(prefs).installationId();
    expect(a, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(b, a);
  });

  test('clearEnrollment borra token y owner pero conserva installationId', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = BmStore(prefs);
    final id = store.installationId();
    await store.saveEnrollment(deviceToken: 't', deviceId: 'd', applianceId: 'a', owner: '1:2');
    expect(store.deviceToken, 't');
    expect(store.owner, '1:2');
    await store.replaceDeviceToken('t2');
    expect(store.deviceToken, 't2');
    await store.clearEnrollment();
    expect(store.deviceToken, isNull);
    expect(store.owner, isNull);
    expect(store.installationId(), id);
    expect(prefs.getKeys().every((k) => k.startsWith('bm.')), isTrue);
  });

  test('windowStartAt no cambia hasta commitWindow y los contadores se acumulan', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = BmStore(prefs);
    final t0 = DateTime.utc(2026, 11, 20, 10, 0, 0);
    final first = store.windowStartAt(t0);
    expect(store.windowStartAt(t0.add(const Duration(minutes: 5))), first);
    await store.addCounter('posHealthChecks', 2);
    await store.addCounter('posHealthChecks', 1);
    expect(store.pendingCounters(), {'posHealthChecks': 3});
    final t1 = t0.add(const Duration(minutes: 10));
    await store.commitWindow(t1);
    expect(store.pendingCounters(), <String, int>{});
    final second = store.windowStartAt(t1.add(const Duration(minutes: 1)));
    expect(second, isNot(first));
    expect(second, t1.toIso8601String());
    expect(BmStore(prefs).windowStartAt(t1), second);
  });

  test('markCommand y seenCommand, y olvida ids de más de 7 días', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = BmStore(prefs);
    final now = DateTime.utc(2026, 11, 20);
    expect(store.seenCommand('c1'), isFalse);
    await store.markCommand('old', now.subtract(const Duration(days: 8)));
    await store.markCommand('c1', now);
    expect(store.seenCommand('c1'), isTrue);
    expect(store.seenCommand('old'), isFalse);
  });

  test('señales web fuera de web devuelven null', () {
    expect(bmOnline(), isNull);
    expect(bmVisibility(), isNull);
  });
}
