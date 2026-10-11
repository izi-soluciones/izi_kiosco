import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/command_result_outbox.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_collector.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_snapshot.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_commands.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_heartbeat.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/monitoring/pos_link_health.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_heartbeat_response.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monitoring_service_test.dart' show FakeMonitoringRepository, FakeTimers, FixedRandom;

const _context = MonitoringContext(contribuyenteId: 5, dispositivoId: 7, deviceName: 'KIOSKO-01');
const _app = MonitoringApp(version: '2.3.1+45', flavor: 'izify', platform: 'web');
const _invalidToken = MonitoringException('http_401',
    statusCode: 401, code: MonitoringException.deviceTokenInvalid);

void main() {
  late FakeMonitoringRepository repository;
  late FakeTimers enrollTimers;
  late FakeTimers beatTimers;
  late MonitoringService enrollment;
  late KioskCounters counters;
  late MonitoringCommandRunner commands;
  late KioskHealthCollector collector;
  late MonitoringHeartbeat heartbeat;
  late String installationId;
  late DateTime now;

  MonitoringHeartbeat build({KioskHealthCollector? using}) => MonitoringHeartbeat(
        enrollment: enrollment,
        repository: repository,
        collector: () => using ?? collector,
        counters: () => counters,
        commands: commands,
        appInfo: () async => _app,
        timer: beatTimers.call,
        now: () => now,
        random: FixedRandom(),
      );

  /// Logs in with a token stored by an earlier enrollment.
  Future<void> enrolled() async {
    await enrollment.start(_context);
    expect(enrollment.deviceToken, 'izd_saved');
  }

  /// Fires the pending heartbeat and returns the delay it was scheduled with.
  Future<Duration> fireBeat() => beatTimers.fire();

  Duration nextDelay() => beatTimers.active.single.delay;

  setUp(() {
    now = DateTime.utc(2026, 10, 12, 14);
    installationId = MonitoringStore.newUuidV4();
    SharedPreferences.setMockInitialValues({
      'monitoring.installationId': installationId,
      'monitoring.deviceToken': 'izd_saved',
      'monitoring.deviceId': 'dev9',
      'monitoring.contribuyenteId': 5,
      'monitoring.dispositivoId': 7,
    });
    Telemetry.install(Telemetry());
    repository = FakeMonitoringRepository();
    enrollTimers = FakeTimers();
    beatTimers = FakeTimers();
    enrollment = MonitoringService(
        repository: repository,
        store: MonitoringStore(),
        appInfo: () async => _app,
        timer: enrollTimers.call,
        now: () => now,
        random: FixedRandom());
    counters = KioskCounters(store: MemoryCountersStore(), now: () => now);
    // Never fired: the heartbeat only hands commands over.
    commands = MonitoringCommandRunner(
        outbox: CommandResultOutbox(
            enrollment: enrollment, repository: repository, store: MemoryCommandResultStore()),
        timer: FakeTimers().call,
        now: () => now);
    collector = KioskHealthCollector(
      activity: () => KioskActivity()..screenChanged('/home'),
      link: () => PosLinkHealth(now: () => now, counters: () => KioskCounters()),
      session: (_) async => null,
      configuredAddress: (_) async => null,
      posName: () async => null,
      pendingCardErrors: () async => 1,
      visibility: () => 'visible',
      online: () => true,
      now: () => now,
    );
    heartbeat = build();
  });

  tearDown(() => heartbeat.stop());

  group('loop', () {
    test('nothing is sent until the kiosk is enrolled', () async {
      heartbeat.start();
      expect(beatTimers.all, isEmpty);
      expect(heartbeat.status.value.running, isFalse);
    });

    test('once enrolled: a first heartbeat shortly, with the device token and the contract body',
        () async {
      heartbeat.start();
      await enrolled();
      repository.acceptBeat();

      expect(await fireBeat(), MonitoringHeartbeat.firstBeatDelay);
      final sent = repository.heartbeats.single;
      expect(sent.token, 'izd_saved');
      final body = sent.dto.toJson();
      expect(body['schema'], 1);
      expect(body['kind'], 'kiosk');
      expect(body['installationId'], installationId);
      expect(MonitoringStore.isUuidV4(body['bootId'] as String), isTrue);
      expect(body['bootId'], heartbeat.bootId);
      expect(body['uptimeSec'], isA<int>());
      expect(body['sentAt'], '2026-10-12T14:00:00.000Z');
      expect(body['app'], {'version': '2.3.1+45', 'flavor': 'izify', 'platform': 'web'});
      expect(body.containsKey('lastEventSeq'), isFalse, reason: 'no events are uploaded yet');
      final state = body['state'] as Map;
      expect(state['screen'], '/home');
      expect(state['mode'], 'idle');
      expect(state['pendingCardErrors'], 1);
      expect((state['pos'] as Map)['status'], 'not_configured');
      final counters = body['counters'] as Map;
      expect(counters['windowStartAt'], '2026-10-12T14:00:00.000Z');
      expect(counters.keys.skip(1), KioskCounters.names);

      expect(nextDelay(), MonitoringHeartbeat.defaultInterval);
      expect(heartbeat.status.value.running, isTrue);
      expect(heartbeat.status.value.lastOkAt, now);
    });

    test('starting with a token already there works the same', () async {
      await enrolled();
      heartbeat.start();
      expect(nextDelay(), MonitoringHeartbeat.firstBeatDelay);
    });

    test('keeps going every interval', () async {
      heartbeat.start();
      await enrolled();
      repository
        ..acceptBeat()
        ..acceptBeat();
      await fireBeat();
      expect(await fireBeat(), MonitoringHeartbeat.defaultInterval);
      expect(repository.heartbeats, hasLength(2));
    });

    test('stops when the kiosk logs out, and resumes on the next login', () async {
      heartbeat.start();
      await enrolled();
      enrollment.stop();
      expect(beatTimers.active, isEmpty);
      expect(heartbeat.status.value.running, isFalse);

      await enrolled();
      expect(nextDelay(), MonitoringHeartbeat.firstBeatDelay);
    });

    test('lastEventSeq goes in once the event upload fills it', () async {
      heartbeat
        ..lastEventSeq = (() => 1234)
        ..start();
      await enrolled();
      repository.acceptBeat();
      await fireBeat();
      expect(repository.heartbeats.single.dto.toJson()['lastEventSeq'], 1234);
    });
  });

  group('response', () {
    Future<void> answer(MonitoringHeartbeatResponse response) async {
      heartbeat.start();
      await enrolled();
      repository.acceptBeat(response);
      await fireBeat();
    }

    test('nextInSec is honoured', () async {
      await answer(const MonitoringHeartbeatResponse(nextInSec: 10));
      expect(nextDelay(), const Duration(seconds: 10));
      expect(heartbeat.interval, const Duration(seconds: 10));
    });

    test('nextInSec is kept within bounds', () {
      expect(MonitoringHeartbeat.intervalFor(null), MonitoringHeartbeat.defaultInterval);
      expect(MonitoringHeartbeat.intervalFor(0), MonitoringHeartbeat.defaultInterval);
      expect(MonitoringHeartbeat.intervalFor(-5), MonitoringHeartbeat.defaultInterval);
      expect(MonitoringHeartbeat.intervalFor(1), MonitoringHeartbeat.minInterval);
      expect(MonitoringHeartbeat.intervalFor(90), const Duration(seconds: 90));
      expect(MonitoringHeartbeat.intervalFor(86400), MonitoringHeartbeat.maxInterval);
    });

    test('ackSeq is kept for the event upload', () async {
      await answer(const MonitoringHeartbeatResponse(ackSeq: 1234));
      expect(heartbeat.ackSeq, 1234);
      expect(heartbeat.status.value.ackSeq, 1234);
    });

    test('a response without ackSeq keeps the last one', () async {
      await answer(const MonitoringHeartbeatResponse(ackSeq: 7));
      repository.acceptBeat();
      await fireBeat();
      expect(heartbeat.ackSeq, 7);
    });

    test('commands are handed to the queue, not run', () async {
      await answer(MonitoringHeartbeatResponse(commands: [
        MonitoringCommand(id: 'c1', type: 'reload_app', expiresAt: now.add(const Duration(minutes: 5))),
      ]));
      expect(commands.pending.single.type, 'reload_app');
      expect(Telemetry.recent().where((e) => e.type == 'monitoring.command_received'), hasLength(1));
    });

    test('with the service clock, so expiry does not depend on the kiosk clock', () async {
      await answer(MonitoringHeartbeatResponse(
          serverTime: now.add(const Duration(minutes: 3)),
          commands: [MonitoringCommand(id: 'c1', type: 'reload_app', expiresAt: now)]));
      expect(commands.serverNow, now.add(const Duration(minutes: 3)));
    });
  });

  group('counters', () {
    test('are taken off only after a 2xx', () async {
      heartbeat.start();
      await enrolled();
      counters.add(KioskCounters.orders, 2);

      repository.rejectBeat(const MonitoringException('unreachable'));
      await fireBeat();
      expect(counters[KioskCounters.orders], 2, reason: 'not accepted: they stay');

      counters.add(KioskCounters.orders);
      now = now.add(const Duration(minutes: 1));
      repository.acceptBeat();
      await fireBeat();
      final retried = repository.heartbeats.last.dto.toJson()['counters'] as Map;
      expect(retried['orders'], 3);
      expect(retried['windowStartAt'], '2026-10-12T14:00:00.000Z',
          reason: 'the same window, so the service adds only the difference');
      expect(repository.heartbeats.first.dto.toJson()['counters']['windowStartAt'],
          retried['windowStartAt']);

      expect(counters[KioskCounters.orders], 0);
      expect(counters.windowStartAt, now);
    });

    test('a 401 is not a 2xx either', () async {
      heartbeat.start();
      await enrolled();
      counters.add(KioskCounters.chargesStarted);
      repository
        ..rejectBeat(_invalidToken)
        ..succeed();
      await fireBeat();
      expect(counters[KioskCounters.chargesStarted], 1);
    });
  });

  group('failures', () {
    test('back off: the interval, then doubling up to 5 minutes', () async {
      heartbeat.start();
      await enrolled();
      final delays = <Duration>[];
      for (var i = 0; i < 5; i++) {
        repository.rejectBeat(const MonitoringException('timeout'));
        await fireBeat();
        delays.add(nextDelay());
      }
      expect(delays, const [
        Duration(seconds: 60),
        Duration(seconds: 120),
        Duration(seconds: 240),
        Duration(minutes: 5),
        Duration(minutes: 5),
      ]);
      expect(heartbeat.status.value.failures, 5);
      expect(heartbeat.status.value.lastCause, 'timeout');

      repository.acceptBeat();
      await fireBeat();
      expect(nextDelay(), MonitoringHeartbeat.defaultInterval);
      expect(heartbeat.status.value.failures, 0);
      expect(Telemetry.recent().where((e) => e.type == 'monitoring.heartbeat_recovered').single.data,
          {'failures': 5});
    });

    test('jitter only shortens the wait, never under the minimum', () {
      expect(MonitoringHeartbeat.retryDelayFor(const Duration(seconds: 60), 1, 0.999),
          const Duration(milliseconds: 48012));
      expect(MonitoringHeartbeat.retryDelayFor(const Duration(seconds: 10), 1, 0.999),
          MonitoringHeartbeat.minInterval);
      expect(MonitoringHeartbeat.retryDelayFor(const Duration(seconds: 60), 40, 0),
          MonitoringHeartbeat.maxBackoff);
    });

    test('a long outage is logged in detail at first, then sampled', () async {
      heartbeat.start();
      await enrolled();
      for (var i = 0; i < 12; i++) {
        repository.rejectBeat(const MonitoringException('unreachable'));
        await fireBeat();
      }
      final logged = Telemetry.recent()
          .where((e) => e.type == 'monitoring.heartbeat_failed')
          .map((e) => e.data['failures'])
          .toList();
      expect(logged, [10, 3, 2, 1]);
    });

    test('nothing escapes: a snapshot that cannot be built is a failed heartbeat', () async {
      heartbeat.stop();
      heartbeat = build(using: _ThrowingCollector());
      heartbeat.start();
      await enrolled();
      await fireBeat();
      expect(repository.heartbeats, isEmpty);
      expect(heartbeat.status.value.failures, 1);
      expect(nextDelay(), MonitoringHeartbeat.defaultInterval);
    });
  });

  group('rejected token', () {
    test('device_token_invalid: forgets the token, enrolls again and resumes with the new one',
        () async {
      heartbeat.start();
      await enrolled();
      repository
        ..rejectBeat(_invalidToken)
        ..succeed()
        ..acceptBeat();

      await fireBeat();
      expect(repository.calls, hasLength(1), reason: 'enrolled again through KIO-01');
      expect(enrollment.deviceToken, 'izd_token1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('monitoring.deviceToken'), 'izd_token1');
      expect(Telemetry.recent().where((e) => e.type == 'monitoring.token_rejected'), hasLength(1));

      expect(await fireBeat(), MonitoringHeartbeat.firstBeatDelay);
      expect(repository.heartbeats.map((h) => h.token), ['izd_saved', 'izd_token1']);
    });

    test('while the enrollment fails, nothing is sent with the dead token', () async {
      heartbeat.start();
      await enrolled();
      repository
        ..rejectBeat(_invalidToken)
        ..failWith(const MonitoringException('unreachable'));

      await fireBeat();
      expect(enrollment.deviceToken, isNull);
      expect(beatTimers.active, isEmpty);
      expect(heartbeat.status.value.running, isFalse);
      expect(enrollTimers.active, hasLength(1), reason: 'the enrollment retries on its own');
    });

    test('fresh tokens rejected again: the enrollments back off, nothing is sent meanwhile',
        () async {
      heartbeat.start();
      await enrolled();

      // The first rejection enrolls right away.
      repository
        ..rejectBeat(_invalidToken)
        ..succeed();
      await fireBeat();
      expect(repository.calls, hasLength(1));
      expect(enrollTimers.active, isEmpty);
      expect(nextDelay(), MonitoringHeartbeat.firstBeatDelay);

      // Every new token is rejected too (e.g. two PCs cloned from the same
      // image revoking each other's token): each enrollment waits longer.
      final waits = <Duration>[];
      for (var i = 0; i < 7; i++) {
        repository
          ..rejectBeat(_invalidToken)
          ..succeed();
        await fireBeat();
        expect(repository.calls, hasLength(i + 1), reason: 'no enrollment before the wait');
        expect(beatTimers.active, isEmpty, reason: 'nothing is sent while waiting');
        expect(enrollment.status.value.state, MonitoringState.error);
        expect(enrollment.status.value.lastCause, MonitoringException.deviceTokenInvalid);
        waits.add(await enrollTimers.fire());
        expect(repository.calls, hasLength(i + 2));
        expect(enrollment.deviceToken, 'izd_token${i + 2}');
      }
      expect(waits, const [
        Duration(seconds: 30),
        Duration(minutes: 1),
        Duration(minutes: 2),
        Duration(minutes: 4),
        Duration(minutes: 8),
        Duration(minutes: 16),
        Duration(minutes: 30),
      ]);
      expect(Telemetry.recent().where((e) => e.type == 'monitoring.reenroll_delayed'), hasLength(7));
    });

    test('a heartbeat accepted with the new token resets the count', () async {
      heartbeat.start();
      await enrolled();
      repository
        ..rejectBeat(_invalidToken)
        ..succeed()
        ..rejectBeat(_invalidToken)
        ..succeed();
      await fireBeat();
      await fireBeat();
      expect(await enrollTimers.fire(), MonitoringService.initialBackoff);
      expect(enrollment.deviceToken, 'izd_token2');

      repository
        ..acceptBeat()
        ..rejectBeat(_invalidToken)
        ..succeed();
      await fireBeat();
      await fireBeat();
      expect(enrollTimers.active, isEmpty, reason: 'it worked in between: enrolls right away');
      expect(enrollment.deviceToken, 'izd_token3');
    });

    test('another 401 is an ordinary failure', () async {
      heartbeat.start();
      await enrolled();
      repository.rejectBeat(const MonitoringException('http_401', statusCode: 401));
      await fireBeat();
      expect(repository.calls, isEmpty);
      expect(enrollment.deviceToken, 'izd_saved');
      expect(nextDelay(), MonitoringHeartbeat.defaultInterval);
    });
  });
}

class _ThrowingCollector extends KioskHealthCollector {
  @override
  Future<KioskHealthSnapshot> collect() async => throw StateError('broken');
}
