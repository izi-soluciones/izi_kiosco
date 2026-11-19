import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/command_result_outbox.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_commands.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/dto/monitoring_command_result_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_heartbeat_response.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monitoring_service_test.dart' show FakeMonitoringRepository, FakeTimers, FixedRandom;

const _context = MonitoringContext(contribuyenteId: 5, dispositivoId: 7);

void main() {
  late DateTime now;
  late FakeMonitoringRepository repository;
  late FakeTimers timers;
  late MonitoringService enrollment;
  late MonitoringCommandRunner runner;
  late bool busy;
  late List<String> ran;

  MonitoringCommand command(String id,
          {String type = 'reload_app', Duration expiresIn = const Duration(minutes: 10)}) =>
      MonitoringCommand(id: id, type: type, expiresAt: now.add(expiresIn));

  Future<CommandOutcome> succeed(MonitoringCommand c) async {
    ran.add(c.id);
    return const CommandOutcome.succeeded(detail: 'done');
  }

  /// Reported results, as `id:status[:reason]`.
  List<String> reported() => [
        for (final r in repository.results)
          '${r.result.commandId}:${r.result.status.name}'
              '${r.result.data['reason'] == null ? '' : ':${r.result.data['reason']}'}'
      ];

  /// Fires the runner's pending timer and lets it finish.
  Future<Duration> fire() => timers.fire();

  setUp(() async {
    now = DateTime.utc(2026, 10, 12, 14);
    busy = false;
    ran = [];
    SharedPreferences.setMockInitialValues({
      'monitoring.installationId': MonitoringStore.newUuidV4(),
      'monitoring.deviceToken': 'izd_saved',
      'monitoring.contribuyenteId': 5,
      'monitoring.dispositivoId': 7,
    });
    Telemetry.install(Telemetry());
    repository = FakeMonitoringRepository();
    timers = FakeTimers();
    enrollment = MonitoringService(
        repository: repository,
        store: MonitoringStore(),
        appInfo: () async => const MonitoringApp(version: '2.3.1+45', flavor: 'izify', platform: 'web'),
        timer: FakeTimers().call,
        now: () => now,
        random: FixedRandom());
    await enrollment.start(_context);
    runner = MonitoringCommandRunner(
      outbox: CommandResultOutbox(
          enrollment: enrollment,
          repository: repository,
          store: MemoryCommandResultStore(),
          timer: FakeTimers().call,
          now: () => now),
      handlers: {'reload_app': succeed, 'repair_pos': succeed},
      busy: () => busy,
      timer: timers.call,
      now: () => now,
    );
  });

  group('dispatcher', () {
    test('runs nothing while the heartbeat hands the commands over', () {
      runner.enqueue([command('c1')]);
      expect(ran, isEmpty);
      expect(timers.active.single.delay, Duration.zero);
    });

    test('runs each command by its type, in order, and reports its result', () async {
      repository
        ..acceptResult()
        ..acceptResult();
      runner.enqueue([command('c1'), command('c2', type: 'repair_pos')]);
      await fire();
      expect(ran, ['c1', 'c2']);
      expect(reported(), ['c1:succeeded', 'c2:succeeded']);
      expect(repository.results.first.token, 'izd_saved');
      expect(repository.results.first.result.toJson(), {'status': 'succeeded', 'detail': 'done', 'data': {}});
    });

    test('a command delivered twice runs once', () async {
      repository.acceptResult();
      runner.enqueue([command('c1')]);
      runner.enqueue([command('c1')]);
      await fire();
      runner.enqueue([command('c1')]);
      expect(timers.active, isEmpty);
      expect(ran, ['c1']);
    });

    test('a type the kiosk does not run is rejected as unsupported', () async {
      repository.acceptResult();
      runner.enqueue([command('c1', type: 'reboot_pc')]);
      await fire();
      expect(ran, isEmpty);
      expect(reported(), ['c1:rejected:unsupported']);
    });

    test('a handler that throws is reported failed, and the next one still runs', () async {
      repository
        ..acceptResult()
        ..acceptResult();
      runner.handlers['repair_pos'] = (_) async => throw StateError('boom');
      runner.enqueue([command('c1', type: 'repair_pos'), command('c2')]);
      await fire();
      expect(reported(), ['c1:failed', 'c2:succeeded']);
      expect(repository.results.first.result.detail, 'StateError');
    });

    test('beyond capacity, a command is rejected instead of kept', () async {
      for (var i = 0; i < MonitoringCommandRunner.capacity + 1; i++) {
        repository.acceptResult();
      }
      runner.enqueue([for (var i = 0; i < MonitoringCommandRunner.capacity + 1; i++) command('c$i')]);
      await pumpEventQueue();
      expect(reported(), ['c20:rejected:queue_full']);
      expect(runner.pending, hasLength(MonitoringCommandRunner.capacity));
    });

    test('an outcome with something to do afterwards does it once the result left', () async {
      final order = <String>[];
      repository.resultReplies.add(() async => order.add('reported'));
      runner.handlers['reload_app'] = (_) async =>
          CommandOutcome.succeeded(after: () async => order.add('reloaded'));
      runner.enqueue([command('c1')]);
      await fire();
      expect(order, ['reported', 'reloaded']);
    });

    test('nor does a result that cannot leave hold the reload back for ever', () async {
      var reloaded = false;
      repository.rejectResult(const MonitoringException('unreachable'));
      runner.handlers['reload_app'] =
          (_) async => CommandOutcome.succeeded(after: () async => reloaded = true);
      runner.enqueue([command('c1')]);
      await fire();
      expect(reloaded, isTrue);
      expect(runner.outbox.pending.single.commandId, 'c1');
    });
  });

  group('expiry', () {
    test('a command past its expiresAt is rejected as expired, not run', () async {
      repository.acceptResult();
      runner.enqueue([command('c1', expiresIn: const Duration(minutes: 1))]);
      now = now.add(const Duration(minutes: 2));
      await fire();
      expect(ran, isEmpty);
      expect(reported(), ['c1:rejected:expired']);
    });

    test('is judged by the service clock: a kiosk clock ahead does not expire it', () async {
      repository.acceptResult();
      // The kiosk clock runs 15 min ahead of the service's.
      final serverNow = now;
      now = now.add(const Duration(minutes: 15));
      runner.enqueue([MonitoringCommand(id: 'c1', type: 'reload_app', expiresAt: serverNow.add(const Duration(minutes: 10)))],
          serverTime: serverNow);
      await fire();
      expect(reported(), ['c1:succeeded']);
    });

    test('and a kiosk clock behind does not keep it alive', () async {
      repository.acceptResult();
      final serverNow = now;
      now = now.subtract(const Duration(minutes: 30));
      runner.enqueue([MonitoringCommand(id: 'c1', type: 'reload_app', expiresAt: serverNow.subtract(const Duration(seconds: 1)))],
          serverTime: serverNow);
      await fire();
      expect(reported(), ['c1:rejected:expired']);
    });
  });

  group('busy rule', () {
    test('never runs while a customer is paying; runs once the kiosk is free', () async {
      busy = true;
      runner.enqueue([command('c1')]);
      expect(await fire(), Duration.zero);
      expect(ran, isEmpty);
      expect(repository.results, isEmpty);
      expect(timers.active.single.delay, MonitoringCommandRunner.busyRecheck);
      expect(Telemetry.recent().where((e) => e.type == 'monitoring.command_postponed'), hasLength(1));

      now = now.add(const Duration(seconds: 5));
      await fire();
      expect(ran, isEmpty);

      busy = false;
      repository.acceptResult();
      now = now.add(const Duration(seconds: 5));
      await fire();
      expect(ran, ['c1']);
      expect(reported(), ['c1:succeeded']);
      // Logged once, not on every check.
      expect(Telemetry.recent().where((e) => e.type == 'monitoring.command_postponed'), hasLength(1));
    });

    test('still busy after 2 minutes: rejected with reason busy, never run', () async {
      busy = true;
      repository.acceptResult();
      runner.enqueue([command('c1')]);
      await fire();
      var waited = Duration.zero;
      while (repository.results.isEmpty) {
        final delay = timers.active.single.delay;
        expect(delay, lessThanOrEqualTo(MonitoringCommandRunner.busyRecheck));
        waited += delay;
        now = now.add(delay);
        await fire();
      }
      expect(waited, MonitoringCommandRunner.maxPostpone);
      expect(ran, isEmpty);
      expect(reported(), ['c1:rejected:busy']);
      expect(repository.results.single.result.toJson()['data'], {'reason': 'busy'});
    });

    test('the commands behind a postponed one wait with it', () async {
      busy = true;
      runner.enqueue([command('c1'), command('c2', type: 'repair_pos')]);
      await fire();
      expect(runner.pending.map((c) => c.id), ['c1', 'c2']);
      busy = false;
      repository
        ..acceptResult()
        ..acceptResult();
      await fire();
      expect(ran, ['c1', 'c2']);
    });

    test('a busy check that throws counts as busy', () async {
      runner = MonitoringCommandRunner(
          outbox: runner.outbox,
          handlers: {'reload_app': succeed},
          busy: () => throw StateError('no activity'),
          timer: timers.call,
          now: () => now);
      runner.enqueue([command('c1')]);
      await fire();
      expect(ran, isEmpty);
      expect(runner.pending, hasLength(1));
    });
  });

  test('a rejection carries its reason in data', () {
    final outcome = CommandOutcome.rejected('busy');
    expect(outcome.status, MonitoringCommandStatus.rejected);
    expect(outcome.data, {'reason': 'busy'});
  });
}
