import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/monitoring_enrollment.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mocks.dart';

/// The monitoring service, answering what each test queues.
class FakeMonitoringRepository extends MonitoringRepository {
  final List<MonitoringEnrollmentDto> calls = [];
  final List<Future<MonitoringEnrollment> Function()> replies = [];
  int _issued = 0;

  void succeed() => replies.add(() async {
        _issued++;
        return MonitoringEnrollment(
            deviceId: 'dev$_issued', applianceId: 'app1', deviceToken: 'izd_token$_issued');
      });

  void failWith(Object error) => replies.add(() async => throw error);

  @override
  Future<MonitoringEnrollment> enroll(MonitoringEnrollmentDto dto) {
    calls.add(dto);
    if (replies.isEmpty) throw StateError('unexpected enrollment');
    return replies.removeAt(0)();
  }
}

class FakeTimer implements Timer {
  final Duration delay;
  final void Function() callback;
  bool active = true;

  FakeTimer(this.delay, this.callback);

  @override
  void cancel() => active = false;

  @override
  bool get isActive => active;

  @override
  int get tick => 0;
}

/// Timers the test fires by hand.
class FakeTimers {
  final List<FakeTimer> all = [];

  Timer call(Duration delay, void Function() callback) {
    final timer = FakeTimer(delay, callback);
    all.add(timer);
    return timer;
  }

  List<FakeTimer> get active => all.where((t) => t.active).toList();

  /// Fires the only pending timer and lets its attempt finish.
  Future<Duration> fire() async {
    final pending = active;
    expect(pending, hasLength(1), reason: 'exactly one scheduled attempt');
    final timer = pending.single..active = false;
    timer.callback();
    await pumpEventQueue();
    return timer.delay;
  }
}

class _Auth extends AuthBloc {
  _Auth() : super(MockAuthRepository(), MockBusinessRepository());

  void login({int contribuyente = 5, int device = 7}) => emit(state.copyWith(
        status: AuthStatus.okAuth,
        currentContribuyente: Contribuyente(
            id: contribuyente,
            nombre: 'Gasaje',
            config: {'paisId': 'CO'},
            actividadesEconomicas: null,
            autorizadosAPI: null),
        currentSucursal: Sucursal(id: 1, nombre: 'Casa Matriz'),
        currentDevice: Device.fromJson({
          'id': device,
          'sucursal': 1,
          'nombre': 'KIOSKO-01',
          'caja': 1,
          'config': <String, dynamic>{},
        }),
      ));

  void loggedOut() => emit(state.resetState());

  void passing(AuthStatus status) => emit(state.copyWith(status: status));
}

const _context = MonitoringContext(
    contribuyenteId: 5,
    dispositivoId: 7,
    deviceName: 'KIOSKO-01',
    contribuyenteNombre: 'Gasaje',
    sucursalNombre: 'Casa Matriz',
    pais: 'CO');

const _app = MonitoringApp(version: '2.3.1+45', flavor: 'izify', platform: 'web');

