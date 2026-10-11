import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/command_result_outbox.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/dto/monitoring_command_result_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monitoring_service_test.dart' show FakeMonitoringRepository, FakeTimers, FixedRandom;

const _context = MonitoringContext(contribuyenteId: 5, dispositivoId: 7);
const _app = MonitoringApp(version: '2.3.1+45', flavor: 'izify', platform: 'web');

void main() {
  late DateTime now;
  late FakeMonitoringRepository repository;
  late FakeTimers timers;
  late MonitoringService enrollment;
  late MemoryCommandResultStore store;
  late CommandResultOutbox outbox;

  MonitoringCommandResultDto result(String id,
          {MonitoringCommandStatus status = MonitoringCommandStatus.succeeded}) =>
      MonitoringCommandResultDto(commandId: id, type: 'reload_app', status: status, recordedAt: now);

  CommandResultOutbox build() => CommandResultOutbox(
      enrollment: enrollment,
      repository: repository,
      store: store,
      timer: timers.call,
      now: () => now,
      random: FixedRandom());

  setUp(() async {
    now = DateTime.utc(2026, 10, 12, 14);
    SharedPreferences.setMockInitialValues({
      'monitoring.installationId': MonitoringStore.newUuidV4(),
      'monitoring.deviceToken': 'izd_saved',
      'monitoring.deviceId': 'dev9',
      'monitoring.contribuyenteId': 5,
      'monitoring.dispositivoId': 7,
    });
    Telemetry.install(Telemetry());
    repository = FakeMonitoringRepository();
    timers = FakeTimers();
    enrollment = MonitoringService(
        repository: repository,
        store: MonitoringStore(),
        appInfo: () async => _app,
        timer: FakeTimers().call,
        now: () => now,
        random: FixedRandom());
    await enrollment.start(_context);
    store = MemoryCommandResultStore();
    outbox = build()..start();
    await pumpEventQueue();
  });

  tearDown(() => outbox.stop());

  test('sends the result with the device token, and forgets it once delivered', () async {
    repository.acceptResult();
    await outbox.add(result('c1'));
    expect(repository.results.single.token, 'izd_saved');
    expect(repository.results.single.result.commandId, 'c1');
    expect(outbox.pending, isEmpty);
    expect(store.saved, isEmpty);
  });

  test('a result that could not leave is kept, also across a reload, and retried', () async {
    repository.rejectResult(const MonitoringException('unreachable'));
    await outbox.add(result('c1'));
    expect(outbox.pending.single.commandId, 'c1');
    expect(store.saved.single.commandId, 'c1');
    expect(timers.active.single.delay, CommandResultOutbox.firstRetry);

    // The page reloads: a new outbox finds it and sends it.
    outbox.stop();
    repository.acceptResult();
    outbox = build()..start();
    await pumpEventQueue();
    expect(repository.results.map((r) => r.result.commandId), ['c1', 'c1']);
    expect(store.saved, isEmpty);
  });

  test('retries back off up to 5 minutes', () {
    expect(CommandResultOutbox.retryDelay(1, 0), const Duration(seconds: 10));
    expect(CommandResultOutbox.retryDelay(2, 0), const Duration(seconds: 20));
    expect(CommandResultOutbox.retryDelay(10, 0), CommandResultOutbox.maxBackoff);
    expect(CommandResultOutbox.retryDelay(1, 0.99).inMilliseconds, greaterThan(8000));
  });

  test('a command the service no longer has open is dropped, not retried', () async {
    repository
      ..rejectResult(const MonitoringException('http_409', statusCode: 409, code: 'command_not_open'))
      ..acceptResult();
    await outbox.add(result('c1'));
    await outbox.add(result('c2'));
    expect(repository.results.map((r) => r.result.commandId), ['c1', 'c2']);
    expect(outbox.pending, isEmpty);
    expect(timers.active, isEmpty);
    expect(Telemetry.recent().where((e) => e.type == 'monitoring.command_result_dropped'),
        hasLength(1));
  });

  test('a rejected device token is handed to the enrollment; the result waits for the next one',
      () async {
    repository
      ..rejectResult(const MonitoringException('http_401',
          statusCode: 401, code: MonitoringException.deviceTokenInvalid))
      ..succeed()
      ..acceptResult();
    await outbox.add(result('c1'));
    await pumpEventQueue();
    // Enrolled again with a new token: the result goes with it.
    expect(enrollment.deviceToken, 'izd_token1');
    expect(outbox.pending.single.commandId, 'c1');
    await timers.fire();
    expect(repository.results.last.token, 'izd_token1');
    expect(outbox.pending, isEmpty);
  });

  test('not enrolled: kept until there is a token', () async {
    enrollment.stop();
    await outbox.add(result('c1'));
    expect(repository.results, isEmpty);
    expect(outbox.pending, hasLength(1));
    repository.acceptResult();
    await enrollment.start(_context);
    await pumpEventQueue();
    expect(repository.results.single.result.commandId, 'c1');
  });

  test('a result older than an hour is dropped: its command expired long ago', () async {
    store.saved = [result('old')];
    outbox.stop();
    now = now.add(const Duration(hours: 2));
    outbox = build()..start();
    await pumpEventQueue();
    expect(repository.results, isEmpty);
    expect(store.saved, isEmpty);
  });

  test('what is stored holds no secret', () {
    final dto = MonitoringCommandResultDto(
        commandId: 'c1',
        type: 'rotate_token',
        status: MonitoringCommandStatus.failed,
        detail: 'token izd_AbCdEfGhIjKlMnOpQrSt rejected',
        data: const {'deviceToken': 'izd_AbCdEfGhIjKlMnOpQrSt'},
        recordedAt: now);
    final stored = dto.toStorage().toString();
    expect(stored, isNot(contains('izd_AbCd')));
    expect(MonitoringCommandResultDto.fromStorage(dto.toStorage())?.commandId, 'c1');
  });
}
