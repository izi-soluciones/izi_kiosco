import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:izi_kiosco/data/monitoring/agent_link.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_agent_client.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monitoring_service_test.dart' show FakeMonitoringRepository, FakeTimers, FixedRandom;

const _context = MonitoringContext(contribuyenteId: 5, dispositivoId: 7);
const _app = MonitoringApp(version: '2.3.1+45', flavor: 'izify', platform: 'web');
const _api = 'https://api.example.test/';

Map<String, Object?> _health({bool enrolled = false, String status = 'not_enrolled'}) => {
      'schema': 1,
      'kind': 'agent',
      'version': '1.0.0',
      'installationId': 'ab',
      'enrolled': enrolled,
      'status': status,
      'lastHeartbeatAt': null,
      'uptimeSec': 10,
    };

/// The agent on loopback: answers what the test sets.
class _Agent {
  final List<http.Request> requests = [];
  http.Response health = http.Response(jsonEncode(_health()), 200);
  http.Response enroll = http.Response(jsonEncode({'enrolled': true}), 200);
  bool reachable = true;

  late final http.Client client = MockClient((request) async {
    requests.add(request);
    // What the browser reports when nothing listens, or CORS blocks it.
    if (!reachable) throw http.ClientException('XMLHttpRequest error.');
    return request.url.path == '/enroll' ? enroll : health;
  });

  List<String> get paths => [for (final r in requests) '${r.method} ${r.url}'];
}

