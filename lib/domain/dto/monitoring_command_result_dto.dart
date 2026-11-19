import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';

/// How a remote command ended (contracts §6).
enum MonitoringCommandStatus { succeeded, failed, rejected }

/// Body of `POST /monitoreo/ingesta/comandos/:id/resultado`, and what the
/// kiosk keeps of it until the service has it.
class MonitoringCommandResultDto {
  /// The service keeps up to 2000 characters of [detail]; the kiosk sends
  /// far less.
  static const int maxDetail = 500;

  final String commandId;

  /// The command's `type`, for the kiosk's own log; not sent.
  final String type;
  final MonitoringCommandStatus status;
  final String? detail;
  final Map<String, Object?> data;
  final DateTime recordedAt;

  const MonitoringCommandResultDto(
      {required this.commandId,
      required this.type,
      required this.status,
      this.detail,
      this.data = const {},
      required this.recordedAt});

  /// `rejected` with `{"reason": reason}`: `busy`, `expired`,
  /// `unsupported`...
  factory MonitoringCommandResultDto.rejected(
          {required String commandId,
          required String type,
          required String reason,
          String? detail,
          required DateTime at}) =>
      MonitoringCommandResultDto(
          commandId: commandId,
          type: type,
          status: MonitoringCommandStatus.rejected,
          detail: detail,
          data: {'reason': reason},
          recordedAt: at);

  /// What the service receives: redacted, like everything the kiosk sends.
  Map<String, Object?> toJson() => TelemetryRedactor.redact({
        'status': status.name,
        if (detail != null && detail!.isNotEmpty) 'detail': _short(detail!),
        'data': data,
      });

  /// What the kiosk stores while the result is on its way.
  Map<String, Object?> toStorage() => {
        'commandId': commandId,
        'type': type,
        ...toJson(),
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      };

  static MonitoringCommandResultDto? fromStorage(Object? json) {
    if (json is! Map) return null;
    final id = json['commandId'];
    final status = MonitoringCommandStatus.values.asNameMap()[json['status']];
    final recordedAt = DateTime.tryParse('${json['recordedAt'] ?? ''}');
    if (id is! String || id.isEmpty || status == null || recordedAt == null) return null;
    final data = json['data'];
    final detail = json['detail'];
    return MonitoringCommandResultDto(
        commandId: id,
        type: '${json['type'] ?? ''}',
        status: status,
        detail: detail is String ? detail : null,
        data: data is Map ? Map<String, Object?>.from(data) : const {},
        recordedAt: recordedAt);
  }

  static String _short(String text) =>
      text.length > maxDetail ? '${text.substring(0, maxDetail)}…' : text;
}
