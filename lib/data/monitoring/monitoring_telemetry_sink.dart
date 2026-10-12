import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_backoff.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/telemetry/platform_signals.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_buffer.dart';
import 'package:izi_kiosco/domain/dto/monitoring_events_dto.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the event upload is: the [stream] its events' `seq` belong to,
/// and up to which `seq` the service has them ([ackSeq]).
class EventStreamState {
  final String stream;

  /// Every event of [stream] up to this `seq` was acknowledged by the
  /// service, or is lost (see [MonitoringTelemetrySink]): none is pending.
  final int ackSeq;

  /// The monitoring device the events go to. Events recorded for one device
  /// are never uploaded with the token of another.
  final String? deviceId;

  const EventStreamState({required this.stream, required this.ackSeq, this.deviceId});

  EventStreamState copyWith({int? ackSeq, String? deviceId}) => EventStreamState(
      stream: stream, ackSeq: ackSeq ?? this.ackSeq, deviceId: deviceId ?? this.deviceId);

  String encode() => jsonEncode({
        'stream': stream,
        'ackSeq': ackSeq,
        if (deviceId != null) 'deviceId': deviceId,
      });

  /// Null for anything that is not a state this class wrote.
  static EventStreamState? tryDecode(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json);
      if (map is! Map) return null;
      final stream = map['stream'];
      final ack = map['ackSeq'];
      final deviceId = map['deviceId'];
      if (stream is! String || stream.isEmpty || ack is! int || ack < 0) return null;
      return EventStreamState(
          stream: stream, ackSeq: ack, deviceId: deviceId is String ? deviceId : null);
    } catch (_) {
      return null;
    }
  }
}

/// Where the upload's place survives a reload. On web SharedPreferences is
/// the browser's localStorage, like the buffer it points into.
abstract class EventStreamStore {
  Future<String?> load();
  Future<void> save(String json);
}

class PrefsEventStreamStore implements EventStreamStore {
  static const String key = 'monitoring.events';

  @override
  Future<String?> load() async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> save(String json) async =>
      (await SharedPreferences.getInstance()).setString(key, json);
}

class MemoryEventStreamStore implements EventStreamStore {
  String? saved;

  @override
  Future<String?> load() async => saved;

  @override
  Future<void> save(String json) async => saved = json;
}

/// What the diagnostics dialog shows about the event upload.
class EventUploadStatus {
  /// The kiosk is enrolled and uploading.
  final bool running;
  final String? stream;
  final int? ackSeq;

  /// Events still to upload.
  final int? pending;

  /// Events lost before they could be uploaded, in this session.
  final int dropped;
  final DateTime? lastOkAt;
  final DateTime? nextAt;

  /// Why the last upload failed, while they keep failing.
  final String? lastCause;
  final int failures;

  /// The last attempt found a card charge on its way and waited.
  final bool waitingForCharge;

  const EventUploadStatus(
      {required this.running,
      this.stream,
      this.ackSeq,
      this.pending,
      this.dropped = 0,
      this.lastOkAt,
      this.nextAt,
      this.lastCause,
      this.failures = 0,
      this.waitingForCharge = false});

  static const EventUploadStatus stopped = EventUploadStatus(running: false);

  Map<String, Object?> toJson() => {
        'running': running,
        'stream': stream,
        'ackSeq': ackSeq,
        'pending': pending,
        'dropped': dropped,
        'lastOkAt': lastOkAt?.toIso8601String(),
        'nextAt': nextAt?.toIso8601String(),
        'lastCause': lastCause,
        'failures': failures,
        'waitingForCharge': waitingForCharge,
      };
}

