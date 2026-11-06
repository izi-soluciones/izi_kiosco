import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/data/telemetry/platform_signals.dart';
import 'package:izi_kiosco/data/telemetry/pos_telemetry.dart';
import 'package:izi_kiosco/data/telemetry/send_budget.dart';
import 'package:izi_kiosco/data/telemetry/sentry_telemetry_sink.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_buffer.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Starts the kiosk's telemetry and then the app.
///
/// Events are always kept on the device (the POS configuration screen shows
/// them). They also go to Sentry when the flavor's `.env` has a
/// `SENTRY_DSN`: usage as Sentry logs, and only what needs a person as
/// issues (see [SendBudget]). No periodic heartbeat is sent, to stay within
/// Sentry's free plan.
class KioskTelemetry {
  /// How often the watchdog timer should fire. When Chrome throttles the tab
  /// it fires much later, which is what [_watchTimers] reports.
  static const Duration timerCheck = Duration(seconds: 30);

  static Future<void> run(
      {required String flavor, required FutureOr<void> Function() appRunner}) async {
    final buffer = TelemetryBuffer(store: PrefsTelemetryStore());
    await buffer.restore();
    final previousEvents = buffer.length;
    final budget = SendBudget();
    final dsn = dotenv.env[EnvKeys.sentryDsn]?.trim() ?? '';
    final useSentry = dsn.isNotEmpty;
    Telemetry.install(Telemetry(
      buffer: buffer,
      budget: budget,
      sink: useSentry ? SentryTelemetrySink() : null,
    ));

    Future<void> start() async {
      await _recordStart(flavor, useSentry, previousEvents);
      listenPlatformSignals((type, data) => Telemetry.event(type,
          level: type == 'web.offline' || type == 'web.freeze'
              ? TelemetryLevel.warning
              : TelemetryLevel.info,
          data: {...data, ...kioskSnapshot()}));
      _watchTimers();
      await appRunner();
    }

    if (!useSentry) return start();

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = flavor;
        options.enableLogs = true;
        options.sendDefaultPii = false;
        // Only what Telemetry records: `print` output may carry anything.
        options.enablePrintBreadcrumbs = false;
        options.tracesSampleRate = 0;
        options.beforeSend = (event, hint) => _beforeSend(event, budget);
        options.beforeSendLog = _beforeSendLog;
      },
      appRunner: start,
    );
  }

  static Future<void> _recordStart(
      String flavor, bool useSentry, int previousEvents) async {
    String? version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    Telemetry.event('app.start', data: {
      'version': version,
      'flavor': flavor,
      'web': kIsWeb,
      'sentry': useSentry,
      'storedEvents': previousEvents,
      ...platformStartInfo(),
    });
    Telemetry.setContext({'app.version': version, 'app.flavor': flavor});
  }

  /// Reports when a 30 s timer fires late: Chrome throttles the timers of a
  /// hidden tab (to once a minute after 5 minutes), and every health check
  /// and payment poll of the kiosk runs on timers.
  static void _watchTimers() {
    final watch = Stopwatch()..start();
    Timer.periodic(timerCheck, (_) {
      final actual = watch.elapsed;
      watch.reset();
      if (actual > timerCheck * 2) {
        Telemetry.event('web.timer_throttled',
            level: TelemetryLevel.warning,
            data: {
              'expectedMs': timerCheck.inMilliseconds,
              'actualMs': actual.inMilliseconds,
              ...kioskSnapshot(),
            });
      }
    });
  }

  static StreamSubscription<AuthState>? _authSub;

  /// Keeps who this kiosk is (contribuyente, device, branch) on every event
  /// sent, as the login and the device selection change.
  static void followAuth(AuthBloc auth) {
    void apply(AuthState state) => Telemetry.setContext({
          'contribuyente.id': state.currentContribuyente?.id,
          'dispositivo.id': state.currentDevice?.id,
          'dispositivo.nombre': state.currentDevice?.nombre,
          'sucursal.id': state.currentSucursal?.id,
        });
    apply(auth.state);
    _authSub?.cancel();
    _authSub = auth.stream
        .distinct((a, b) =>
            a.currentContribuyente?.id == b.currentContribuyente?.id &&
            a.currentDevice?.id == b.currentDevice?.id &&
            a.currentDevice?.nombre == b.currentDevice?.nombre &&
            a.currentSucursal?.id == b.currentSucursal?.id)
        .listen(apply);
  }

  /// Uncaught errors reach Sentry through its own integrations: count them
  /// against the same issue budget, keep them on the device, and scrub their
  /// text. Issues created by [SentryTelemetrySink] were already counted.
  static SentryEvent? _beforeSend(SentryEvent event, SendBudget budget) {
    if (event.tags?[SentryTelemetrySink.originTag] == '1') return event;
    final exception = event.exceptions?.firstOrNull;
    final type = exception?.type ?? 'message';
    final value = TelemetryRedactor.scrub(
        exception?.value ?? event.message?.formatted ?? '');
    final allowed = budget.allowIssue('error.uncaught:$type:${value.length > 60 ? value.substring(0, 60) : value}');
    // Recorded through the buffer only: sending it as a log too would count
    // the same crash twice.
    Telemetry.instance.buffer.add(TelemetryEvent(
      seq: 0,
      ts: DateTime.now(),
      upMs: Telemetry.instance.uptime.inMilliseconds,
      type: 'error.uncaught',
      level: TelemetryLevel.error,
      data: {'type': type, 'message': value, 'sent': allowed},
    ));
    if (!allowed) return null;
    for (final e in event.exceptions ?? const <SentryException>[]) {
      if (e.value != null) e.value = TelemetryRedactor.scrub(e.value!);
    }
    final message = event.message;
    if (message != null) message.formatted = TelemetryRedactor.scrub(message.formatted);
    for (final crumb in event.breadcrumbs ?? const <Breadcrumb>[]) {
      if (crumb.message != null) crumb.message = TelemetryRedactor.scrub(crumb.message!);
    }
    return event;
  }

  static SentryLog? _beforeSendLog(SentryLog log) {
    log.body = TelemetryRedactor.scrub(log.body);
    return log;
  }
}
