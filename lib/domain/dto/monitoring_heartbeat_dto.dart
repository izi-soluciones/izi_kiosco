import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';

/// Body of `POST /monitoreo/ingesta/heartbeat` (contracts §4).
///
/// [state] and [counters] are already JSON; the whole body still goes
/// through [TelemetryRedactor], like everything the kiosk sends.
class MonitoringHeartbeatDto {
  static const int schema = 1;
  static const String kind = 'kiosk';

  final String installationId;
  final DateTime sentAt;

  /// Changes on every app start: tells a reload from a long-running kiosk.
  final String bootId;
  final int uptimeSec;
  final MonitoringApp app;
  final Map<String, Object?> state;
  final Map<String, Object?> counters;

  /// The last event `seq` recorded, once events are uploaded (KIO-03).
  final int? lastEventSeq;

  const MonitoringHeartbeatDto(
      {required this.installationId,
      required this.sentAt,
      required this.bootId,
      required this.uptimeSec,
      required this.app,
      required this.state,
      required this.counters,
      this.lastEventSeq});

  Map<String, dynamic> toJson() => TelemetryRedactor.redact({
        'schema': schema,
        'installationId': installationId,
        'kind': kind,
        'sentAt': sentAt.toUtc().toIso8601String(),
        'bootId': bootId,
        'uptimeSec': uptimeSec,
        'app': app.toJson(),
        'state': state,
        'counters': counters,
        if (lastEventSeq != null) 'lastEventSeq': lastEventSeq,
      });
}
