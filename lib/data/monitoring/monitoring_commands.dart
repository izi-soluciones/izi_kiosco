import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/models/monitoring_heartbeat_response.dart';

/// Where the heartbeat hands the remote commands it receives (contracts §6).
/// Running them, and reporting their result, is KIO-05's.
abstract class MonitoringCommandQueue {
  /// Takes [commands] as delivered by the service. Must not throw, nor run
  /// anything before returning: the heartbeat loop calls it.
  void enqueue(List<MonitoringCommand> commands);
}

/// Keeps the commands received, without running any: the kiosk does not
/// execute remote commands yet.
///
/// The service marks a command delivered when it sends it, so each one is
/// kept (by id, at most [capacity], expired ones dropped) for the executor
/// to find, and recorded once in the device log.
class PendingCommandQueue implements MonitoringCommandQueue {
  static const int capacity = 20;

  final DateTime Function() _now;
  final Map<String, MonitoringCommand> _pending = {};

  PendingCommandQueue({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Unexpired commands, oldest first.
  List<MonitoringCommand> get pending {
    _dropExpired();
    return List.unmodifiable(_pending.values);
  }

  @override
  void enqueue(List<MonitoringCommand> commands) {
    try {
      _dropExpired();
      for (final command in commands) {
        if (_pending.containsKey(command.id) || command.isExpired(_now())) continue;
        _pending[command.id] = command;
        Telemetry.event('monitoring.command_received',
            data: {'id': command.id, 'type': command.type});
      }
      while (_pending.length > capacity) {
        _pending.remove(_pending.keys.first);
      }
    } catch (_) {}
  }

  /// The executor took [id] (KIO-05).
  MonitoringCommand? take(String id) => _pending.remove(id);

  void _dropExpired() {
    final now = _now();
    _pending.removeWhere((_, command) => command.isExpired(now));
  }
}
