/// A remote command the support console sent this kiosk (contracts §6),
/// delivered in a heartbeat response.
class MonitoringCommand {
  final String id;

  /// `reload_app`, `repair_pos`, `upload_diagnostics`, `rotate_token`...
  final String type;
  final Map<String, dynamic> args;
  final DateTime? expiresAt;

  const MonitoringCommand(
      {required this.id, required this.type, this.args = const {}, this.expiresAt});

  /// Null without an id and a type: a command nobody can answer for.
  static MonitoringCommand? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final type = json['type'];
    if (id is! String || id.isEmpty || type is! String || type.isEmpty) return null;
    final args = json['args'];
    return MonitoringCommand(
      id: id,
      type: type,
      args: args is Map ? Map<String, dynamic>.from(args) : const {},
      expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}'),
    );
  }

  bool isExpired(DateTime now) => expiresAt != null && !expiresAt!.isAfter(now);
}

/// What the monitoring service answers a heartbeat (contracts §4.5).
class MonitoringHeartbeatResponse {
  /// When the next heartbeat is due, as the service asks; null when it did
  /// not say (or said something unusable).
  final int? nextInSec;

  /// The last event `seq` the service persisted (contracts §5).
  final int? ackSeq;
  final DateTime? serverTime;
  final List<MonitoringCommand> commands;
  final Map<String, dynamic> config;

  const MonitoringHeartbeatResponse(
      {this.nextInSec,
      this.ackSeq,
      this.serverTime,
      this.commands = const [],
      this.config = const {}});

  /// Tolerant: the heartbeat was accepted whatever the body says, so an
  /// odd field only loses that field.
  static MonitoringHeartbeatResponse parse(Object? json) {
    if (json is! Map) return const MonitoringHeartbeatResponse();
    final next = json['nextInSec'];
    final ack = json['ackSeq'];
    final commands = json['commands'];
    final config = json['config'];
    return MonitoringHeartbeatResponse(
      nextInSec: next is num && next.isFinite ? next.round() : null,
      ackSeq: ack is num && ack.isFinite ? ack.toInt() : null,
      serverTime: DateTime.tryParse('${json['serverTime'] ?? ''}'),
      commands: commands is List
          ? commands.map(MonitoringCommand.tryParse).whereType<MonitoringCommand>().toList()
          : const [],
      config: config is Map ? Map<String, dynamic>.from(config) : const {},
    );
  }
}
