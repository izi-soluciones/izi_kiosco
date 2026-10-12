import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:izi_kiosco/data/monitoring/command_result_outbox.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_commands.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_diagnostics.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_collector.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_commands.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/monitoring/pos_link_health.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/blocs/pos_config/pos_config_bloc.dart';
import 'package:izi_kiosco/domain/dto/monitoring_command_result_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_heartbeat_response.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monitoring_service_test.dart' show FakeMonitoringRepository, FakeTimers, FixedRandom;

const _context = MonitoringContext(contribuyenteId: 5, dispositivoId: 7);
const _app = MonitoringApp(version: '2.3.1+45', flavor: 'izify', platform: 'web');
const _rotated = 'izd_NewTokenFromTheService_0123456789';

class _PosConfig extends Mock implements PosConfigBloc {}

void main() {
  late DateTime now;
  late FakeMonitoringRepository repository;
  late MonitoringService enrollment;
  late KioskCommands commands;
  IzifyPosSession? session;
  late http.Client terminal;
  late bool paying;

  MonitoringCommand command(String type, {Map<String, dynamic> args = const {}}) =>
      MonitoringCommand(id: 'cmd1', type: type, args: args, expiresAt: now.add(const Duration(minutes: 10)));

  setUp(() async {
    now = DateTime.utc(2026, 10, 12, 14);
    session = null;
    paying = false;
    terminal = MockClient((_) async => http.Response('', 404));
    SharedPreferences.setMockInitialValues({
      'monitoring.installationId': MonitoringStore.newUuidV4(),
      'monitoring.deviceToken': 'izd_saved',
      'monitoring.deviceId': 'dev9',
      'monitoring.applianceId': 'app1',
      'monitoring.contribuyenteId': 5,
      'monitoring.dispositivoId': 7,
    });
    Telemetry.install(Telemetry());
    repository = FakeMonitoringRepository();
    enrollment = MonitoringService(
        repository: repository,
        store: MonitoringStore(),
        appInfo: () async => _app,
        timer: FakeTimers().call,
        now: () => now,
        random: FixedRandom());
    await enrollment.start(_context);
    commands = KioskCommands(
      enrollment: enrollment,
      repository: repository,
      diagnostics: KioskDiagnostics(
        collector: () => KioskHealthCollector(
          activity: () => KioskActivity()..screenChanged('/home'),
          link: () => PosLinkHealth(now: () => now, counters: () => KioskCounters()),
          session: (_) async => null,
          configuredAddress: (_) async => null,
          posName: () async => null,
          pendingCardErrors: () async => 0,
          visibility: () => 'visible',
          online: () => true,
          now: () => now,
        ),
        session: (_) async => session,
        client: () => IzifyPosClient(httpClient: terminal),
        now: () => now,
        busy: () => paying,
      ),
      reloadPage: () => false,
    );
  });

  test('handles the four kiosk commands of the contract', () {
    expect(commands.handlers.keys,
        unorderedEquals(['reload_app', 'repair_pos', 'upload_diagnostics', 'rotate_token']));
  });

  group('reload_app', () {
    test('reports first, then saves the log and restarts the app', () async {
      final order = <String>[];
      commands = KioskCommands(
          enrollment: enrollment,
          repository: repository,
          reloadPage: () => false,
          beforeReload: () async => order.add('saved'))
        ..restartApp = () => order.add('restarted');
      final outcome = await commands.reload(command('reload_app'));
      expect(outcome.status, MonitoringCommandStatus.succeeded);
      expect(order, isEmpty);
      await outcome.after!();
      expect(order, ['saved', 'restarted']);
    });

    test('a save that hangs does not keep the reload from happening', () async {
      var restarted = false;
      commands = KioskCommands(
          enrollment: enrollment,
          repository: repository,
          reloadPage: () => false,
          beforeReload: () => Completer<void>().future)
        ..restartApp = () => restarted = true;
      final outcome = await commands.reload(command('reload_app'));
      await outcome.after!();
      expect(restarted, isTrue);
    });

    test('the web page reload goes first when there is a page', () async {
      var restarted = 0;
      var reloaded = 0;
      commands = KioskCommands(
          enrollment: enrollment, repository: repository, reloadPage: () => ++reloaded > 0)
        ..restartApp = () => restarted++;
      final outcome = await commands.reload(command('reload_app'));
      await outcome.after!();
      expect(reloaded, 1);
      expect(restarted, 0);
    });

    test('without a way to restart, it fails instead of claiming success', () async {
      final outcome = await commands.reload(command('reload_app'));
      expect(outcome.status, MonitoringCommandStatus.failed);
      expect(outcome.detail, 'not_available');
    });

    test('through the runner the result leaves before the restart', () async {
      final order = <String>[];
      commands.restartApp = () => order.add('restart');
      repository.resultReplies.add(() async => order.add('result'));
      final runner = MonitoringCommandRunner(
          outbox: CommandResultOutbox(
              enrollment: enrollment, repository: repository, store: MemoryCommandResultStore()),
          handlers: commands.handlers,
          busy: () => false,
          timer: FakeTimers().call,
          now: () => now);
      runner.enqueue([command('reload_app')]);
      await runner.pump();
      expect(order, ['result', 'restart']);
      expect(repository.results.single.result.status, MonitoringCommandStatus.succeeded);
    });

    group('keeps to the busy rule up to the reload itself', () {
      late bool busy;
      late FakeTimers timers;
      late List<String> order;

      List<String> deferred() => [
            for (final e in Telemetry.instance.buffer.events)
              if (e.type == 'monitoring.reload_deferred') e.type
          ];

      setUp(() {
        busy = false;
        timers = FakeTimers();
        order = [];
        commands = KioskCommands(
            enrollment: enrollment,
            repository: repository,
            reloadPage: () {
              order.add(busy ? 'reload:busy' : 'reload');
              return true;
            },
            beforeReload: () async => order.add('saved'),
            busy: () => busy,
            timer: timers.call)
          // Off the web the handler needs a restart to claim success; the
          // page reload above goes first.
          ..restartApp = () => order.add('restart');
      });

      test('a customer who reaches the payment while the result leaves is not interrupted',
          () async {
        // The service answers just as the customer taps "Pagar".
        repository.resultReplies.add(() async => busy = true);
        final runner = MonitoringCommandRunner(
            outbox: CommandResultOutbox(
                enrollment: enrollment, repository: repository, store: MemoryCommandResultStore()),
            handlers: commands.handlers,
            busy: () => busy,
            timer: FakeTimers().call,
            now: () => now);
        runner.enqueue([command('reload_app')]);
        unawaited(runner.pump());
        await pumpEventQueue();
        expect(repository.results.single.result.status, MonitoringCommandStatus.succeeded);
        expect(order, isEmpty);
        expect(deferred(), hasLength(1));

        // Still paying at the next check.
        expect(await timers.fire(), MonitoringCommandRunner.busyRecheck);
        expect(order, isEmpty);

        busy = false;
        await timers.fire();
        expect(order, ['saved', 'reload']);
        expect(deferred(), hasLength(1));
      });

      test('nor one who reaches it while the records are saved', () async {
        commands = KioskCommands(
            enrollment: enrollment,
            repository: repository,
            reloadPage: () {
              order.add(busy ? 'reload:busy' : 'reload');
              return true;
            },
            beforeReload: () async {
              order.add('saved');
              busy = order.length == 1;
            },
            busy: () => busy,
            timer: timers.call)
          // Off the web the handler needs a restart to claim success; the
          // page reload above goes first.
          ..restartApp = () => order.add('restart');
        final outcome = await commands.reload(command('reload_app'));
        final done = outcome.after!();
        await pumpEventQueue();
        expect(order, ['saved']);

        busy = false;
        await timers.fire();
        await done;
        expect(order, ['saved', 'saved', 'reload']);
      });

      test('a reload already reported stays due past the 2 min, until the kiosk is free',
          () async {
        busy = true;
        final outcome = await commands.reload(command('reload_app'));
        unawaited(outcome.after!());
        await pumpEventQueue();
        final checks = MonitoringCommandRunner.maxPostpone.inSeconds ~/
                MonitoringCommandRunner.busyRecheck.inSeconds +
            2;
        for (var i = 0; i < checks; i++) {
          await timers.fire();
        }
        expect(order, isEmpty);

        busy = false;
        await timers.fire();
        expect(order, ['saved', 'reload']);
      });

      test('a busy rule that cannot be read counts as busy', () async {
        commands = KioskCommands(
            enrollment: enrollment,
            repository: repository,
            reloadPage: () {
              order.add('reload');
              return true;
            },
            beforeReload: () async {},
            busy: () => throw StateError('no activity'),
            timer: timers.call)
          // Off the web the handler needs a restart to claim success; the
          // page reload above goes first.
          ..restartApp = () => order.add('restart');
        final outcome = await commands.reload(command('reload_app'));
        unawaited(outcome.after!());
        await pumpEventQueue();
        expect(order, isEmpty);
        expect(timers.active, hasLength(1));
      });

      test('outside the browser the restart keeps to it too', () async {
        commands = KioskCommands(
            enrollment: enrollment,
            repository: repository,
            reloadPage: () => false,
            beforeReload: () async {},
            busy: () => busy,
            timer: timers.call)
          ..restartApp = () => order.add(busy ? 'restart:busy' : 'restart');
        busy = true;
        final outcome = await commands.reload(command('reload_app'));
        unawaited(outcome.after!());
        await pumpEventQueue();
        expect(order, isEmpty);
        busy = false;
        await timers.fire();
        expect(order, ['restart']);
      });
    });
  });

  group('repair_pos', () {
    late _PosConfig bloc;

    setUp(() {
      bloc = _PosConfig();
      when(() => bloc.isClosed).thenReturn(false);
      when(() => bloc.repair()).thenAnswer((_) async {});
      commands.attachStates(posConfig: bloc);
    });

    test('asks the pairing to repair itself, and succeeds when the terminal ends up ready',
        () async {
      when(() => bloc.state).thenReturn(PosConfigState.init().copyWith(
          status: PosConfigStatus.paired,
          pairedDevice: const PosDevice(name: 'POS', ip: '192.168.1.50', port: 8081),
          isHealthy: true));
      final outcome = await commands.repair(command('repair_pos'));
      verify(() => bloc.repair()).called(1);
      expect(outcome.status, MonitoringCommandStatus.succeeded);
      expect(outcome.data, {'paired': true, 'address': '192.168.1.50:8081', 'healthy': true});
    });

    test('a terminal still not ready is a failure, with the reason', () async {
      when(() => bloc.state).thenReturn(PosConfigState.init().copyWith(
          pairedDevice: const PosDevice(name: 'POS', ip: '192.168.1.50', port: 8081),
          isHealthy: false,
          notReadyReason: () => 'El datáfono no responde.'));
      final outcome = await commands.repair(command('repair_pos'));
      expect(outcome.status, MonitoringCommandStatus.failed);
      expect(outcome.detail, 'El datáfono no responde.');
    });

    test('no terminal paired after trying: failed, not paired', () async {
      when(() => bloc.state).thenReturn(PosConfigState.init());
      final outcome = await commands.repair(command('repair_pos'));
      expect(outcome.status, MonitoringCommandStatus.failed);
      expect(outcome.data, {'paired': false});
    });

    test('before the app set the pairing up: failed, nothing called', () async {
      commands.attachStates();
      final outcome = await commands.repair(command('repair_pos'));
      expect(outcome.detail, 'not_ready');
    });
  });

  group('upload_diagnostics', () {
    test('uploads the Kiosco tab and says the terminal is not paired', () async {
      Telemetry.event('pos.health_failed', data: {'cause': 'timeout'});
      repository.acceptDiagnostics('diag7');
      final outcome = await commands.upload(command('upload_diagnostics'));
      expect(outcome.status, MonitoringCommandStatus.succeeded);
      expect(outcome.data, {'diagnosticId': 'diag7', 'size': 1234, 'terminal': 'not_paired'});
      final sent = repository.diagnostics.single;
      expect(sent.commandId, 'cmd1');
      expect(sent.token, 'izd_saved');
      final kiosk = sent.report['kiosk'] as Map;
      expect(kiosk.keys, containsAll(['context', 'state', 'monitoring', 'events']));
      expect((kiosk['monitoring'] as Map)['health'], isA<Map>());
      expect(jsonEncode(kiosk['events']), contains('pos.health_failed'));
      expect(sent.report['terminal'], {'unavailable': 'not_paired'});
    });

    test("includes the terminal's own record when it answers, redacted", () async {
      session = const IzifyPosSession(IzifyPosAddress('192.168.1.50'), 'pairing-token');
      terminal = MockClient((request) async {
        expect(request.url.path, '/diagnostics');
        expect(request.headers['Authorization'], 'Bearer pairing-token');
        return http.Response(
            jsonEncode({
              'app': {'version': '1.29'},
              'pairing': {'token': 'pairing-token', 'kioskHash': 'a1b2'},
              'events': [
                {'ts': '2026-10-12T13:00:00Z', 'type': 'charge.result', 'data': {'card': '4111 1111 1111 1111'}},
              ],
            }),
            200);
      });
      repository.acceptDiagnostics();
      final outcome = await commands.upload(command('upload_diagnostics'));
      expect(outcome.data['terminal'], 'included');
      final report = jsonEncode(repository.diagnostics.single.report);
      expect(report, contains('charge.result'));
      expect(report, isNot(contains('pairing-token')));
      expect(report, isNot(contains('4111 1111')));
    });

    test('a customer who started paying meanwhile: the terminal is not asked', () async {
      session = const IzifyPosSession(IzifyPosAddress('192.168.1.50'), 'pairing-token');
      var asked = 0;
      terminal = MockClient((_) async {
        asked++;
        return http.Response('{}', 200);
      });
      paying = true;
      repository.acceptDiagnostics();
      final outcome = await commands.upload(command('upload_diagnostics'));
      expect(asked, 0);
      expect(outcome.status, MonitoringCommandStatus.succeeded);
      expect(outcome.data['terminal'], 'busy');
      expect(repository.diagnostics.single.report['terminal'], {'unavailable': 'busy'});
    });

    test('an unreachable terminal does not fail the upload', () async {
      session = const IzifyPosSession(IzifyPosAddress('192.168.1.50'), 'tok');
      terminal = MockClient((_) async => throw http.ClientException('Connection refused'));
      repository.acceptDiagnostics();
      final outcome = await commands.upload(command('upload_diagnostics'));
      expect(outcome.status, MonitoringCommandStatus.succeeded);
      expect(outcome.data['terminal'], 'unreachable');
    });

    test('an upload the service refuses is a failure with its cause', () async {
      repository.rejectDiagnostics(
          const MonitoringException('http_413', statusCode: 413, code: 'payload_too_large'));
      final outcome = await commands.upload(command('upload_diagnostics'));
      expect(outcome.status, MonitoringCommandStatus.failed);
      expect(outcome.detail, 'http_413');
      expect(outcome.data, {'code': 'payload_too_large'});
    });
  });

  group('rotate_token', () {
    test('keeps the token the service sent, stored before the result is reported', () async {
      final outcome = await commands.rotate(command('rotate_token', args: {'deviceToken': _rotated}));
      expect(outcome.status, MonitoringCommandStatus.succeeded);
      expect(enrollment.deviceToken, _rotated);
      expect((await MonitoringStore().enrollment())?.deviceToken, _rotated);
      expect((await MonitoringStore().enrollment())?.deviceId, 'dev9');
      // Nothing about the token in the result or the log.
      expect(jsonEncode(outcome.data), isNot(contains('izd_')));
      expect(jsonEncode([for (final e in Telemetry.recent()) e.toJson()]), isNot(contains(_rotated)));
    });

    test('through the runner the result is confirmed with the new token', () async {
      repository.acceptResult();
      final runner = MonitoringCommandRunner(
          outbox: CommandResultOutbox(
              enrollment: enrollment, repository: repository, store: MemoryCommandResultStore()),
          handlers: commands.handlers,
          busy: () => false,
          timer: FakeTimers().call,
          now: () => now);
      runner.enqueue([command('rotate_token', args: {'deviceToken': _rotated})]);
      await runner.pump();
      await pumpEventQueue();
      expect(repository.results.single.token, _rotated);
      expect(repository.results.single.result.status, MonitoringCommandStatus.succeeded);
    });

    test('a token that is not a device token is refused, the current one stays', () async {
      final outcome = await commands.rotate(command('rotate_token', args: {'deviceToken': 'nope'}));
      expect(outcome.status, MonitoringCommandStatus.failed);
      expect(outcome.detail, 'invalid_token');
      expect(enrollment.deviceToken, 'izd_saved');
    });

    test('logged out meanwhile: nothing to rotate, nothing stored', () async {
      enrollment.stop();
      expect(await enrollment.adoptRotatedToken(_rotated), isFalse);
      expect((await MonitoringStore().enrollment())?.deviceToken, 'izd_saved');
    });

    test('without a token in the args, enrolls again', () async {
      repository.succeed();
      final outcome = await commands.rotate(command('rotate_token'));
      expect(outcome.status, MonitoringCommandStatus.succeeded);
      expect(outcome.detail, 'reenrolled');
      expect(enrollment.deviceToken, 'izd_token1');
    });

    test('an enrollment that fails is a failed rotation', () async {
      repository.failWith(const MonitoringException('unreachable'));
      final outcome = await commands.rotate(command('rotate_token'));
      expect(outcome.status, MonitoringCommandStatus.failed);
      expect(outcome.data, {'cause': 'unreachable'});
    });
  });
}
