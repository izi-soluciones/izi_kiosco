import 'dart:async';

import 'package:flutter/foundation.dart';
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
      Future<void> Function()? beforeReload})
      : _enrollment = enrollment,
        _injectedRepository = repository,
        _diagnostics = diagnostics ?? KioskDiagnostics(),
        _reloadPage = reloadPage ?? page.reloadPage,
        _beforeReload = beforeReload ?? _saveRecords;

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
  Future<CommandOutcome> reload(MonitoringCommand command) async {
    if (!kIsWeb && restartApp == null) {
      return const CommandOutcome.failed(detail: 'not_available');
    }
    return CommandOutcome.succeeded(
        detail: kIsWeb ? 'page_reload' : 'app_restart',
        after: () async {
          try {
            // What was recorded in the last seconds is still only in
            // memory: saved first, it is uploaded after the reload.
            await _beforeReload().timeout(saveTimeout, onTimeout: () {});
          } catch (_) {}
          try {
            if (!_reloadPage()) restartApp?.call();
          } catch (_) {}
        });
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