void main() {
  late FakeMonitoringRepository repository;
  late FakeTimers timers;
  late MonitoringService service;
  final now = DateTime.utc(2026, 10, 12, 14);

  MonitoringService build() => MonitoringService(
      repository: repository,
      store: MonitoringStore(),
      appInfo: () async => _app,
      timer: timers.call,
      now: () => now);

  List<TelemetryEvent> events(String type) =>
      Telemetry.recent().where((e) => e.type == type).toList();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Telemetry.install(Telemetry());
    repository = FakeMonitoringRepository();
    timers = FakeTimers();
    service = build();
  });

  group('enrollment', () {
    test('without a token: enrolls shortly after the login and keeps the token', () async {
      repository.succeed();
      await service.start(_context);

      expect(service.status.value.state, MonitoringState.pending);
      expect(repository.calls, isEmpty, reason: 'the login requests go first');
      expect(await timers.fire(), MonitoringService.firstAttemptDelay);

      final body = repository.calls.single.toJson();
      expect(body['schema'], 1);
      expect(body['kind'], 'kiosk');
      expect(MonitoringStore.isUuidV4(body['installationId']), isTrue);
      expect(body['app'], {'version': '2.3.1+45', 'flavor': 'izify', 'platform': 'web'});
      expect(body['deviceName'], 'KIOSKO-01');
      expect(body['business'],
          {'contribuyenteNombre': 'Gasaje', 'sucursalNombre': 'Casa Matriz', 'pais': 'CO'});

      final status = service.status.value;
      expect(status.state, MonitoringState.enrolled);
      expect(status.deviceId, 'dev1');
      expect(status.applianceId, 'app1');
      expect(service.deviceToken, 'izd_token1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('monitoring.deviceToken'), 'izd_token1');
      expect(prefs.getString('monitoring.installationId'), body['installationId']);

      final enrolled = events('monitoring.enrolled').single;
      expect(enrolled.data['deviceId'], 'dev1');
      expect(enrolled.data['reenroll'], false);
      expect(Telemetry.instance.context['monitoring.deviceId'], 'dev1');
      expect(timers.active, isEmpty);
    });

    test('a token of the same contribuyente and device is used as is', () async {
      SharedPreferences.setMockInitialValues({
        'monitoring.installationId': MonitoringStore.newUuidV4(),
        'monitoring.deviceToken': 'izd_saved',
        'monitoring.deviceId': 'dev9',
        'monitoring.contribuyenteId': 5,
        'monitoring.dispositivoId': 7,
      });
      await service.start(_context);

      expect(repository.calls, isEmpty);
      expect(timers.all, isEmpty);
      expect(service.status.value.state, MonitoringState.enrolled);
      expect(service.status.value.deviceId, 'dev9');
      expect(service.deviceToken, 'izd_saved');
    });

    test('a token of another contribuyente is dropped and the kiosk enrolls again', () async {
      final installation = MonitoringStore.newUuidV4();
      SharedPreferences.setMockInitialValues({
        'monitoring.installationId': installation,
        'monitoring.deviceToken': 'izd_other',
        'monitoring.contribuyenteId': 99,
        'monitoring.dispositivoId': 7,
      });
      repository.succeed();
      await service.start(_context);
      expect(service.deviceToken, isNull);
      await timers.fire();

      expect(repository.calls.single.installationId, installation,
          reason: 'same installation, new contribuyente');
      final saved = (await MonitoringStore().enrollment())!;
      expect(saved.deviceToken, 'izd_token1');
      expect(saved.isFor(contribuyenteId: 5, dispositivoId: 7), isTrue);
    });

    test('starting again with the same identity does not enroll twice', () async {
      repository.succeed();
      await service.start(_context);
      await service.start(_context);
      await timers.fire();
      await service.start(_context);
      expect(repository.calls, hasLength(1));
      expect(timers.active, isEmpty);
    });
  });

  group('failures', () {
    test('back off from 30 s to 30 min, and recover', () async {
      for (var i = 0; i < 8; i++) {
        repository.failWith(const MonitoringException('http_503', statusCode: 503, code: 'down'));
      }
      repository.succeed();
      await service.start(_context);
      await timers.fire(); // first attempt

      final delays = <int>[];
      for (var i = 0; i < 8; i++) {
        final status = service.status.value;
        if (i < 7) {
          expect(status.state, MonitoringState.error);
          expect(status.lastCause, 'http_503');
        }
        delays.add((await timers.fire()).inSeconds);
      }
      expect(delays, [30, 60, 120, 240, 480, 960, 1800, 1800]);
      expect(service.status.value.state, MonitoringState.enrolled);

      final failed = events('monitoring.enroll_failed');
      expect(failed, hasLength(8));
      final first = failed.last; // recent() is newest first
      expect(first.level, TelemetryLevel.warning);
      expect(first.data['cause'], 'http_503');
      expect(first.data['code'], 'down');
      expect(first.data['attempt'], 1);
      expect(first.data['retryInSec'], 30);
      expect(events('monitoring.enrolled').single.data['attempts'], 9);
    });

    test('the error status says when the next attempt is', () async {
      repository.failWith(const MonitoringException('unreachable'));
      await service.start(_context);
      await timers.fire();
      final status = service.status.value;
      expect(status.state, MonitoringState.error);
      expect(status.failures, 1);
      expect(status.nextAttemptAt, now.add(const Duration(seconds: 30)));
      expect(status.enrolling, isFalse);
    });

    test('an unexpected error never escapes and is retried', () async {
      repository.failWith(StateError('boom'));
      await service.start(_context);
      await timers.fire();
      expect(service.status.value.lastCause, 'error');
      expect(timers.active.single.delay, const Duration(seconds: 30));
    });

    test('backoff is capped', () {
      expect(MonitoringService.backoffFor(1), const Duration(seconds: 30));
      expect(MonitoringService.backoffFor(2), const Duration(minutes: 1));
      expect(MonitoringService.backoffFor(7), const Duration(minutes: 30));
      expect(MonitoringService.backoffFor(1000), const Duration(minutes: 30));
    });
  });

  group('stop and retry', () {
    test('stop cancels the scheduled attempt', () async {
      await service.start(_context);
      service.stop();
      expect(timers.active, isEmpty);
      expect(service.status.value.state, MonitoringState.stopped);
      expect(repository.calls, isEmpty);
    });

    test('an answer that arrives after stop is ignored', () async {
      final reply = Completer<MonitoringEnrollment>();
      repository.replies.add(() => reply.future);
      await service.start(_context);
      timers.active.single.callback();
      await pumpEventQueue();
      expect(service.status.value.enrolling, isTrue);

      service.stop();
      reply.complete(const MonitoringEnrollment(
          deviceId: 'late', applianceId: 'a', deviceToken: 'izd_late'));
      await pumpEventQueue();

      expect(service.status.value.state, MonitoringState.stopped);
      expect(service.deviceToken, isNull);
      expect(await MonitoringStore().enrollment(), isNull);
      expect(events('monitoring.enrolled'), isEmpty);
    });

    test('a manual retry enrolls now, even when already enrolled', () async {
      repository
        ..succeed()
        ..succeed();
      await service.start(_context);
      await timers.fire();
      expect(service.deviceToken, 'izd_token1');

      await service.retryNow();
      expect(repository.calls, hasLength(2));
      expect(service.deviceToken, 'izd_token2');
      final second = events('monitoring.enrolled').first;
      expect(second.data['reenroll'], true);
      expect(second.data['manual'], true);
    });

    test('a manual retry skips the backoff wait', () async {
      repository
        ..failWith(const MonitoringException('timeout'))
        ..succeed();
      await service.start(_context);
      await timers.fire();
      expect(timers.active.single.delay, const Duration(seconds: 30));

      await service.retryNow();
      expect(timers.active, isEmpty);
      expect(service.status.value.state, MonitoringState.enrolled);
    });

    test('a manual retry does nothing while stopped', () async {
      await service.retryNow();
      expect(repository.calls, isEmpty);
    });

    test('a rejected token is forgotten and the kiosk enrolls again', () async {
      repository
        ..succeed()
        ..succeed();
      await service.start(_context);
      await timers.fire();

      await service.onTokenRejected();
      expect(repository.calls, hasLength(2));
      expect(service.deviceToken, 'izd_token2');
      expect((await MonitoringStore().enrollment())!.deviceToken, 'izd_token2');
    });
  });

  group('followAuth', () {
    test('starts when logged in with a device and stops on logout', () async {
      final auth = _Auth();
      addTearDown(auth.close);
      repository
        ..succeed()
        ..succeed();
      service.followAuth(auth);
      expect(service.status.value.state, MonitoringState.stopped);

      auth.login();
      await pumpEventQueue();
      await timers.fire();
      expect(service.status.value.state, MonitoringState.enrolled);
      expect(repository.calls.single.deviceName, 'KIOSKO-01');

      // The logout first shows the splash: nothing changes yet.
      auth.passing(AuthStatus.init);
      await pumpEventQueue();
      expect(service.status.value.state, MonitoringState.enrolled);

      auth.loggedOut();
      await pumpEventQueue();
      expect(service.status.value.state, MonitoringState.stopped);
      expect(service.deviceToken, isNull);

      // Back to another contribuyente: a new enrollment.
      auth.login(contribuyente: 6);
      await pumpEventQueue();
      await timers.fire();
      expect(repository.calls, hasLength(2));
      expect((await MonitoringStore().enrollment())!.contribuyenteId, 6);
    });

    test('the context carries the names the console shows', () {
      final auth = _Auth()..login();
      addTearDown(auth.close);
      final context = MonitoringContext.fromAuth(auth.state)!;
      expect(context.contribuyenteId, 5);
      expect(context.dispositivoId, 7);
      expect(context.deviceName, 'KIOSKO-01');
      expect(context.contribuyenteNombre, 'Gasaje');
      expect(context.sucursalNombre, 'Casa Matriz');
      expect(context.pais, 'CO');
      expect(MonitoringContext.fromAuth(AuthState.init()), isNull);
    });
  });

  test('the device token never reaches telemetry', () async {
    repository.succeed();
    await service.start(_context);
    await timers.fire();
    for (final e in Telemetry.recent()) {
      expect(e.toJson().toString(), isNot(contains('izd_')), reason: e.type);
    }
    expect(Telemetry.instance.context.toString(), isNot(contains('izd_')));
  });
}
