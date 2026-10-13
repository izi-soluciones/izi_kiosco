import 'package:izi_kiosco/data/telemetry/telemetry_event.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';

/// Body of `POST /monitoreo/ingesta/eventos` (contracts §5): a batch of the
/// kiosk's [TelemetryEvent]s of one [stream].
///
/// Not redacted as a whole like the heartbeat (the redactor keeps the first
/// 20 items of a list): each event is, in [eventJson].
class MonitoringEventsDto {
  static const int schema = 1;

  /// What the service takes in one batch (contracts §5).
  static const int maxEvents = 200;

  final String installationId;

  /// Identifies the sequence the events' `seq` belong to.
  final String stream;
  final List<TelemetryEvent> events;

  const MonitoringEventsDto(
      {required this.installationId, required this.stream, required this.events});

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'installationId': installationId,
        'stream': stream,
        'events': [for (final e in events) eventJson(e)],
      };

  /// One event as the contract has it (§5, §12.4): `ts` in UTC with `Z` (the
  /// buffer keeps the PC's local time, without offset) and `level` one of
  /// `debug|info|warn|error`. Redacted again: events kept by an older build
  /// come back from storage.
  static Map<String, Object?> eventJson(TelemetryEvent event) {
    final chargeId = event.chargeId;
    final reference = event.reference;
    return {
      'seq': event.seq,
      'ts': event.ts.toUtc().toIso8601String(),
      'upMs': event.upMs,
      'type': event.type,
      'level': level(event.level),
      if (chargeId != null) 'chargeId': TelemetryRedactor.scrub(chargeId),
      if (reference != null) 'reference': TelemetryRedactor.scrub(reference),
      'data': TelemetryRedactor.redact(event.data),
    };
  }

  /// The contract's name of [level]: `warning` is `warn`.
  static String level(TelemetryLevel level) => switch (level) {
        TelemetryLevel.debug => 'debug',
        TelemetryLevel.info => 'info',
        TelemetryLevel.warning => 'warn',
        TelemetryLevel.error => 'error',
      };
}
