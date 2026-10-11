import 'dart:async';

import 'package:izi_kiosco/data/monitoring/command_result_outbox.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/dto/monitoring_command_result_dto.dart';
import 'package:izi_kiosco/domain/models/monitoring_heartbeat_response.dart';

/// Where the heartbeat hands the remote commands it receives (contracts §6).
abstract class MonitoringCommandQueue {
  /// Takes [commands] as delivered by the service, whose clock read
  /// [serverTime] when it answered. Must not throw, nor run anything before
  /// returning: the heartbeat loop calls it.
  void enqueue(List<MonitoringCommand> commands, {DateTime? serverTime});
}

/// How a command handler ended.
class CommandOutcome {
  final MonitoringCommandStatus status;
  final String? detail;

  /// The result's `data`; a rejection carries its `reason` in it.
  final Map<String, Object?> data;

  /// Runs once the result is on its way (or could not leave in time):
  /// `reload_app` reloads the page only after reporting that it will. It
  /// must keep to the busy rule itself (the customer may have reached the
  /// payment since the runner checked), and may wait for that: the queue
  /// waits with it, as whatever is behind a reload would be cut off by it.
  final Future<void> Function()? after;

  const CommandOutcome.succeeded({this.detail, this.data = const {}, this.after})
      : status = MonitoringCommandStatus.succeeded;

  const CommandOutcome.failed({this.detail, this.data = const {}})
      : status = MonitoringCommandStatus.failed,
        after = null;

  /// `rejected` with `{"reason": reason}` (contracts §6: `busy`; also
  /// `expired`, `unsupported`, `queue_full`, `not_enrolled`...).
  CommandOutcome.rejected(String reason, {this.detail})
      : status = MonitoringCommandStatus.rejected,
        data = {'reason': reason},
        after = null;

  String? get reason => data['reason']?.toString();
}

/// Runs one command type. Should not throw (the runner catches anyway).
typedef CommandHandler = Future<CommandOutcome> Function(MonitoringCommand command);

/// Runs the remote commands the heartbeat delivers, one at a time, and
/// reports each result (contracts §6).
///
/// - A type without a handler is answered `rejected` `{reason: unsupported}`.
/// - A command whose `expiresAt` passed, by the service's clock (from the
///   heartbeat's `serverTime`: the kiosk's own may be off), is `rejected`
///   `{reason: expired}`.
/// - **Busy rule**: nothing runs while a customer is paying or a card
///   charge is on its way ([KioskActivity.busy]: `chargeInProgress` or
///   `mode=paying`). The command waits, checked again every [busyRecheck],
///   for up to [maxPostpone]; still busy then, it is `rejected`
///   `{reason: busy}`.
/// - A handler that throws, or takes longer than [handlerTimeout], is
///   `failed`.
///
/// Results go through a [CommandResultOutbox], which keeps them until the
/// service has them, across reloads. Commands themselves are not kept: one
/// cut off by a reload is left to expire on the service.
class MonitoringCommandRunner implements MonitoringCommandQueue {
  static const int capacity = 20;
  static const Duration maxPostpone = Duration(minutes: 2);
  static const Duration busyRecheck = Duration(seconds: 5);
  static const Duration handlerTimeout = Duration(seconds: 90);

  /// How long a result may take to leave before its [CommandOutcome.after]
  /// (a reload) runs anyway.
  static const Duration flushBeforeAfter = Duration(seconds: 8);

  /// Ids already taken, so a command delivered twice runs once.
  static const int rememberedIds = 100;

  final CommandResultOutbox outbox;
  final Map<String, CommandHandler> handlers;
  final bool Function() _busy;
  final MonitoringTimerFactory _timer;
  final DateTime Function() _now;

  final List<_Queued> _queue = [];
  final List<String> _seen = [];
  Timer? _next;
  bool _running = false;

  /// Service time minus kiosk time, at the last heartbeat that said.
  Duration _skew = Duration.zero;

  MonitoringCommandRunner(
      {required this.outbox,
      Map<String, CommandHandler>? handlers,
      bool Function()? busy,
      MonitoringTimerFactory? timer,
      DateTime Function()? now})
      : handlers = handlers ?? {},
        _busy = busy ?? (() => KioskActivity.instance.busy),
        _timer = timer ?? Timer.new,
        _now = now ?? DateTime.now;

  static MonitoringCommandRunner? _instance;

