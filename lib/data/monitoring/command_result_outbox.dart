import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:izi_kiosco/data/monitoring/monitoring_backoff.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/dto/monitoring_command_result_dto.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the results not yet delivered are kept. Prefs in production.
abstract class CommandResultStore {
  Future<List<MonitoringCommandResultDto>> load();
  Future<void> save(List<MonitoringCommandResultDto> results);
}

class PrefsCommandResultStore implements CommandResultStore {
  static const String key = 'monitoring.commandResults';

  @override
  Future<List<MonitoringCommandResultDto>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(MonitoringCommandResultDto.fromStorage).whereType<MonitoringCommandResultDto>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<MonitoringCommandResultDto> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (results.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, jsonEncode([for (final r in results) r.toStorage()]));
      }
    } catch (_) {}
  }
}

class MemoryCommandResultStore implements CommandResultStore {
  List<MonitoringCommandResultDto> saved = [];

  @override
  Future<List<MonitoringCommandResultDto>> load() async => List.of(saved);

  @override
  Future<void> save(List<MonitoringCommandResultDto> results) async => saved = List.of(results);
}

/// Delivers the results of remote commands
/// (`POST /monitoreo/ingesta/comandos/:id/resultado`, contracts §6) and keeps
/// those not delivered yet, also across a reload (the one `reload_app`
/// causes, among others).
///
/// Each result goes with the device token current when it leaves: after a
/// `rotate_token` that is already the new one, as the contracts ask
/// (§12.5). A result the service will never take (the command is unknown
/// or no longer open, 404/409, or the body is refused) is dropped; one that
/// could not be delivered is retried with backoff ([retryDelay]: 10 s
/// doubling up to [maxBackoff], with jitter); a rejected device token is
/// handed to the enrollment, and sending resumes with the next token. After
/// [maxAge] a result is dropped: the service expired its command long ago.
class CommandResultOutbox {
  static const int capacity = 20;
  static const Duration firstRetry = Duration(seconds: 10);
  static const Duration maxBackoff = Duration(minutes: 5);
  static const Duration maxAge = Duration(hours: 1);
  static const Duration attemptTimeout = Duration(seconds: 30);

  final MonitoringService _enrollment;
  final MonitoringRepository? _injectedRepository;
  final CommandResultStore _store;
  final MonitoringTimerFactory _timer;
  final DateTime Function() _now;
  final Random _random;

  late final MonitoringRepository _repository =
      _injectedRepository ?? MonitoringRepositoryHttp();

  final List<MonitoringCommandResultDto> _pending = [];
  final List<Completer<void>> _waiting = [];
  Future<void>? _restoring;
  bool _started = false;
  bool _sending = false;
  Timer? _retry;
  int _failures = 0;

  CommandResultOutbox(
      {required MonitoringService enrollment,
      MonitoringRepository? repository,
      CommandResultStore? store,
      MonitoringTimerFactory? timer,
      DateTime Function()? now,
      Random? random})
      : _enrollment = enrollment,
        _injectedRepository = repository,
        _store = store ?? PrefsCommandResultStore(),
        _timer = timer ?? Timer.new,
        _now = now ?? DateTime.now,
        _random = random ?? Random();

  /// Results not delivered yet, oldest first.
  List<MonitoringCommandResultDto> get pending => List.unmodifiable(_pending);

  /// Picks up what a previous session left, and sends whenever the kiosk
  /// is enrolled. Once.
  void start() {
    if (_started) return;
    _started = true;
    _enrollment.status.addListener(_onEnrollment);
    unawaited(_restore().then((_) => _send()).catchError((Object _) {}));
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _enrollment.status.removeListener(_onEnrollment);
    _cancelRetry();
  }

  /// Keeps [result] and sends it. Completes once it was delivered or
  /// dropped, or once this attempt failed (it is retried later). Never
  /// throws.
  Future<void> add(MonitoringCommandResultDto result) async {
    try {
      await _restore();
      _pending.removeWhere((r) => r.commandId == result.commandId);
      _pending.add(result);
      while (_pending.length > capacity) {
        _pending.removeAt(0);
      }
      await _persist();
      final done = Completer<void>();
      _waiting.add(done);
      unawaited(_send());
      await done.future;
    } catch (_) {}
  }

  Future<void> _restore() => _restoring ??= () async {
        final saved = await _store.load();
        for (final r in saved) {
          if (!_pending.any((p) => p.commandId == r.commandId)) _pending.insert(0, r);
        }
      }();

  void _onEnrollment() {
    if (_enrollment.deviceToken != null && _pending.isNotEmpty && _retry == null) {
      unawaited(_send());
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    _sending = true;
    _cancelRetry();
    var failed = false;
    try {
      _pending.removeWhere((r) => _now().difference(r.recordedAt) > maxAge);
      while (_pending.isNotEmpty) {
        final token = _enrollment.deviceToken;
        // Not enrolled: [_onEnrollment] sends once there is a token.
        if (token == null) break;
        final result = _pending.first;
        try {
          await _repository.reportCommandResult(result, deviceToken: token).timeout(attemptTimeout);
          _pending.remove(result);
          _failures = 0;
        } on MonitoringException catch (e) {
          if (e.isTokenInvalid) {
            unawaited(_enrollment.onTokenRejected(token));
            failed = true;
            break;
          }
          if (e.isFinal) {
            _pending.remove(result);
            Telemetry.event('monitoring.command_result_dropped',
                level: TelemetryLevel.warning,
                data: {'id': result.commandId, 'cause': e.cause, if (e.code != null) 'code': e.code});
            continue;
          }
          failed = true;
          break;
        } catch (_) {
          failed = true;
          break;
        }
      }
      await _persist();
    } catch (_) {
      failed = true;
    } finally {
      _sending = false;
      final waiting = List.of(_waiting);
      _waiting.clear();
      for (final w in waiting) {
        if (!w.isCompleted) w.complete();
      }
      if (failed && _pending.isNotEmpty && _started) {
        _failures++;
        _retry = _timer(retryDelay(_failures, _random.nextDouble()), () {
          _retry = null;
          unawaited(_send());
        });
      }
    }
  }

  /// [firstRetry] after the first failure, doubling up to [maxBackoff],
  /// moved by up to 20 % either way for [random] in [0, 1) (0.5 leaves it as
  /// is), and never out of that range ([MonitoringBackoff]).
  static Duration retryDelay(int failures, double random) => MonitoringBackoff.delay(
      first: firstRetry, max: maxBackoff, failures: failures, random: random);

  Future<void> _persist() => _store.save(_pending);

  void _cancelRetry() {
    _retry?.cancel();
    _retry = null;
  }
}