/// Uploads this kiosk's events to the monitoring service (contracts §5),
/// next to what goes to Sentry: Sentry keeps its own budget, this sends
/// every event.
///
/// Nothing is kept here but a place: the events to upload are the ones in
/// the [TelemetryBuffer] with a `seq` above [EventStreamState.ackSeq] of
/// the current stream. Both live in the browser's storage, so a reload or
/// an outage loses nothing the buffer still holds. Only the newest
/// increasing run of the buffer counts: events numbered by an older build,
/// which started over on every reload, are never sent.
///
/// A new stream starts, and `seq` with it, when the place is missing (first
/// run, or the storage was cleared) or the buffer holds less than was
/// acknowledged (the stored events were lost, so `seq` started over); also
/// when the service holds more of the stream than the kiosk ever sent.
///
/// Every [interval] while the kiosk is enrolled ([MonitoringService]) it
/// posts up to [MonitoringEventsDto.maxEvents] events (and [maxBatchBytes]),
/// sooner ([urgentDelay]) when an error is recorded or [urgentPending]
/// events are waiting, and right away again while more are waiting. Never
/// while a card charge is on its way ([KioskActivity.chargeInProgress]):
/// it waits [chargeRetry] and looks again.
///
/// The buffer keeps [TelemetryBuffer.capacity] events: when more were
/// recorded than uploaded, the oldest are lost. They are counted and
/// reported (`telemetry.dropped`), and the heartbeat carries how many are
/// waiting (`state.telemetryBacklog`).
///
/// Fail-safe like the heartbeat: never awaited by the UI, never throws, and
/// told of each event without doing anything there but scheduling.
class MonitoringTelemetrySink implements TelemetrySink {
  static const Duration interval = Duration(seconds: 30);

  /// After enrolling: after the first heartbeat.
  static const Duration firstUploadDelay = Duration(seconds: 10);

  /// After an error, or once [urgentPending] events wait: a burst of events
  /// goes in one batch.
  static const Duration urgentDelay = Duration(seconds: 3);
  static const int urgentPending = 50;

  /// Between batches while more events wait.
  static const Duration drainDelay = Duration(seconds: 2);

  /// While a card charge is on its way.
  static const Duration chargeRetry = Duration(seconds: 10);
  static const Duration maxBackoff = Duration(minutes: 5);

  /// Under the 256 KB the gateway and the service take, envelope included.
  static const int maxBatchBytes = 192 * 1024;

  /// A last guard over the repository's own timeouts, as in the heartbeat.
  static const Duration attemptTimeout = Duration(seconds: 45);
  static const Duration restoreTimeout = Duration(seconds: 5);

  /// The share of each backoff wait that is random, either way.
  static const double jitter = MonitoringBackoff.jitter;

  /// Failures in a row recorded in detail; after that, one in [logEvery].
  static const int detailedFailures = 3;
  static const int logEvery = 10;

  final MonitoringService _enrollment;
  final MonitoringRepository? _injectedRepository;
  final TelemetryBuffer Function() _buffer;
  final EventStreamStore _store;
  final bool Function() _chargeInProgress;
  final bool? Function() _online;
  final MonitoringTimerFactory _timer;
  final DateTime Function() _now;
  final Random _random;
  final ValueNotifier<EventUploadStatus> _status = ValueNotifier(EventUploadStatus.stopped);

  // Created on first use: the HTTP client reads the API URL from the `.env`.
  late final MonitoringRepository _repository =
      _injectedRepository ?? MonitoringRepositoryHttp();

  Future<void>? _restoring;
  EventStreamState? _state;

  /// Why a stream started, recorded once the kiosk can record (see
  /// [restore]).
  final List<Map<String, Object?>> _streamNotes = [];

  bool _started = false;
  bool _inFlight = false;
  String? _token;
  Timer? _next;
  DateTime? _nextAt;
  int _failures = 0;
  int _maxBatch = MonitoringEventsDto.maxEvents;
  int _dropped = 0;
  DateTime? _lastOkAt;
  String? _lastCause;
  bool _waitingForCharge = false;

  MonitoringTelemetrySink(
      {required MonitoringService enrollment,
      MonitoringRepository? repository,
      TelemetryBuffer? buffer,
      EventStreamStore? store,
      bool Function()? chargeInProgress,
      bool? Function()? online,
      MonitoringTimerFactory? timer,
      DateTime Function()? now,
      Random? random})
      : _enrollment = enrollment,
        _injectedRepository = repository,
        _buffer = buffer != null ? (() => buffer) : (() => Telemetry.instance.buffer),
        _store = store ?? MemoryEventStreamStore(),
        _chargeInProgress = chargeInProgress ?? (() => KioskActivity.instance.chargeInProgress),
        _online = online ?? currentOnline,
        _timer = timer ?? Timer.new,
        _now = now ?? DateTime.now,
        _random = random ?? Random();

  static MonitoringTelemetrySink? _instance;

  /// The upload installed at startup; null before (and in tests that do not
  /// install one).
  static MonitoringTelemetrySink? get instance => _instance;

  static void install(MonitoringTelemetrySink sink) => _instance = sink;

  ValueListenable<EventUploadStatus> get status => _status;

  EventStreamState? get state => _state;