  /// The runner installed at startup; null before (and in tests that do not
  /// install one).
  static MonitoringCommandRunner? get instance => _instance;

  static void install(MonitoringCommandRunner runner) => _instance = runner;

  /// Sends the results a previous session left. Once.
  void start() => outbox.start();

  /// Commands waiting to run, oldest first.
  List<MonitoringCommand> get pending => [for (final q in _queue) q.command];

  /// The service's clock now, as far as the kiosk knows it.
  DateTime get serverNow => _now().add(_skew);

  @override
  void enqueue(List<MonitoringCommand> commands, {DateTime? serverTime}) {
    try {
      if (serverTime != null) _skew = serverTime.difference(_now());
      for (final command in commands) {
        if (_seen.contains(command.id)) continue;
        _remember(command.id);
        Telemetry.event('monitoring.command_received',
            data: {'id': command.id, 'type': command.type});
        if (_queue.length >= capacity) {
          unawaited(_finish(command, CommandOutcome.rejected('queue_full')));
          continue;
        }
        _queue.add(_Queued(command, _now()));
      }
      if (_queue.isNotEmpty && !_running) _schedule(Duration.zero);
    } catch (_) {}
  }

  /// Runs what can run now (also what the timer calls).
  Future<void> pump() async {
    if (_running) return;
    _running = true;
    _cancel();
    try {
      while (_queue.isNotEmpty) {
        final queued = _queue.first;
        final command = queued.command;
        if (command.isExpired(serverNow)) {
          _queue.removeAt(0);
          await _finish(command, CommandOutcome.rejected('expired'));
          continue;
        }
        final handler = handlers[command.type];
        if (handler == null) {
          _queue.removeAt(0);
          await _finish(command, CommandOutcome.rejected('unsupported'));
          continue;
        }
        if (_isBusy()) {
          final waited = _now().difference(queued.receivedAt);
          if (waited < maxPostpone) {
            if (!queued.postponed) {
              queued.postponed = true;
              Telemetry.event('monitoring.command_postponed',
                  data: {'id': command.id, 'type': command.type});
            }
            final left = maxPostpone - waited;
            _schedule(left < busyRecheck ? left : busyRecheck);
            return;
          }
          _queue.removeAt(0);
          await _finish(command, CommandOutcome.rejected('busy'));
          continue;
        }
        _queue.removeAt(0);
        Telemetry.event('monitoring.command_started',
            data: {'id': command.id, 'type': command.type});
        CommandOutcome outcome;
        try {
          outcome = await handler(command).timeout(handlerTimeout);
        } on TimeoutException {
          outcome = const CommandOutcome.failed(detail: 'timeout');
        } catch (e) {
          outcome = CommandOutcome.failed(detail: e.runtimeType.toString());
        }
        await _finish(command, outcome);
      }
    } catch (_) {
    } finally {
      _running = false;
    }
  }

  bool _isBusy() {
    try {
      return _busy();
    } catch (_) {
      // Unknown counts as busy: a command never risks a sale.
      return true;
    }
  }

  Future<void> _finish(MonitoringCommand command, CommandOutcome outcome) async {
    try {
      final result = MonitoringCommandResultDto(
        commandId: command.id,
        type: command.type,
        status: outcome.status,
        detail: outcome.detail,
        data: outcome.data,
        recordedAt: _now(),
      );
      Telemetry.event('monitoring.command_finished',
          level: outcome.status == MonitoringCommandStatus.succeeded
              ? TelemetryLevel.info
              : TelemetryLevel.warning,
          data: {
            'id': command.id,
            'type': command.type,
            'status': outcome.status.name,
            if (outcome.reason != null) 'reason': outcome.reason,
          });
      final sent = outbox.add(result);
      final after = outcome.after;
      if (after != null) {
        await sent.timeout(flushBeforeAfter, onTimeout: () {});
        await after();
      }
    } catch (_) {}
  }

  void _remember(String id) {
    _seen.add(id);
    if (_seen.length > rememberedIds) _seen.removeAt(0);
  }

  void _schedule(Duration delay) {
    _cancel();
    _next = _timer(delay, () => unawaited(pump()));
  }

  void _cancel() {
    _next?.cancel();
    _next = null;
  }
}

class _Queued {
  final MonitoringCommand command;
  final DateTime receivedAt;
  bool postponed = false;

  _Queued(this.command, this.receivedAt);
}
