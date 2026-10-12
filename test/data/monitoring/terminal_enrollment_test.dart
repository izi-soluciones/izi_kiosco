import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/monitoring/terminal_enrollment.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/blocs/pos_config/pos_config_bloc.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_enrollment_code.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monitoring_service_test.dart' show FakeMonitoringRepository, FakeTimers, FixedRandom;

const _context = MonitoringContext(contribuyenteId: 5, dispositivoId: 7);
const _app = MonitoringApp(version: '2.3.1+45', flavor: 'izify', platform: 'web');
const _device = PosDevice(name: 'POS', ip: '192.168.1.50', port: 8081);
const _api = 'https://api.example.test/';

/// The longest backoff for a random of 0.5 (as is), 0 (the whole jitter
/// shorter) and 1 (kept at the cap).
const _longestWaits = [
  (0.5, MonitoringService.maxBackoff),
  (0.0, Duration(minutes: 24)),
  (1.0, MonitoringService.maxBackoff),
];

final _healthy = PosConfigState.init()
    .copyWith(status: PosConfigStatus.paired, pairedDevice: _device, isHealthy: true);

/// The PayPOS terminal: answers what the test sets, and remembers each
/// request.
class _Terminal {
  final List<http.Request> requests = [];
  http.Response status = http.Response(jsonEncode({'enrolled': false}), 200);
  http.Response enroll = http.Response(jsonEncode({'enrolled': true, 'deviceId': 't1'}), 200);

  late final http.Client client = MockClient((request) async {
    requests.add(request);
    return switch (request.url.path) {
      '/monitoring/status' => status,
      '/monitoring/enroll' => enroll,
      _ => http.Response('', 404),
    };
  });

  List<String> get paths => [for (final r in requests) '${r.method} ${r.url.path}'];
}

