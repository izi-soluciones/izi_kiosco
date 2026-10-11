import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_diagnostics.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_commands.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/page_reload.dart' as page;
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/pos_config/pos_config_bloc.dart';
import 'package:izi_kiosco/domain/models/monitoring_heartbeat_response.dart';
import 'package:izi_kiosco/domain/repositories/monitoring_repository.dart';

/// The remote commands a kiosk runs (contracts §6), for
/// [MonitoringCommandRunner]: `reload_app`, `repair_pos`,
/// `upload_diagnostics` and `rotate_token`.
///
/// The runner already keeps them away from a sale (busy rule) and reports
/// their results; each handler here only does its job and says how it went.
/// None puts a token, a code or a card in its result.
class KioskCommands {
  static const String reloadApp = 'reload_app';
  static const String repairPos = 'repair_pos';
  static const String uploadDiagnostics = 'upload_diagnostics';
  static const String rotateToken = 'rotate_token';

  final MonitoringService _enrollment;
  final MonitoringRepository? _injectedRepository;
  final KioskDiagnostics _diagnostics;
  final bool Function() _reloadPage;
  final Future<void> Function() _beforeReload;
  final bool Function() _busy;
  final MonitoringTimerFactory _timer;

  /// The most a reload waits for the device log and the counters to be
  /// saved.
  static const Duration saveTimeout = Duration(seconds: 2);

  late final MonitoringRepository _repository =
      _injectedRepository ?? MonitoringRepositoryHttp();

  /// The login (the device, for the terminal's diagnostics) and the POS
  /// pairing, set up by `MyApp`.
  AuthState Function()? _auth;
  PosConfigBloc? _posConfig;

  /// Outside the browser: takes the app back to its home screen and loads
  /// the kiosk again, as the "reload" button of the error screen does. Set
  /// up by `MyApp`.
  void Function()? restartApp;

  KioskCommands(
      {required MonitoringService enrollment,
      MonitoringRepository? repository,
      KioskDiagnostics? diagnostics,
      bool Function()? reloadPage,
      Future<void> Function()? beforeReload,
      bool Function()? busy,
      MonitoringTimerFactory? timer})
      : _enrollment = enrollment,
        _injectedRepository = repository,
        _diagnostics = diagnostics ?? KioskDiagnostics(),
        _reloadPage = reloadPage ?? page.reloadPage,
        _beforeReload = beforeReload ?? _saveRecords,
        _busy = busy ?? (() => KioskActivity.instance.busy),
        _timer = timer ?? Timer.new;

  static Future<void> _saveRecords() async {
    await Telemetry.instance.buffer.flush();
    await KioskCounters.instance.flush();
  }

  static KioskCommands? _instance;

  /// The handlers installed at startup; null before (and in tests that do
  /// not install them).
  static KioskCommands? get instance => _instance;

  static void install(KioskCommands commands) => _instance = commands;

  void attach({required AuthBloc auth, required PosConfigBloc posConfig}) {
    _auth = () => auth.state;
    _posConfig = posConfig;
  }

  /// For tests.
  void attachStates({AuthState Function()? auth, PosConfigBloc? posConfig}) {
    _auth = auth;
    _posConfig = posConfig;
  }

  Map<String, CommandHandler> get handlers => {
        reloadApp: reload,
        repairPos: repair,
        uploadDiagnostics: upload,
        rotateToken: rotate,
      };

  /// `reload_app`: reports first, then reloads the page (web) or restarts
  /// the app to its home screen (Android).
  ///
  /// The runner checked the busy rule before this handler, but the reload
  /// happens only after the result left (up to
  /// [MonitoringCommandRunner.flushBeforeAfter]) and the records were saved
  /// (up to [saveTimeout]): a customer may have reached the payment in the
  /// meantime. So the busy rule is checked again before saving and once more
  /// right before reloading, with nothing asynchronous in between. The
  /// result already said the kiosk reloads, so a busy kiosk does not drop
  /// the reload: it stays due, checked again every
  /// [MonitoringCommandRunner.busyRecheck], and happens as soon as the
  /// customer is done (`monitoring.reload_deferred` says it waited).
  Future<CommandOutcome> reload(MonitoringCommand command) async {
    if (!kIsWeb && restartApp == null) {
      return const CommandOutcome.failed(detail: 'not_available');
    }
    return CommandOutcome.succeeded(
        detail: kIsWeb ? 'page_reload' : 'app_restart', after: () => _reloadWhenIdle(command));
  }