  /// Events still to upload (`state.telemetryBacklog`); null until the
  /// place is loaded.
  int? backlog() {
    try {
      final state = _state;
      if (state == null) return null;
      return pendingIn(_buffer().events, state.ackSeq).length;
    } catch (_) {
      return null;
    }
  }

  /// The last event `seq` recorded (`lastEventSeq` of the heartbeat).
  int? lastEventSeq() {
    try {
      final seq = _buffer().lastSeq;
      return seq > 0 ? seq : null;
    } catch (_) {
      return null;
    }
  }

  /// Loads the place where the last session left it. Call it once the
  /// buffer is restored and before anything new is recorded: whether `seq`
  /// started over is judged against what the buffer brought back.
  Future<void> restore() => _restoring ??= _load();

  Future<void> _load() async {
    EventStreamState? saved;
    try {
      saved = EventStreamState.tryDecode(await _store.load());
    } catch (_) {}
    try {
      final buffer = _buffer();
      if (saved == null) {
        _startStream('new', base: baseFor(buffer.events));
      } else if (buffer.lastSeq < saved.ackSeq) {
        // The buffer lost events the service already has: what comes next
        // would repeat their numbers.
        _startStream('restarted',
            base: baseFor(buffer.events),
            deviceId: saved.deviceId,
            previousAckSeq: saved.ackSeq);
      } else {
        _state = saved;
      }
    } catch (_) {
      _state ??= EventStreamState(stream: MonitoringStore.newUuidV4(), ackSeq: 0);
    }
  }

  /// Uploads while the kiosk is enrolled, from now on. Once.
  void start() {
    if (_started) return;
    _started = true;
    _enrollment.status.addListener(_onEnrollment);
    _onEnrollment();
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _enrollment.status.removeListener(_onEnrollment);
    _token = null;
    _cancel();
    _set(EventUploadStatus.stopped);
  }

  void _onEnrollment() {
    try {
      final token = _enrollment.deviceToken;
      if (token == null) {
        // Logged out, or enrolling again: nothing to send with. The events
        // wait in the buffer.
        _token = null;
        _cancel();
        _publish(nextAt: null);
        return;
      }
      if (token == _token) return;
      _token = token;
      _failures = 0;
      _lastCause = null;
      _schedule(firstUploadDelay);
    } catch (_) {}
  }

  @override
  void onEvent(TelemetryEvent event, {required bool sendLog, required bool sendIssue}) {
    try {
      // Failing: the backoff decides, an error storm must not hammer the
      // service.
      if (!_started || _token == null || _inFlight || _failures > 0) return;
      if (event.level == TelemetryLevel.error || (backlog() ?? 0) >= urgentPending) {
        _soon();
      }
    } catch (_) {}
  }

  @override
  void setContext(Map<String, Object?> context) {}

