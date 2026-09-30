import 'dart:convert';

import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sends recorded events to Sentry:
/// - every event as a breadcrumb (free: it travels inside the next issue);
/// - within the log budget, as a Sentry log (the usage timeline);
/// - when asked and within the issue budget, as an issue.
class SentryTelemetrySink implements TelemetrySink {
  /// Tag set on the issues this sink creates, so `beforeSend` does not count
  /// them against the budget a second time.
  static const String originTag = 'telemetry';

  @override
  void onEvent(TelemetryEvent event,
      {required bool sendLog, required bool sendIssue}) {
    try {
      Sentry.addBreadcrumb(Breadcrumb(
        category: event.type,
        message: event.summary,
        level: _sentryLevel(event.level),
        timestamp: event.ts.toUtc(),
      ));
      if (sendLog) {
        final attributes = logAttributes(event);
        final logger = Sentry.logger;
        switch (event.level) {
          case TelemetryLevel.debug:
            logger.debug(event.type, attributes: attributes);
          case TelemetryLevel.info:
            logger.info(event.type, attributes: attributes);
          case TelemetryLevel.warning:
            logger.warn(event.type, attributes: attributes);
          case TelemetryLevel.error:
            logger.error(event.type, attributes: attributes);
        }
      }
      if (sendIssue) {
        Sentry.captureMessage(
          event.type,
          level: _sentryLevel(event.level),
          withScope: (scope) {
            scope.fingerprint = [
              event.type,
              '${event.data['code'] ?? event.data['cause'] ?? event.data['status'] ?? ''}',
            ];
            scope.setTag(originTag, '1');
            if (event.chargeId != null) scope.setTag('charge.id', event.chargeId!);
            if (event.reference != null) {
              scope.setTag('charge.reference', event.reference!);
            }
            scope.setContexts('event', event.toJson());
          },
        );
      }
    } catch (_) {
      // Sentry not initialized (no DSN) or failing: the device keeps the event.
    }
  }

  @override
  void setContext(Map<String, Object?> context) {
    try {
      Sentry.setAttributes({
        for (final e in context.entries)
          if (e.value != null) e.key: attribute(e.value),
      });
      Sentry.configureScope((scope) {
        for (final e in context.entries) {
          if (e.value == null) {
            scope.removeTag(e.key);
          } else {
            scope.setTag(e.key, e.value.toString());
          }
        }
      });
    } catch (_) {}
  }

  static Map<String, SentryAttribute> logAttributes(TelemetryEvent event) => {
        'event.seq': SentryAttribute.int(event.seq),
        'app.up_ms': SentryAttribute.int(event.upMs),
        if (event.chargeId != null)
          'charge.id': SentryAttribute.string(event.chargeId!),
        if (event.reference != null)
          'charge.reference': SentryAttribute.string(event.reference!),
        for (final e in event.data.entries)
          if (e.value != null) e.key: attribute(e.value),
      };

  static SentryAttribute attribute(Object? value) => switch (value) {
        final bool v => SentryAttribute.bool(v),
        final int v => SentryAttribute.int(v),
        final double v => SentryAttribute.double(v),
        final String v => SentryAttribute.string(v),
        _ => SentryAttribute.string(jsonEncode(value)),
      };

  static SentryLevel _sentryLevel(TelemetryLevel level) => switch (level) {
        TelemetryLevel.debug => SentryLevel.debug,
        TelemetryLevel.info => SentryLevel.info,
        TelemetryLevel.warning => SentryLevel.warning,
        TelemetryLevel.error => SentryLevel.error,
      };
}