void main() {
  group('decide', () {
    const notEnrolled = KioskAgentHealth(enrolled: false, status: 'not_enrolled');

    test('an agent not enrolled next to an enrolled kiosk gets a code', () {
      expect(AgentLink.decide(health: notEnrolled, monitoringEnrolled: true), AgentNext.enroll);
      // After its token was revoked, too, or while it starts without one.
      for (final status in ['token_invalid', 'starting']) {
        expect(
            AgentLink.decide(
                health: KioskAgentHealth(enrolled: false, status: status), monitoringEnrolled: true),
            AgentNext.enroll);
      }
    });

    test('a token it cannot read yet gets a while before a code replaces it', () {
      const unreadable = KioskAgentHealth(enrolled: false, status: 'token_unreadable');
      expect(AgentLink.decide(health: unreadable, monitoringEnrolled: true), AgentNext.wait);
      expect(
          AgentLink.decide(
              health: unreadable,
              monitoringEnrolled: true,
              unreadableFor: AgentLink.unreadableGrace - const Duration(seconds: 1)),
          AgentNext.wait);
      expect(
          AgentLink.decide(
              health: unreadable, monitoringEnrolled: true, unreadableFor: AgentLink.unreadableGrace),
          AgentNext.enroll);
    });

    test('an enrolled agent is left alone', () {
      expect(
          AgentLink.decide(
              health: const KioskAgentHealth(enrolled: true, status: 'ok'), monitoringEnrolled: true),
          AgentNext.keep);
    });

    test('the kiosk not enrolled yet: no code to give', () {
      expect(AgentLink.decide(health: notEnrolled, monitoringEnrolled: false), AgentNext.keep);
    });

    test('unreachable, or already enrolling: ask again', () {
      expect(AgentLink.decide(health: null, monitoringEnrolled: true), AgentNext.retry);
      expect(
          AgentLink.decide(
              health: const KioskAgentHealth(enrolled: false, status: 'enrolling'),
              monitoringEnrolled: true),
          AgentNext.retry);
    });
  });

  test('an answer on the port that is not the agent is not taken for it', () async {
    final client = KioskAgentClient(
        httpClient: MockClient((_) async => http.Response(jsonEncode({'status': 'OK'}), 200)));
    await expectLater(client.health(),
        throwsA(isA<KioskAgentException>().having((e) => e.code, 'code', 'invalid_response')));
  });

  group('flow', () {
    late DateTime now;
    late FakeMonitoringRepository repository;
    late MonitoringService enrollment;
    late FakeTimers timers;
    late _Agent agent;
    late bool busy;
    late AgentLink link;

    setUp(() async {
      now = DateTime.utc(2026, 10, 12, 14);
      busy = false;
      SharedPreferences.setMockInitialValues({
        'monitoring.installationId': MonitoringStore.newUuidV4(),
        'monitoring.deviceToken': 'izd_saved',
        'monitoring.contribuyenteId': 5,
        'monitoring.dispositivoId': 7,
      });
      Telemetry.install(Telemetry());
      repository = FakeMonitoringRepository();
      timers = FakeTimers();
      agent = _Agent();
      enrollment = MonitoringService(
          repository: repository,
          store: MonitoringStore(),
          appInfo: () async => _app,
          timer: FakeTimers().call,
          now: () => now,
          random: FixedRandom());
      await enrollment.start(_context);
      link = AgentLink(
        enrollment: enrollment,
        repository: repository,
        client: KioskAgentClient(httpClient: agent.client),
        busy: () => busy,
        apiBaseUrl: () => _api,
        timer: timers.call,
        now: () => now,
        random: FixedRandom(),
      )..start();
    });

    tearDown(() => link.stop());

    test('state.agent stays out of the heartbeat until the agent was asked', () {
      expect(link.stateSection(), isNull);
      expect(timers.active.single.delay, AgentLink.firstCheckDelay);
    });

    test('an agent not enrolled gets a code for:agent, sent to it with the gateway', () async {
      repository.issueCode('K7Q-4MZ-9TD');
      await timers.fire();
      expect(agent.paths,
          ['GET http://127.0.0.1:47800/health', 'POST http://127.0.0.1:47800/enroll']);
      expect(repository.codeRequests.single.forKind, 'agent');
      expect(jsonDecode(agent.requests.last.body), {'code': 'K7Q-4MZ-9TD', 'apiBaseUrl': _api});
      expect(agent.requests.last.headers['Content-Type'], startsWith('application/json'));
      expect(link.stateSection(), {'reachable': true, 'enrolled': true});
      // Confirmed on the next /health.
      expect(timers.active.single.delay, AgentLink.enrollingRecheck);
    });

    test('no agent on this PC (or the browser blocks it): reachable false, nothing else, backoff',
        () async {
      agent.reachable = false;
      await timers.fire();
      expect(link.stateSection(), {'reachable': false});
      expect(repository.codeRequests, isEmpty);
      expect(timers.active.single.delay, const Duration(seconds: 30));
      await timers.fire();
      expect(timers.active.single.delay, const Duration(seconds: 60));
      // Not an error worth logging every time: most PCs have no agent yet.
      expect(Telemetry.recent().where((e) => e.type == 'monitoring.agent_enroll_failed'), isEmpty);
    });

    test('an enrolled agent is only watched', () async {
      agent.health = http.Response(jsonEncode(_health(enrolled: true, status: 'ok')), 200);
      await timers.fire();
      expect(agent.paths, ['GET http://127.0.0.1:47800/health']);
      expect(link.stateSection(), {'reachable': true, 'enrolled': true});
      expect(timers.active.single.delay, AgentLink.healthInterval);
    });

    test('the kiosk not enrolled: the agent waits; it gets its code once the kiosk enrolls',
        () async {
      enrollment.stop();
      await timers.fire();
      expect(repository.codeRequests, isEmpty);
      expect(link.stateSection(), {'reachable': true, 'enrolled': false});
      expect(timers.active.single.delay, AgentLink.healthInterval);

      await enrollment.start(_context);
      expect(timers.active.single.delay, AgentLink.firstCheckDelay);
    });

    test('not while a customer is paying', () async {
      busy = true;
      await timers.fire();
      expect(repository.codeRequests, isEmpty);
      expect(timers.active.single.delay, AgentLink.busyRetry);
    });

    test('an agent set up for another gateway is not insisted on', () async {
      agent.enroll = http.Response(jsonEncode({'error': 'api_base_url_mismatch'}), 409);
      repository.issueCode();
      await timers.fire();
      expect(link.status.value.lastCause, 'api_base_url_mismatch');
      expect(timers.active.single.delay, MonitoringService.maxBackoff);
    });

    test('a refused code is replaced by a new one right away, once', () async {
      var posts = 0;
      final codes = <String>[];
      final refusing = MockClient((request) async {
        if (request.url.path != '/enroll') return agent.health;
        posts++;
        codes.add((jsonDecode(request.body) as Map)['code'] as String);
        return posts == 1
            ? http.Response(jsonEncode({'error': 'enrollment_code_invalid'}), 400)
            : http.Response(jsonEncode({'enrolled': true}), 200);
      });
      link.stop();
      link = AgentLink(
        enrollment: enrollment,
        repository: repository,
        client: KioskAgentClient(httpClient: refusing),
        busy: () => busy,
        apiBaseUrl: () => _api,
        timer: timers.call,
        now: () => now,
        random: FixedRandom(),
      )..start();
      repository
        ..issueCode('AAA-AAA-AAA')
        ..issueCode('BBB-BBB-BBB');
      await timers.fire();
      expect(codes, ['AAA-AAA-AAA', 'BBB-BBB-BBB']);
      expect(repository.codeRequests.map((r) => r.forKind), ['agent', 'agent']);
      expect(link.stateSection(), {'reachable': true, 'enrolled': true});
      expect(link.status.value.failures, 0);
    });

    test('a second refused code in a row backs off', () async {
      agent.enroll = http.Response(jsonEncode({'error': 'enrollment_code_invalid'}), 400);
      repository
        ..issueCode()
        ..issueCode();
      await timers.fire();
      expect(repository.codeRequests, hasLength(2));
      expect(link.status.value.lastCause, 'enrollment_code_invalid');
      expect(timers.active.single.delay, const Duration(seconds: 30));
    });

    test('a request the agent does not take is not insisted on', () async {
      agent.enroll = http.Response(jsonEncode({'error': 'invalid_request'}), 400);
      repository.issueCode();
      await timers.fire();
      expect(link.status.value.lastCause, 'invalid_request');
      expect(timers.active.single.delay, MonitoringService.maxBackoff);
    });

    test('an agent busy redeeming (rate_limited, upstream_unavailable) backs off as usual',
        () async {
      for (final (status, error) in [(429, 'rate_limited'), (502, 'upstream_unavailable')]) {
        agent.enroll = http.Response(jsonEncode({'error': error}), status);
        repository.issueCode();
        await timers.fire();
        expect(link.status.value.lastCause, error);
        expect(timers.active.single.delay, lessThan(MonitoringService.maxBackoff));
      }
      expect(link.status.value.failures, 2);
    });

    test('an agent that cannot read its token yet gets 5 minutes before a code', () async {
      agent.health =
          http.Response(jsonEncode(_health(enrolled: false, status: 'token_unreadable')), 200);
      await timers.fire();
      expect(repository.codeRequests, isEmpty);
      expect(link.status.value.reason, 'token_unreadable');
      expect(timers.active.single.delay, AgentLink.unreadableGrace);

      // It read it meanwhile: nothing to do.
      agent.health = http.Response(jsonEncode(_health(enrolled: true, status: 'ok')), 200);
      now = now.add(AgentLink.unreadableGrace);
      await timers.fire();
      expect(repository.codeRequests, isEmpty);

      // Unreadable again, and still after the grace: it gets a code.
      agent.health =
          http.Response(jsonEncode(_health(enrolled: false, status: 'token_unreadable')), 200);
      now = now.add(AgentLink.healthInterval);
      await timers.fire();
      expect(repository.codeRequests, isEmpty, reason: 'the grace starts over');
      now = now.add(AgentLink.unreadableGrace);
      repository.issueCode();
      await timers.fire();
      expect(repository.codeRequests.single.forKind, 'agent');
      expect(link.stateSection(), {'reachable': true, 'enrolled': true});
    });

    test('a kiosk origin the agent does not allow is not insisted on', () async {
      agent.health = http.Response(jsonEncode({'error': 'origin_not_allowed'}), 403);
      await timers.fire();
      expect(link.status.value.lastCause, 'origin_not_allowed');
      expect(timers.active.single.delay, MonitoringService.maxBackoff);
    });

    test('already enrolled by hand meanwhile: taken as enrolled', () async {
      agent.enroll = http.Response(jsonEncode({'error': 'already_enrolled'}), 409);
      repository.issueCode();
      await timers.fire();
      expect(link.stateSection(), {'reachable': true, 'enrolled': true});
      expect(timers.active.single.delay, AgentLink.healthInterval);
    });

    test('a refused POST (CORS, private network) is swallowed and retried with backoff',
        () async {
      repository.issueCode();
      agent.enroll = http.Response('', 200);
      final failing = MockClient((request) async {
        if (request.url.path == '/enroll') throw http.ClientException('XMLHttpRequest error.');
        return agent.health;
      });
      link.stop();
      link = AgentLink(
        enrollment: enrollment,
        repository: repository,
        client: KioskAgentClient(httpClient: failing),
        busy: () => false,
        apiBaseUrl: () => _api,
        timer: timers.call,
        now: () => now,
        random: FixedRandom(),
      )..start();
      await timers.fire();
      expect(link.status.value.state, 'failed');
      expect(link.status.value.lastCause, 'unreachable');
      expect(timers.active.single.delay, const Duration(seconds: 30));
    });
  });
}