  /// One upload now (also what the timer runs): one batch, then the next
  /// one is scheduled.
  Future<void> upload() async {
    final token = _enrollment.deviceToken;
    if (_inFlight || token == null) return;
    _inFlight = true;
    _cancel();
    Duration? next;
    try {
      await restore().timeout(restoreTimeout);
      if (_chargeInProgress()) {
        _waitingForCharge = true;
        next = chargeRetry;
        return;
      }
      _waitingForCharge = false;
      if (_online() == false) {
        // The browser knows it is offline: no request, no failure.
        _lastCause = 'offline';
        next = interval;
        return;
      }
      _reconcile();
      // What is acknowledged must survive a reload: the buffer saves later
      // by itself, and the events would come back without it.
      await _buffer().flush();
      final batch = _batch();
      if (batch.isEmpty || _chargeInProgress()) {
        _waitingForCharge = batch.isNotEmpty;
        next = batch.isEmpty ? interval : chargeRetry;
        return;
      }
      final state = _state!;
      final sentUpTo = batch.map((e) => e.seq).reduce(max);
      final response = await _repository
          .uploadEvents(
              MonitoringEventsDto(
                  installationId: await _enrollment.store.installationId(),
                  stream: state.stream,
                  events: batch),
              deviceToken: token)
          .timeout(attemptTimeout);
      if (response.stream != state.stream) {
        throw const MonitoringException('invalid_response');
      }
      if (response.ackSeq > sentUpTo) {
        // The service holds more of this stream than this kiosk ever sent
        // (a cloned PC writing to it, or a place restored from elsewhere):
        // start a stream of our own, with the same events pending.
        _startStream('server_ahead',
            base: state.ackSeq, deviceId: state.deviceId, previousAckSeq: response.ackSeq);
      } else if (response.ackSeq <= state.ackSeq) {
        // Nothing of the batch was kept: sending it again right away would
        // only repeat this.
        throw const MonitoringException('not_acknowledged');
      } else {
        _setState(state.copyWith(ackSeq: response.ackSeq));
      }
      _enrollment.onTokenAccepted(token);
      if (_failures > 0) {
        Telemetry.event('monitoring.events_recovered', data: {'failures': _failures});
      }
      _failures = 0;
      _lastCause = null;
      _lastOkAt = _now();
      _maxBatch = min(_maxBatch * 2, MonitoringEventsDto.maxEvents);
      next = (backlog() ?? 0) > 0 ? drainDelay : interval;
    } catch (error) {
      final cause = switch (error) {
        MonitoringException e => e.cause,
        TimeoutException _ => 'timeout',
        _ => 'error',
      };
      _lastCause = cause;
      if (error is MonitoringException && error.isTooLarge && _maxBatch > 1) {
        // Smaller batches, right away: the events are fine, the batch was not.
        _maxBatch = max(_maxBatch ~/ 2, 1);
        next = drainDelay;
      } else {
        _failures++;
        next = retryDelayFor(_failures, _random.nextDouble());
        if (error is MonitoringException && error.isTokenInvalid) {
          Telemetry.event('monitoring.token_rejected',
              level: TelemetryLevel.warning, data: {'source': 'events'});
          // Forgets the token and enrolls again; uploading resumes with the
          // new one, from where it was.
          unawaited(_enrollment.onTokenRejected(token));
        } else if (_failures <= detailedFailures || _failures % logEvery == 0) {
          Telemetry.event('monitoring.events_failed',
              level: TelemetryLevel.warning,
              data: {
                'cause': cause,
                if (error is MonitoringException && error.code != null) 'code': error.code,
                'failures': _failures,
                'retryInSec': next.inSeconds,
              });
        }
      }
    } finally {
      _inFlight = false;
      if (_started) {
        final current = _enrollment.deviceToken;
        if (current == token) {
          _schedule(next ?? interval);
        } else if (current != null) {
          // Enrolled again while this one was on its way: start over with
          // the new token.
          _token = current;
          _failures = 0;
          _schedule(firstUploadDelay);
        } else {
          _publish(nextAt: null);
        }
      }
    }
  }

  /// Brings the place up to date with the buffer before a batch: a stream
  /// that started over, a change of device, events lost to the buffer's
  /// capacity. Records what it finds; never called while an event is being
  /// recorded.
  void _reconcile() {
    final buffer = _buffer();
    var state = _state!;
    if (buffer.lastSeq < state.ackSeq) {
      // A buffer swapped or emptied while running.
      _startStream('restarted',
          base: baseFor(buffer.events), deviceId: state.deviceId, previousAckSeq: state.ackSeq);
      state = _state!;
    }

    final deviceId = _enrollment.status.value.deviceId;
    if (deviceId != null && deviceId != state.deviceId) {
      if (state.deviceId != null) {
        // Enrolled as another device (another contribuyente): what was
        // recorded for the previous one is not this one's to see.
        final skipped = pendingIn(buffer.events, state.ackSeq).length;
        _setState(state.copyWith(ackSeq: buffer.lastSeq, deviceId: deviceId));
        if (skipped > 0) {
          _dropped += skipped;
          Telemetry.event('telemetry.dropped',
              level: TelemetryLevel.warning,
              data: {'count': skipped, 'reason': 'device_changed'});
        }
      } else {
        _setState(state.copyWith(deviceId: deviceId));
      }
      state = _state!;
    }

    while (_streamNotes.isNotEmpty) {
      Telemetry.event('telemetry.stream_started', data: _streamNotes.removeAt(0));
    }

    state = _state!;
    final events = buffer.events;
    final pending = pendingIn(events, state.ackSeq);
    if (pending.isEmpty) return;
    final first = pending.first.seq;
    if (first <= state.ackSeq + 1) return;
    // Events after the acknowledged ones are missing: the buffer let them
    // go to keep its capacity before they were uploaded.
    var count = first - state.ackSeq - 1;
    var upTo = first - 1;
    if (buffer.isFull && events.first.seq == first) {
      // Recording the report pushes the oldest pending event out too.
      count++;
      upTo = first;
    }
    final from = state.ackSeq + 1;
    _setState(state.copyWith(ackSeq: upTo));
    _dropped += count;
    Telemetry.event('telemetry.dropped', level: TelemetryLevel.warning, data: {
      'count': count,
      'fromSeq': from,
      'toSeq': upTo,
      'reason': 'overflow',
      'capacity': buffer.capacity,
    });
  }