void main() {
  group('blockedBy', () {
    PosConfigState pos({PosDevice? device = _device, bool? healthy = true, PosConfigStatus status = PosConfigStatus.paired}) =>
        PosConfigState(status: status, discoveredDevices: const [], pairedDevice: device, isHealthy: healthy);

    test('only an enrolled kiosk with a paired, healthy terminal and no sale going on', () {
      expect(TerminalEnrollment.blockedBy(monitoringEnrolled: true, pos: pos(), busy: false), isNull);
    });

    test('the kiosk not enrolled comes first: there is no appliance to join', () {
      expect(TerminalEnrollment.blockedBy(monitoringEnrolled: false, pos: pos(), busy: true),
          TerminalEnrollBlock.notEnrolled);
    });

    test('no pairing, or no pairing state yet', () {
      expect(TerminalEnrollment.blockedBy(monitoringEnrolled: true, pos: pos(device: null), busy: false),
          TerminalEnrollBlock.notPaired);
      expect(TerminalEnrollment.blockedBy(monitoringEnrolled: true, pos: null, busy: false),
          TerminalEnrollBlock.notPaired);
    });

    test('paired but not answering, not checked yet, or pairing again', () {
      for (final state in [
        pos(healthy: false),
        pos(healthy: null),
        pos(status: PosConfigStatus.pairing),
      ]) {
        expect(TerminalEnrollment.blockedBy(monitoringEnrolled: true, pos: state, busy: false),
            TerminalEnrollBlock.unhealthy);
      }
    });

    test('never during a charge', () {
      expect(TerminalEnrollment.blockedBy(monitoringEnrolled: true, pos: pos(), busy: true),
          TerminalEnrollBlock.busy);
    });
  });

  group('flow', () {
    late DateTime now;
    late FakeMonitoringRepository repository;
    late MonitoringService enrollment;
    late FakeTimers timers;
    late _Terminal terminal;
    late PosConfigState pos;
    late StreamController<PosConfigState> posChanges;
    late bool busy;
    late String? api;
    late FixedRandom random;
    late TerminalEnrollment zeroTouch;

    setUp(() async {
      now = DateTime.utc(2026, 10, 12, 14);
      busy = false;
      api = _api;
      random = FixedRandom();
      pos = _healthy;
      posChanges = StreamController.broadcast();
      SharedPreferences.setMockInitialValues({
        'monitoring.installationId': MonitoringStore.newUuidV4(),
        'monitoring.deviceToken': 'izd_saved',
        'monitoring.contribuyenteId': 5,
        'monitoring.dispositivoId': 7,
      });
      Telemetry.install(Telemetry());
      repository = FakeMonitoringRepository();
      timers = FakeTimers();
      terminal = _Terminal();
      enrollment = MonitoringService(
          repository: repository,
          store: MonitoringStore(),
          appInfo: () async => _app,
          timer: FakeTimers().call,
          now: () => now,
          random: FixedRandom());
      zeroTouch = TerminalEnrollment(
        enrollment: enrollment,
        repository: repository,
        client: IzifyPosClient(httpClient: terminal.client),
        session: (_) async => const IzifyPosSession(IzifyPosAddress('192.168.1.50'), 'pairing-token'),
        busy: () => busy,
        apiBaseUrl: () => api,
        timer: timers.call,
        now: () => now,
        random: random,
      )..attachState(pos: () => pos, changes: posChanges.stream);
    });

    tearDown(() async {
      zeroTouch.stop();
      await posChanges.close();
    });

    Future<void> enrolledKiosk() async {
      zeroTouch.start();
      await enrollment.start(_context);
      expect(timers.active.single.delay, TerminalEnrollment.firstCheckDelay);
    }

    test('nothing happens until the kiosk itself is enrolled', () async {
      zeroTouch.start();
      expect(timers.all, isEmpty);
      expect(zeroTouch.status.value.reason, 'not_enrolled');
    });

    test('a terminal not enrolled gets a code for:terminal and the kiosk gateway', () async {
      await enrolledKiosk();
      repository.issueCode('K7Q-4MZ-9TD');
      await timers.fire();

      expect(terminal.paths, ['GET /monitoring/status', 'POST /monitoring/enroll']);
      expect(terminal.requests.first.headers['Authorization'], 'Bearer pairing-token');
      expect(repository.codeRequests.single.forKind, 'terminal');
      expect(repository.codeRequests.single.token, 'izd_saved');
      final body = jsonDecode(terminal.requests.last.body);
      expect(body, {'code': 'K7Q-4MZ-9TD', 'apiBaseUrl': _api});
      expect(terminal.requests.last.headers['Authorization'], 'Bearer pairing-token');
      expect(zeroTouch.status.value.state, 'enrolled');
      expect(timers.active.single.delay, TerminalEnrollment.recheckEnrolled);
      // The code never reaches the log.
      expect(jsonEncode([for (final e in Telemetry.recent()) e.toJson()]), isNot(contains('K7Q')));
    });

    test('a terminal already enrolled is left alone: no code is issued', () async {
      terminal.status = http.Response(jsonEncode({'enrolled': true}), 200);
      await enrolledKiosk();
      await timers.fire();
      expect(terminal.paths, ['GET /monitoring/status']);
      expect(repository.codeRequests, isEmpty);
      expect(timers.active.single.delay, TerminalEnrollment.recheckEnrolled);
    });

    test('an older PayPOS without the routes (404) is tolerated and asked again much later',
        () async {
      terminal.status = http.Response('Not Found', 404);
      await enrolledKiosk();
      await timers.fire();
      expect(repository.codeRequests, isEmpty);
      expect(zeroTouch.status.value.state, 'unsupported');
      expect(timers.active.single.delay, TerminalEnrollment.recheckUnsupported);
      await timers.fire();
      expect(Telemetry.recent().where((e) => e.type == 'monitoring.terminal_unsupported'),
          hasLength(1));
    });

    test('never during a charge: not even the status is asked', () async {
      busy = true;
      await enrolledKiosk();
      await timers.fire();
      expect(terminal.requests, isEmpty);
      expect(zeroTouch.status.value.reason, 'busy');
      expect(timers.active.single.delay, TerminalEnrollment.busyRetry);
    });

    test('a charge that starts while the code is on its way stops the enrollment', () async {
      await enrolledKiosk();
      repository.codeReplies.add(() async {
        busy = true;
        return const MonitoringEnrollmentCode(code: 'K7Q-4MZ-9TD');
      });
      await timers.fire();
      expect(terminal.paths, ['GET /monitoring/status']);
      expect(timers.active.single.delay, TerminalEnrollment.busyRetry);
    });

    test('the terminal saying BUSY is asked again shortly, without counting a failure', () async {
      terminal.enroll = http.Response(jsonEncode({'success': false, 'code': 'BUSY', 'message': 'cobrando'}), 409);
      await enrolledKiosk();
      repository.issueCode();
      await timers.fire();
      expect(timers.active.single.delay, TerminalEnrollment.busyRetry);
      expect(zeroTouch.status.value.failures, 0);
    });

    test('failures back off from 30 s, doubling', () async {
      terminal.enroll = http.Response(
          jsonEncode({'success': false, 'code': 'ENROLL_FAILED', 'message': 'x'}), 502);
      await enrolledKiosk();
      repository.issueCode();
      await timers.fire();
      expect(timers.active.single.delay, const Duration(seconds: 30));
      repository.issueCode();
      await timers.fire();
      expect(timers.active.single.delay, const Duration(seconds: 60));
      expect(zeroTouch.status.value.lastCause, 'enroll_failed');
      expect(Telemetry.recent().where((e) => e.type == 'monitoring.terminal_enroll_failed'),
          hasLength(2));
    });

    test('a code the terminal refuses is replaced by a new one right away, once', () async {
      final codes = <String>[];
      var posts = 0;
      final refusing = MockClient((request) async {
        if (request.url.path == '/monitoring/status') return terminal.status;
        posts++;
        codes.add((jsonDecode(request.body) as Map)['code'] as String);
        return posts == 1
            ? http.Response(
                jsonEncode({'success': false, 'code': 'ENROLLMENT_CODE_INVALID', 'message': 'x'}),
                400)
            : http.Response(jsonEncode({'enrolled': true}), 200);
      });
      zeroTouch.stop();
      zeroTouch = TerminalEnrollment(
        enrollment: enrollment,
        repository: repository,
        client: IzifyPosClient(httpClient: refusing),
        session: (_) async => const IzifyPosSession(IzifyPosAddress('192.168.1.50'), 'pairing-token'),
        busy: () => busy,
        apiBaseUrl: () => _api,
        timer: timers.call,
        now: () => now,
        random: FixedRandom(),
      )..attachState(pos: () => pos, changes: posChanges.stream);
      await enrolledKiosk();
      repository
        ..issueCode('AAA-AAA-AAA')
        ..issueCode('BBB-BBB-BBB');
      await timers.fire();
      expect(codes, ['AAA-AAA-AAA', 'BBB-BBB-BBB']);
      expect(repository.codeRequests.map((r) => r.forKind), ['terminal', 'terminal']);
      expect(zeroTouch.status.value.state, 'enrolled');
      expect(zeroTouch.status.value.failures, 0);
      expect(timers.active.single.delay, TerminalEnrollment.recheckEnrolled);
    });

    test('a second refused code in a row backs off, and gets a new code next time', () async {
      terminal.enroll = http.Response(
          jsonEncode({'success': false, 'code': 'ENROLLMENT_CODE_INVALID', 'message': 'x'}), 400);
      await enrolledKiosk();
      repository
        ..issueCode()
        ..issueCode();
      await timers.fire();
      expect(repository.codeRequests, hasLength(2));
      expect(zeroTouch.status.value.lastCause, 'enrollment_code_invalid');
      expect(timers.active.single.delay, const Duration(seconds: 30));
    });

    test('a code refused for non-payment (401 bloqueadoPago) backs off; the token stays',
        () async {
      await enrolledKiosk();
      repository.refuseCode(const MonitoringException('http_401',
          statusCode: 401, code: MonitoringException.paymentBlocked));
      await timers.fire();
      expect(zeroTouch.status.value.lastCause, 'http_401');
      expect(timers.active.single.delay, const Duration(seconds: 30));
      expect(enrollment.deviceToken, 'izd_saved');
      expect(repository.calls, isEmpty, reason: 'no re-enrollment of the kiosk');
    });

    test('a request this PayPOS build does not take waits the longest backoff (24 to 30 min)',
        () async {
      terminal.enroll =
          http.Response(jsonEncode({'success': false, 'code': 'INVALID_BODY', 'message': 'x'}), 400);
      await enrolledKiosk();
      for (final (r, wait) in _longestWaits) {
        random.value = r;
        repository.issueCode();
        await timers.fire();
        expect(zeroTouch.status.value.lastCause, 'invalid_body');
        expect(timers.active.single.delay, wait, reason: 'random $r');
      }
    });

    test('a kiosk without a gateway URL to hand over waits 24 to 30 min', () async {
      api = null;
      await enrolledKiosk();
      for (final (r, wait) in _longestWaits) {
        random.value = r;
        await timers.fire();
        expect(terminal.paths.last, 'GET /monitoring/status');
        expect(repository.codeRequests, isEmpty);
        expect(zeroTouch.status.value.lastCause, 'no_api_url');
        expect(timers.active.single.delay, wait, reason: 'random $r');
      }
    });

    test('a charge starting while the refused code is replaced stops the enrollment', () async {
      terminal.enroll = http.Response(
          jsonEncode({'success': false, 'code': 'ENROLLMENT_CODE_INVALID', 'message': 'x'}), 400);
      await enrolledKiosk();
      repository
        ..issueCode()
        ..codeReplies.add(() async {
          busy = true;
          return const MonitoringEnrollmentCode(code: 'BBB-BBB-BBB');
        });
      await timers.fire();
      expect(terminal.paths, ['GET /monitoring/status', 'POST /monitoring/enroll']);
      expect(timers.active.single.delay, TerminalEnrollment.busyRetry);
    });

    test('a gateway this PayPOS build refuses waits the longest backoff (24 to 30 min)',
        () async {
      terminal.enroll = http.Response(jsonEncode({'success': false, 'code': 'API_NOT_ALLOWED'}), 400);
      await enrolledKiosk();
      for (final (r, wait) in _longestWaits) {
        random.value = r;
        repository.issueCode();
        await timers.fire();
        expect(zeroTouch.status.value.lastCause, 'api_not_allowed');
        expect(timers.active.single.delay, wait, reason: 'random $r');
      }
    });

    test('a code the service will not issue backs off too', () async {
      await enrolledKiosk();
      repository.refuseCode(const MonitoringException('http_503', statusCode: 503));
      await timers.fire();
      expect(terminal.paths, ['GET /monitoring/status']);
      expect(timers.active.single.delay, const Duration(seconds: 30));
    });

    test('an unreachable terminal is a failure with backoff', () async {
      terminal = _Terminal();
      zeroTouch.stop();
      zeroTouch = TerminalEnrollment(
        enrollment: enrollment,
        repository: repository,
        client: IzifyPosClient(
            httpClient: MockClient((_) async => throw http.ClientException('Connection refused'))),
        session: (_) async => const IzifyPosSession(IzifyPosAddress('192.168.1.50'), 'tok'),
        busy: () => false,
        apiBaseUrl: () => _api,
        timer: timers.call,
        now: () => now,
        random: FixedRandom(),
      )..attachState(pos: () => pos);
      await enrolledKiosk();
      await timers.fire();
      expect(zeroTouch.status.value.state, 'failed');
      expect(timers.active.single.delay, const Duration(seconds: 30));
    });

    test('an unhealthy terminal is waited for, and checked soon once it is back', () async {
      pos = _healthy.copyWith(isHealthy: false);
      await enrolledKiosk();
      await timers.fire();
      expect(terminal.requests, isEmpty);
      expect(zeroTouch.status.value.reason, 'unhealthy');
      expect(timers.active.single.delay, TerminalEnrollment.waitForPos);

      pos = _healthy;
      posChanges.add(pos);
      await pumpEventQueue();
      expect(timers.active.single.delay, TerminalEnrollment.firstCheckDelay);
    });

    test('a healthy terminal already looked at is not asked again on every health check',
        () async {
      terminal.status = http.Response(jsonEncode({'enrolled': true}), 200);
      await enrolledKiosk();
      await timers.fire();
      posChanges.add(_healthy);
      await pumpEventQueue();
      expect(timers.active.single.delay, TerminalEnrollment.recheckEnrolled);

      // Paired with another terminal: that one is looked at soon.
      posChanges.add(_healthy.copyWith(
          pairedDevice: const PosDevice(name: 'POS', ip: '192.168.1.60', port: 8081)));
      await pumpEventQueue();
      expect(timers.active.single.delay, TerminalEnrollment.firstCheckDelay);
    });

    test('logged out: stops', () async {
      await enrolledKiosk();
      enrollment.stop();
      expect(timers.active, isEmpty);
    });
  });
}