  Future<void> _reloadWhenIdle(MonitoringCommand command) async {
    var deferred = false;
    while (true) {
      if (_isBusy()) {
        if (!deferred) {
          deferred = true;
          Telemetry.event('monitoring.reload_deferred',
              level: TelemetryLevel.warning, data: {'id': command.id, 'type': command.type});
        }
        await _wait(MonitoringCommandRunner.busyRecheck);
        continue;
      }
      try {
        // What was recorded in the last seconds is still only in
        // memory: saved first, it is uploaded after the reload.
        await _beforeReload().timeout(saveTimeout, onTimeout: () {});
      } catch (_) {}
      // The last check: from here to the reload nothing yields, so no
      // customer can reach the payment in between.
      if (_isBusy()) continue;
      try {
        if (!_reloadPage()) restartApp?.call();
      } catch (_) {}
      return;
    }
  }

  bool _isBusy() {
    try {
      return _busy();
    } catch (_) {
      // Unknown counts as busy, as for the runner: a reload never risks a
      // sale.
      return true;
    }
  }

  Future<void> _wait(Duration delay) {
    final done = Completer<void>();
    try {
      _timer(delay, () {
        if (!done.isCompleted) done.complete();
      });
    } catch (_) {
      return Future<void>.delayed(delay);
    }
    return done.future;
  }

  /// `repair_pos`: what "Verificar ahora" does: the terminal is asked, paired
  /// again if it lost the pairing or rejects the token, looked for on the
  /// LAN if it moved; with no pairing, the backend's terminal is paired.
  /// Succeeds when the terminal ends up ready to charge.
  Future<CommandOutcome> repair(MonitoringCommand command) async {
    final bloc = _posConfig;
    if (bloc == null || bloc.isClosed) return const CommandOutcome.failed(detail: 'not_ready');
    await bloc.repair();
    final state = bloc.state;
    final device = state.pairedDevice;
    if (device == null) {
      return CommandOutcome.failed(
          detail: state.errorMessage ?? 'not_paired', data: const {'paired': false});
    }
    final data = {'paired': true, 'address': '${device.ip}:${device.port}', 'healthy': state.isHealthy == true};
    if (state.isHealthy == true) return CommandOutcome.succeeded(data: data);
    return CommandOutcome.failed(detail: state.notReadyReason ?? 'not_healthy', data: data);
  }

  /// `upload_diagnostics`: the diagnostics report ([KioskDiagnostics]) to the
  /// service, tied to the command.
  Future<CommandOutcome> upload(MonitoringCommand command) async {
    final token = _enrollment.deviceToken;
    if (token == null) return CommandOutcome.rejected('not_enrolled');
    AuthState? auth;
    try {
      auth = _auth?.call();
    } catch (_) {}
    final report = await _diagnostics.build(device: auth?.currentDevice);
    try {
      final receipt =
          await _repository.uploadDiagnostics(report, commandId: command.id, deviceToken: token);
      final terminal = report['terminal'];
      return CommandOutcome.succeeded(data: {
        if (receipt.id != null) 'diagnosticId': receipt.id,
        if (receipt.size != null) 'size': receipt.size,
        'terminal': terminal is Map && terminal['unavailable'] != null
            ? terminal['unavailable']
            : 'included',
      });
    } on MonitoringException catch (e) {
      if (e.isTokenInvalid) unawaited(_enrollment.onTokenRejected(token));
      return CommandOutcome.failed(
          detail: e.cause, data: {if (e.code != null) 'code': e.code});
    }
  }

  /// `rotate_token` (contracts §12.5): keeps the token the service sent in
  /// `args.deviceToken`, so the result goes with it; without one, enrolls
  /// again.
  Future<CommandOutcome> rotate(MonitoringCommand command) async {
    final next = command.args['deviceToken'];
    if (next != null) {
      if (next is! String || !MonitoringService.rotatedTokenFormat.hasMatch(next)) {
        return const CommandOutcome.failed(detail: 'invalid_token');
      }
      return await _enrollment.adoptRotatedToken(next)
          ? const CommandOutcome.succeeded(detail: 'rotated')
          : const CommandOutcome.failed(detail: 'not_enrolled');
    }
    final fresh = await _enrollment.reenroll();
    return fresh != null
        ? const CommandOutcome.succeeded(detail: 'reenrolled')
        : CommandOutcome.failed(
            detail: 'reenroll_failed',
            data: {if (_enrollment.status.value.lastCause != null) 'cause': _enrollment.status.value.lastCause});
  }
}
