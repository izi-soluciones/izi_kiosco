import 'package:flutter/services.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';

/// The values of `state.printer.route` and of the `route` of the print
/// events (contracts §4.1, §5.1): how the kiosk prints its tickets.
class PrintRoute {
  const PrintRoute._();

  /// The browser's print dialog (Chrome in kiosk mode prints it silently).
  static const String webPdf = 'web_pdf';

  /// The SAT / Masung USB printer of the Android kiosks.
  static const String sat = 'sat';

  /// The AutoReply printer of the Android kiosks.
  static const String autoreply = 'autoreply';

  /// The printer built into Sunmi devices.
  static const String sunmi = 'sunmi';
  static const String none = 'none';
}

/// What the kiosk knows about its ticket printer, from the tickets it
/// printed: the heartbeat's `state.printer` (contracts §4.1). It also
/// records the `print.ok` / `print.failed` events (§5.1), which the
/// heartbeat counters count.
///
/// Only what printing already learnt: it never asks the printer anything.
/// Never throws: a ticket must print the same with or without it.
class PrinterHealth {
  final DateTime Function() _now;
  String? _route;
  DateTime? _lastOkAt;
  String? _lastError;
  bool? _hasPaper;

  PrinterHealth({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static PrinterHealth _instance = PrinterHealth();

  static PrinterHealth get instance => _instance;

  /// Replaces the global instance (in tests).
  static void install(PrinterHealth health) => _instance = health;

  /// A ticket went out by [route] in [ms]. [hasPaper] is what the printer
  /// said before, when it says.
  void printed(String route, {required int ms, bool? hasPaper}) {
    try {
      _route = route;
      _lastOkAt = _now();
      _lastError = null;
      if (hasPaper != null) _hasPaper = hasPaper;
      Telemetry.event('print.ok', data: {'route': route, 'ms': ms});
    } catch (_) {}
  }

  /// The ticket did not print by [route]. [cause] is a short code (see
  /// [causeOf]), never the error's text.
  void failed(String route, {required String cause, bool? hasPaper}) {
    try {
      _route = route;
      _lastError = cause;
      if (hasPaper != null) _hasPaper = hasPaper;
      Telemetry.event('print.failed',
          level: TelemetryLevel.warning, data: {'route': route, 'cause': cause});
    } catch (_) {}
  }

  /// `state.printer`, or null while nothing was printed since the start.
  Map<String, Object?>? toJson() {
    final route = _route;
    if (route == null) return null;
    return {
      'route': route,
      'lastOkAt': _lastOkAt?.toUtc().toIso8601String(),
      'lastError': _lastError,
      'hasPaper': _hasPaper,
    };
  }

  /// A short, stable code for why printing failed: the platform channel's
  /// error code (`PRINT_ERROR`), or the error's type. Never its message,
  /// which may carry the ticket.
  static String causeOf(Object error) {
    if (error is PlatformException) return error.code;
    if (error is MissingPluginException) return 'missing_plugin';
    return error.runtimeType.toString();
  }

  /// What a Sunmi printer status (`PrinterStatus.name`) says about the
  /// ticket printed under it: null when it should have printed, else the
  /// cause it did not.
  static String? sunmiProblem(String status) => switch (status) {
        'ERROR' => 'printer_error',
        'OUT_OF_PAPER' => 'out_of_paper',
        'OPEN_THE_LID' => 'lid_open',
        'OVERHEATED' => 'overheated',
        'PAPER_CUTTER_ABNORMAL' => 'cutter_error',
        'NO_PRINTER_DETECTED' => 'no_printer',
        'ABNORMAL_COMMUNICATION' => 'communication_error',
        'EXCEPTION' => 'printer_exception',
        _ => null,
      };

  /// Whether a Sunmi printer status says there is paper; null when it does
  /// not tell.
  static bool? sunmiHasPaper(String status) => switch (status) {
        'OUT_OF_PAPER' => false,
        'NORMAL' => true,
        _ => null,
      };
}
