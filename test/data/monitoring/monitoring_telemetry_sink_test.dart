import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_telemetry_sink.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_buffer.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/dto/monitoring_events_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_events_response.dart';
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
  late FakeTimers timers;
  late MonitoringService enrollment;
  late MemoryTelemetryStore bufferStore;
  late TelemetryBuffer buffer;
  late MemoryEventStreamStore streamStore;
  late MonitoringTelemetrySink sink;
  late String installationId;
  late bool charging;
  late DateTime now;

  /// A kiosk session: the buffer as the previous one left it, the upload
  /// and the telemetry recording into both.
  Future<void> boot({int capacity = 500}) async {
    buffer = TelemetryBuffer(store: bufferStore, capacity: capacity, saveDelay: Duration.zero);
    await buffer.restore();
    sink = MonitoringTelemetrySink(
      enrollment: enrollment,
      repository: repository,
      buffer: buffer,
      store: streamStore,
      chargeInProgress: () => charging,
      online: () => true,
      timer: timers.call,
      now: () => now,
      random: FixedRandom(),
    );
    await sink.restore();
    Telemetry.install(Telemetry(buffer: buffer, sinks: [sink]));
  }

  void record(int count, {String type = 'e', TelemetryLevel level = TelemetryLevel.info}) {
    for (var i = 0; i < count; i++) {
      Telemetry.event(type, level: level);
    }
  }

  /// Logs in with a token stored by an earlier enrollment, and uploads.
  Future<void> enrolled() async {
    await enrollment.start(_context);
    expect(enrollment.deviceToken, 'izd_saved');
    sink.start();
  }

  Future<Duration> fire() => timers.fire();

  Duration nextDelay() => timers.active.single.delay;

  List<int> seqs(MonitoringEventsDto dto) => [for (final e in dto.events) e.seq];

  List<TelemetryEvent> recorded(String type) =>
      buffer.events.where((e) => e.type == type).toList();

  setUp(() {
    now = DateTime.utc(2026, 10, 12, 14);
    charging = false;
    installationId = MonitoringStore.newUuidV4();
    SharedPreferences.setMockInitialValues({
      'monitoring.installationId': installationId,
      'monitoring.deviceToken': 'izd_saved',
      'monitoring.deviceId': 'dev9',
      'monitoring.contribuyenteId': 5,
      'monitoring.dispositivoId': 7,
    });
    repository = FakeMonitoringRepository();
    enrollTimers = FakeTimers();
    timers = FakeTimers();
    enrollment = MonitoringService(
        repository: repository,
        store: MonitoringStore(),
        appInfo: () async => _app,
        timer: enrollTimers.call,
        now: () => now,
        random: FixedRandom());
    bufferStore = MemoryTelemetryStore();
    streamStore = MemoryEventStreamStore();
  });

  tearDown(() {
    sink.stop();
    Telemetry.install(Telemetry());
  });

  group('upload', () {
    test('nothing is sent until the kiosk is enrolled', () async {
      await boot();
      record(3);
      sink.start();
      expect(timers.all, isEmpty);
      expect(sink.status.value.running, isFalse);
      expect(sink.backlog(), 3, reason: 'the events wait in the buffer');
    });

    test('once enrolled: the pending events, with the device token and the contract body',
        () async {
      await boot();
      record(1, type: 'app.start');
      record(1, type: 'pos.health_failed', level: TelemetryLevel.warning);
      await enrolled();
      repository.acceptUpload();

      expect(await fire(), MonitoringTelemetrySink.firstUploadDelay);
      final sent = repository.uploads.single;
      expect(sent.token, 'izd_saved');
      final body = sent.dto.toJson();
      expect(body['schema'], 1);
      expect(body['installationId'], installationId);
      expect(MonitoringStore.isUuidV4(body['stream'] as String), isTrue);
      expect(body['stream'], sink.state!.stream);
      final events = (body['events'] as List).cast<Map>();
      expect(events.map((e) => e['type']),
          ['app.start', 'pos.health_failed', 'telemetry.stream_started']);
      expect(events.map((e) => e['seq']), [1, 2, 3]);
      expect(events[1]['level'], 'warn', reason: 'the contract says warn');
      expect((events[0]['ts'] as String).endsWith('Z'), isTrue, reason: 'UTC');
      expect(events[2]['data'], containsPair('reason', 'new'));

      expect(sink.state!.ackSeq, 3);
      expect(sink.backlog(), 0);
      expect(nextDelay(), MonitoringTelemetrySink.interval);
      expect(sink.status.value.running, isTrue);
      expect(sink.status.value.lastOkAt, now);
      expect(sink.lastEventSeq(), 3);
    });

    test('an acknowledged event is never sent again, and batches are of 200 at most', () async {
      await boot();
      record(250);
      await enrolled();
      repository.acceptUpload();
      await fire();
      expect(seqs(repository.uploads[0].dto), List.generate(200, (i) => i + 1));
      expect(sink.state!.ackSeq, 200);
      expect(sink.backlog(), 51, reason: '250 + the stream note - 200');
      expect(nextDelay(), MonitoringTelemetrySink.drainDelay, reason: 'more are waiting');

      repository.acceptUpload();
      await fire();
      expect(seqs(repository.uploads[1].dto), List.generate(51, (i) => i + 201));
      expect(sink.backlog(), 0);
      expect(nextDelay(), MonitoringTelemetrySink.interval);
    });

    test('only what the service acknowledges is forgotten', () async {
      await boot();
      record(10);
      await enrolled();
      repository.answerUpload((dto) => MonitoringEventsResponse(ackSeq: 6, stream: dto.stream));
      await fire();
      expect(sink.state!.ackSeq, 6);
      repository.acceptUpload();
      await fire();
      expect(seqs(repository.uploads[1].dto).first, 7);
    });

    test('an answer that acknowledges nothing new backs off', () async {
      await boot();
      record(2);
      await enrolled();
      repository.answerUpload((dto) => MonitoringEventsResponse(ackSeq: 0, stream: dto.stream));
      await fire();
      expect(sink.state!.ackSeq, 0);
      expect(sink.status.value.lastCause, 'not_acknowledged');
      expect(nextDelay(), MonitoringTelemetrySink.interval);
    });

    test('an answer for another stream acknowledges nothing', () async {
      await boot();
      record(2);
      await enrolled();
      repository.answerUpload((_) => const MonitoringEventsResponse(ackSeq: 3, stream: 'other'));
      await fire();
      expect(sink.state!.ackSeq, 0);
      expect(sink.status.value.lastCause, 'invalid_response');
    });

    test('failures back off up to 5 minutes and are recorded sparingly', () async {
      await boot();
      record(2);
      await enrolled();
      final delays = <Duration>[];
      for (var i = 0; i < 6; i++) {
        repository.rejectUpload(const MonitoringException('unreachable'));
        await fire();
        delays.add(nextDelay());
      }
      expect(delays.map((d) => d.inSeconds), [30, 60, 120, 240, 300, 300]);
      expect(recorded('monitoring.events_failed'), hasLength(MonitoringTelemetrySink.detailedFailures));
      expect(sink.state!.ackSeq, 0);

      repository.acceptUpload();
      await fire();
      expect(recorded('monitoring.events_recovered').single.data['failures'], 6);
      expect(nextDelay(), MonitoringTelemetrySink.drainDelay,
          reason: 'the recovery note itself is pending');
    });

    test('a batch too big for the service is sent in halves', () async {
      await boot();
      record(150);
      await enrolled();
      repository.rejectUpload(const MonitoringException('http_413', statusCode: 413));
      await fire();
      expect(nextDelay(), MonitoringTelemetrySink.drainDelay);
      repository.acceptUpload();
      await fire();
      expect(repository.uploads.map((u) => u.dto.events.length), [151, 100]);
    });

    test('events never go over the size the service takes', () async {
      await boot();
      final chunk = 'x' * 290;
      // ~60 KB each: three fit in a batch.
      for (var i = 0; i < 5; i++) {
        Telemetry.event('big', data: {for (var k = 0; k < 200; k++) 'k$k': chunk});
      }
      // One alone over the limit travels without its data.
      Telemetry.event('huge', data: {for (var k = 0; k < 800; k++) 'k$k': chunk});
      await enrolled();
      for (var i = 0; i < 3; i++) {
        repository.acceptUpload();
        await fire();
      }
      final sizes = repository.uploads.map((u) => u.dto.events.length).toList();
      expect(sizes, [3, 2, 1]);
      final huge = repository.uploads[2].dto.events.first;
      expect(huge.type, 'huge');
      expect(huge.data['truncated'], isTrue);
    });

    test('a rejected token is handed to the enrollment, and uploads resume with the new one',
        () async {
      // Enrolling the same installation again keeps its device (the fake
      // issues dev1).
      SharedPreferences.setMockInitialValues({
        'monitoring.installationId': installationId,
        'monitoring.deviceToken': 'izd_saved',
        'monitoring.deviceId': 'dev1',
        'monitoring.contribuyenteId': 5,
        'monitoring.dispositivoId': 7,
      });
      await boot();
      record(2);
      await enrolled();
      repository.rejectUpload(_invalidToken);
      repository.succeed();
      await fire();
      expect(repository.calls, hasLength(1), reason: 'enrolled again');
      expect(enrollment.deviceToken, 'izd_token1');
      expect(nextDelay(), MonitoringTelemetrySink.firstUploadDelay);

      repository.acceptUpload();
      await fire();
      expect(repository.uploads.last.token, 'izd_token1');
      expect(seqs(repository.uploads.last.dto).first, 1, reason: 'from where it was');
    });

    test('logging out stops the uploads; the events wait', () async {
      await boot();
      await enrolled();
      enrollment.stop();
      expect(timers.active, isEmpty);
      record(3);
      expect(sink.status.value.running, isFalse);
      expect(sink.backlog(), 3);
    });
  });

  group('charges', () {
    test('nothing is uploaded while a card charge is on its way', () async {
      await boot();
      record(5);
      await enrolled();
      charging = true;
      await fire();
      expect(repository.uploads, isEmpty);
      expect(nextDelay(), MonitoringTelemetrySink.chargeRetry);
      expect(sink.status.value.waitingForCharge, isTrue);

      record(1, type: 'charge.result', level: TelemetryLevel.error);
      await fire();
      expect(repository.uploads, isEmpty, reason: 'an error does not jump the charge either');

      charging = false;
      repository.acceptUpload();
      await fire();
      expect(repository.uploads, hasLength(1));
      expect(sink.status.value.waitingForCharge, isFalse);
    });
  });

  group('sooner', () {
    Future<void> idle() async {
      await boot();
      await enrolled();
      repository.acceptUpload();
      await fire();
      expect(nextDelay(), MonitoringTelemetrySink.interval);
    }

    test('an error is uploaded within seconds, a burst in one batch', () async {
      await idle();
      record(1, level: TelemetryLevel.warning);
      expect(nextDelay(), MonitoringTelemetrySink.interval, reason: 'a warning waits');
      record(3, type: 'charge.result', level: TelemetryLevel.error);
      expect(nextDelay(), MonitoringTelemetrySink.urgentDelay);
      repository.acceptUpload();
      await fire();
      expect(repository.uploads.last.dto.events.length, 4);
    });

    test('50 pending events are uploaded within seconds', () async {
      await idle();
      record(MonitoringTelemetrySink.urgentPending - 1);
      expect(nextDelay(), MonitoringTelemetrySink.interval);
      record(1);
      expect(nextDelay(), MonitoringTelemetrySink.urgentDelay);
    });

    test('not while failing: the backoff decides', () async {
      await boot();
      record(1);
      await enrolled();
      repository.rejectUpload(const MonitoringException('unreachable'));
      await fire();
      record(1, level: TelemetryLevel.error);
      expect(nextDelay(), MonitoringTelemetrySink.interval);
    });
  });

  group('across reloads', () {
    test('what was not uploaded is still pending after a reload', () async {
      await boot();
      record(4);
      await enrolled();
      repository.rejectUpload(const MonitoringException('unreachable'));
      await fire();
      final stream = sink.state!.stream;
      final pending = sink.backlog();
      await buffer.flush();
      sink.stop();

      await boot();
      expect(sink.state!.stream, stream);
      expect(sink.backlog(), pending);
      record(1);
      expect(buffer.events.last.seq, buffer.events[buffer.length - 2].seq + 1,
          reason: 'seq goes on');
      sink.start();
      repository.acceptUpload();
      await fire();
      expect(seqs(repository.uploads.last.dto).first, 1);
      expect(sink.state!.ackSeq, buffer.lastSeq);
    });

    test('acknowledged events stay acknowledged after a reload', () async {
      await boot();
      record(3);
      await enrolled();
      repository.acceptUpload();
      await fire();
      sink.stop();

      await boot();
      record(2);
      sink.start();
      repository.acceptUpload();
      await fire();
      expect(seqs(repository.uploads.last.dto), [5, 6]);
    });

    test('a cleared buffer starts a new stream from seq 1', () async {
      streamStore.saved =
          const EventStreamState(stream: 'old-stream', ackSeq: 40, deviceId: 'dev9').encode();
      await boot();
      expect(sink.state!.stream, isNot('old-stream'));
      expect(sink.state!.ackSeq, 0);
      record(2);
      await enrolled();
      repository.acceptUpload();
      await fire();
      final dto = repository.uploads.single.dto;
      expect(dto.stream, sink.state!.stream);
      expect(seqs(dto), [1, 2, 3]);
      final note = dto.events.last;
      expect(note.type, 'telemetry.stream_started');
      expect(note.data, containsPair('reason', 'restarted'));
      expect(note.data, containsPair('previousAckSeq', 40));
      expect(EventStreamState.tryDecode(streamStore.saved)!.stream, dto.stream);
    });

    test('a buffer that lost what was acknowledged (seq restarted) starts a new stream',
        () async {
      bufferStore.saved = [
        for (var seq = 1; seq <= 5; seq++)
          '{"seq":$seq,"ts":"2026-10-12T09:00:00.000","upMs":0,"type":"e","level":"info"}'
      ];
      streamStore.saved =
          const EventStreamState(stream: 'old-stream', ackSeq: 12, deviceId: 'dev9').encode();
      await boot();
      expect(sink.state!.stream, isNot('old-stream'));
      expect(sink.backlog(), 5, reason: 'all of them, under the new stream');
    });

    test('the same buffer keeps its stream', () async {
      bufferStore.saved = [
        for (var seq = 1; seq <= 5; seq++)
          '{"seq":$seq,"ts":"2026-10-12T09:00:00.000","upMs":0,"type":"e","level":"info"}'
      ];
      streamStore.saved =
          const EventStreamState(stream: 'kept-stream', ackSeq: 5, deviceId: 'dev9').encode();
      await boot();
      expect(sink.state!.stream, 'kept-stream');
      expect(sink.backlog(), 0);
    });

    test('events numbered by an older build (seq per session) are never sent', () async {
      bufferStore.saved = [
        for (final seq in [1, 2, 3, 1, 2])
          '{"seq":$seq,"ts":"2026-10-12T09:00:00.000","upMs":0,"type":"old","level":"info"}'
      ];
      await boot();
      expect(sink.backlog(), 2, reason: 'only the newest run');
      record(1);
      expect(buffer.events.last.seq, 4, reason: 'numbered after the highest seq kept');
      await enrolled();
      repository.acceptUpload();
      await fire();
      expect(seqs(repository.uploads.single.dto), [1, 2, 4, 5]);
    });

    test('the service holding more of the stream than was sent starts a new one', () async {
      await boot();
      record(3);
      await enrolled();
      repository.answerUpload((dto) => MonitoringEventsResponse(ackSeq: 900, stream: dto.stream));
      await fire();
      final first = repository.uploads.single.dto;
      expect(sink.state!.stream, isNot(first.stream));
      expect(sink.state!.ackSeq, 0, reason: 'the same events, pending again');
      expect(nextDelay(), MonitoringTelemetrySink.drainDelay);

      repository.acceptUpload();
      await fire();
      final second = repository.uploads.last.dto;
      expect(second.stream, sink.state!.stream);
      expect(seqs(second).take(4), [1, 2, 3, 4]);
      expect(second.events.last.data, containsPair('reason', 'server_ahead'));
    });
  });

  group('overflow', () {
    test('events the buffer let go before the upload are counted and reported', () async {
      streamStore.saved =
          const EventStreamState(stream: 'kept-stream', ackSeq: 0, deviceId: 'dev9').encode();
      await boot(capacity: 10);
      record(25);
      expect(sink.backlog(), 10);
      await enrolled();
      repository.acceptUpload();
      await fire();

      final dropped = recorded('telemetry.dropped').single;
      expect(dropped.level, TelemetryLevel.warning);
      // 1-15 never made it; the report itself pushed 16 out.
      expect(dropped.data, containsPair('count', 16));
      expect(dropped.data, containsPair('fromSeq', 1));
      expect(dropped.data, containsPair('toSeq', 16));
      expect(dropped.data, containsPair('reason', 'overflow'));
      final sent = repository.uploads.single.dto;
      expect(seqs(sent), List.generate(10, (i) => i + 17));
      expect(sent.events.last.type, 'telemetry.dropped');
      expect(sink.status.value.dropped, 16);
      expect(sink.backlog(), 0);
    });

    test('reported once: the next upload finds nothing missing', () async {
      streamStore.saved =
          const EventStreamState(stream: 'kept-stream', ackSeq: 0, deviceId: 'dev9').encode();
      await boot(capacity: 10);
      record(12);
      await enrolled();
      repository.acceptUpload();
      await fire();
      record(3);
      repository.acceptUpload();
      await fire();
      expect(recorded('telemetry.dropped'), hasLength(1));
      expect(seqs(repository.uploads.last.dto), [14, 15, 16]);
    });

    test('a new stream starts at the oldest event kept: what came before is not lost', () async {
      // Left by a build that did not upload: no place stored.
      bufferStore.saved = [
        for (var seq = 16; seq <= 25; seq++)
          '{"seq":$seq,"ts":"2026-10-12T09:00:00.000","upMs":0,"type":"e","level":"info"}'
      ];
      await boot(capacity: 10);
      expect(sink.state!.ackSeq, 15);
      expect(sink.backlog(), 10);
      await enrolled();
      repository.acceptUpload();
      await fire();
      // Only what the full buffer let go to keep the stream note and the
      // report itself: 1-15 were never part of the stream.
      final dropped = recorded('telemetry.dropped').single;
      expect(dropped.data, containsPair('fromSeq', 16));
      expect(dropped.data, containsPair('count', 2));
      expect(seqs(repository.uploads.single.dto).first, 18);
    });
  });

  group('devices', () {
    test('events recorded for another device are not uploaded with this one', () async {
      streamStore.saved =
          const EventStreamState(stream: 'kept-stream', ackSeq: 0, deviceId: 'devOther').encode();
      await boot();
      record(4);
      await enrolled();
      repository.acceptUpload();
      await fire();
      final sent = repository.uploads.single.dto;
      expect(sent.events.map((e) => e.type), ['telemetry.dropped']);
      expect(sent.events.single.data, {'count': 4, 'reason': 'device_changed'});
      expect(sink.state!.deviceId, 'dev9');
    });

    test('the first device the upload sees is adopted', () async {
      await boot();
      record(2);
      await enrolled();
      repository.acceptUpload();
      await fire();
      expect(sink.state!.deviceId, 'dev9');
      expect(repository.uploads.single.dto.events, hasLength(3));
    });
  });

  group('pendingIn and baseFor', () {
    TelemetryEvent e(int seq) =>
        TelemetryEvent(seq: seq, ts: DateTime(2026), upMs: 0, type: 'e', level: TelemetryLevel.info);

    test('the newest increasing run above the acknowledged seq', () {
      final events = [for (final s in [5, 6, 1, 2, 3, 4]) e(s)];
      expect(MonitoringTelemetrySink.pendingIn(events, 0).map((x) => x.seq), [1, 2, 3, 4]);
      expect(MonitoringTelemetrySink.pendingIn(events, 2).map((x) => x.seq), [3, 4]);
      expect(MonitoringTelemetrySink.pendingIn(events, 4), isEmpty);
      expect(MonitoringTelemetrySink.pendingIn([e(0)], 0), isEmpty, reason: 'seq 0 is never sent');
      expect(MonitoringTelemetrySink.baseFor(events), 0);
      expect(MonitoringTelemetrySink.baseFor([e(16), e(17)]), 15);
      expect(MonitoringTelemetrySink.baseFor(const []), 0);
    });
  });

  group('EventStreamState', () {
    test('survives encoding and refuses anything else', () {
      const state = EventStreamState(stream: 's1', ackSeq: 12, deviceId: 'dev9');
      final back = EventStreamState.tryDecode(state.encode())!;
      expect((back.stream, back.ackSeq, back.deviceId), ('s1', 12, 'dev9'));
      expect(EventStreamState.tryDecode('{nope'), isNull);
      expect(EventStreamState.tryDecode('{"stream":"s","ackSeq":-1}'), isNull);
      expect(EventStreamState.tryDecode(null), isNull);
    });
  });
}