  /// The next batch: the oldest pending events, within [_maxBatch] and
  /// [maxBatchBytes]. An event too big on its own goes without its data.
  List<TelemetryEvent> _batch() {
    final pending = pendingIn(_buffer().events, _state!.ackSeq);
    final batch = <TelemetryEvent>[];
    var bytes = 0;
    for (final event in pending.take(_maxBatch)) {
      final size = utf8.encode(jsonEncode(MonitoringEventsDto.eventJson(event))).length + 1;
      if (size > maxBatchBytes) {
        if (batch.isNotEmpty) break;
        return [_withoutData(event, size)];
      }
      if (bytes + size > maxBatchBytes) break;
      batch.add(event);
      bytes += size;
    }
    return batch;
  }

  void _startStream(String reason,
      {required int base, String? deviceId, int? previousAckSeq}) {
    final stream = MonitoringStore.newUuidV4();
    _setState(EventStreamState(stream: stream, ackSeq: base, deviceId: deviceId));
    _streamNotes.add({
      'reason': reason,
      'stream': stream,
      'fromSeq': base + 1,
      if (previousAckSeq != null) 'previousAckSeq': previousAckSeq,
    });
  }

  void _setState(EventStreamState state) {
    _state = state;
    unawaited(_save(state));
  }

  Future<void> _save(EventStreamState state) async {
    try {
      await _store.save(state.encode());
    } catch (_) {
      // Storage full or blocked: the next session starts a new stream.
    }
  }

  /// The pending events of [events] (oldest first, as the buffer keeps
  /// them): the newest increasing run of `seq`, above [ackSeq].
  static List<TelemetryEvent> pendingIn(List<TelemetryEvent> events, int ackSeq) {
    var start = events.length;
    int? after;
    for (var i = events.length - 1; i >= 0; i--) {
      final seq = events[i].seq;
      if (seq <= ackSeq || (after != null && seq >= after)) break;
      after = seq;
      start = i;
    }
    return events.sublist(start);
  }

  /// Where a new stream starts: right before the newest increasing run of
  /// [events], so all of it is uploaded and nothing older is.
  static int baseFor(List<TelemetryEvent> events) {
    if (events.isEmpty) return 0;
    var first = events.last.seq;
    for (var i = events.length - 2; i >= 0; i--) {
      final seq = events[i].seq;
      if (seq >= first) break;
      first = seq;
    }
    return max(first - 1, 0);
  }

  static TelemetryEvent _withoutData(TelemetryEvent event, int bytes) => TelemetryEvent(
        seq: event.seq,
        ts: event.ts,
        upMs: event.upMs,
        type: event.type,
        level: event.level,
        chargeId: event.chargeId,
        reference: event.reference,
        data: {'truncated': true, 'bytes': bytes},
      );

  /// After [failures] in a row: [interval], then doubling up to
  /// [maxBackoff], each wait moved by up to [jitter] either way for [random]
  /// in [0, 1) (0.5 leaves it as is), and never out of that range
  /// ([MonitoringBackoff]).
  static Duration retryDelayFor(int failures, double random) => MonitoringBackoff.delay(
      first: interval, max: maxBackoff, failures: failures, random: random);

  /// Within [urgentDelay], unless something is due before.
  void _soon() {
    final due = _now().add(urgentDelay);
    final at = _nextAt;
    if (_next != null && at != null && !at.isAfter(due)) return;
    _schedule(urgentDelay);
  }

  void _schedule(Duration delay) {
    _cancel();
    _next = _timer(delay, () => unawaited(upload()));
    _nextAt = _now().add(delay);
    _publish(nextAt: _nextAt);
  }

  void _cancel() {
    _next?.cancel();
    _next = null;
    _nextAt = null;
  }

  void _publish({required DateTime? nextAt}) => _set(EventUploadStatus(
        running: _token != null,
        stream: _state?.stream,
        ackSeq: _state?.ackSeq,
        pending: backlog(),
        dropped: _dropped,
        lastOkAt: _lastOkAt,
        nextAt: nextAt,
        lastCause: _lastCause,
        failures: _failures,
        waitingForCharge: _waitingForCharge,
      ));

  void _set(EventUploadStatus status) {
    try {
      _status.value = status;
    } catch (_) {}
  }
}
