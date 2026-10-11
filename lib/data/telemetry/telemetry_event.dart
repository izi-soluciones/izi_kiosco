/// How much an event matters. [error] marks something that went wrong for a
/// customer or an operator, not a routine failure the kiosk recovers from.
enum TelemetryLevel { debug, info, warning, error }

/// One thing that happened on this kiosk, as it is kept on the device and
/// sent to Sentry. PayPOS records the same shape, so a charge can be followed
/// from one to the other by [chargeId] and [reference].
class TelemetryEvent {
  /// Increases by one per event within an app session.
  final int seq;

  /// Wall clock of the kiosk PC. It drifts from the terminal's, so events are
  /// ordered by [upMs] within each app and matched across apps by [reference].
  final DateTime ts;

  /// Milliseconds since this app session started: immune to clock changes.
  final int upMs;

  /// Dotted name, e.g. `pos.health_failed`, `charge.result`.
  final String type;
  final TelemetryLevel level;

  /// Identifies the whole charge (cobro), retries included.
  final String? chargeId;

  /// Identifies one attempt of the charge on the terminal (`KOS-…`).
  final String? reference;

  /// Already redacted: see [TelemetryRedactor].
  final Map<String, Object?> data;

  const TelemetryEvent({
    required this.seq,
    required this.ts,
    required this.upMs,
    required this.type,
    required this.level,
    this.chargeId,
    this.reference,
    this.data = const {},
  });

  Map<String, Object?> toJson() => {
        'seq': seq,
        'ts': ts.toIso8601String(),
        'upMs': upMs,
        'type': type,
        'level': level.name,
        if (chargeId != null) 'chargeId': chargeId,
        if (reference != null) 'reference': reference,
        if (data.isNotEmpty) 'data': data,
      };

  static TelemetryEvent? fromJson(Object? json) {
    if (json is! Map) return null;
    final ts = DateTime.tryParse(json['ts']?.toString() ?? '');
    final type = json['type']?.toString();
    if (ts == null || type == null) return null;
    return TelemetryEvent(
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      ts: ts,
      upMs: (json['upMs'] as num?)?.toInt() ?? 0,
      type: type,
      level: TelemetryLevel.values.firstWhere(
          (l) => l.name == json['level'], orElse: () => TelemetryLevel.info),
      chargeId: json['chargeId']?.toString(),
      reference: json['reference']?.toString(),
      data: json['data'] is Map
          ? Map<String, Object?>.from(json['data'] as Map)
          : const {},
    );
  }

  /// One line for the diagnostics screen.
  String get summary {
    final ids = [
      if (chargeId != null) chargeId,
      if (reference != null) reference,
    ].join(' ');
    final details = data.entries.map((e) => '${e.key}=${e.value}').join(' ');
    return [type, if (ids.isNotEmpty) ids, if (details.isNotEmpty) details]
        .join('  ');
  }
}
