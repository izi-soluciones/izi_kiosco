import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/printer_health.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
import 'package:sunmi_printer_plus/enums.dart';

void main() {
  late DateTime now;
  late PrinterHealth health;
  late KioskCounters counters;

  setUp(() {
    now = DateTime.utc(2026, 10, 12, 14);
    health = PrinterHealth(now: () => now);
    counters = KioskCounters();
    Telemetry.install(Telemetry(observers: [counters.observe]));
  });

  List<TelemetryEvent> events() =>
      Telemetry.recent().reversed.where((e) => e.type.startsWith('print.')).toList();

  test('nothing printed since the start: no state.printer', () {
    expect(health.toJson(), isNull);
  });

  test('a ticket printed: print.ok with its route and time, counted', () {
    health.printed(PrintRoute.sat, ms: 900);

    final event = events().single;
    expect(event.type, 'print.ok');
    expect(event.data, {'route': 'sat', 'ms': 900});
    expect(counters[KioskCounters.printsOk], 1);
    expect(health.toJson(), {
      'route': 'sat',
      'lastOkAt': '2026-10-12T14:00:00.000Z',
      'lastError': null,
      'hasPaper': null,
    });
  });

  test('a ticket that did not print: print.failed with its cause, counted', () {
    health.printed(PrintRoute.sunmi, ms: 500, hasPaper: true);
    now = now.add(const Duration(minutes: 5));
    health.failed(PrintRoute.sunmi, cause: 'out_of_paper', hasPaper: false);

    final event = events().last;
    expect(event.type, 'print.failed');
    expect(event.level, TelemetryLevel.warning);
    expect(event.data, {'route': 'sunmi', 'cause': 'out_of_paper'});
    expect(counters[KioskCounters.printsFailed], 1);
    expect(health.toJson(), {
      'route': 'sunmi',
      'lastOkAt': '2026-10-12T14:00:00.000Z',
      'lastError': 'out_of_paper',
      'hasPaper': false,
    });
  });

  test('the next ticket that prints clears the error; paper unknown keeps the last word', () {
    health.failed(PrintRoute.sunmi, cause: 'out_of_paper', hasPaper: false);
    health.printed(PrintRoute.sunmi, ms: 400);
    final state = health.toJson()!;
    expect(state['lastError'], isNull);
    expect(state['hasPaper'], isFalse);
  });

  test('the cause is a code, never the error text', () {
    expect(PrinterHealth.causeOf(PlatformException(code: 'PRINT_ERROR', message: 'Total 15000 tarjeta 4111')),
        'PRINT_ERROR');
    expect(PrinterHealth.causeOf(MissingPluginException('printSat')), 'missing_plugin');
    expect(PrinterHealth.causeOf(StateError('ticket de Juan')), 'StateError');
  });

  test('what a Sunmi status says about the ticket printed under it', () {
    expect(PrinterHealth.sunmiProblem(PrinterStatus.NORMAL.name), isNull);
    expect(PrinterHealth.sunmiProblem(PrinterStatus.UNKNOWN.name), isNull,
        reason: 'it prints anyway');
    expect(PrinterHealth.sunmiProblem(PrinterStatus.PREPARING.name), isNull);
    expect(PrinterHealth.sunmiProblem(PrinterStatus.ERROR.name), 'printer_error');
    expect(PrinterHealth.sunmiProblem(PrinterStatus.OUT_OF_PAPER.name), 'out_of_paper');
    expect(PrinterHealth.sunmiProblem(PrinterStatus.OPEN_THE_LID.name), 'lid_open');
    expect(PrinterHealth.sunmiProblem(PrinterStatus.OVERHEATED.name), 'overheated');
    expect(PrinterHealth.sunmiProblem(PrinterStatus.NO_PRINTER_DETECTED.name), 'no_printer');

    expect(PrinterHealth.sunmiHasPaper(PrinterStatus.OUT_OF_PAPER.name), isFalse);
    expect(PrinterHealth.sunmiHasPaper(PrinterStatus.NORMAL.name), isTrue);
    expect(PrinterHealth.sunmiHasPaper(PrinterStatus.OVERHEATED.name), isNull);
  });

  test('a recording that fails never reaches the ticket', () {
    Telemetry.install(Telemetry(observers: [(_) => throw StateError('boom')]));
    expect(() => health.printed(PrintRoute.webPdf, ms: 1), returnsNormally);
    expect(() => health.failed(PrintRoute.webPdf, cause: 'x'), returnsNormally);
  });

  test('a kiosk that prints no ticket reports nothing', () async {
    PrinterHealth.install(health);
    final device = Device.fromJson(
        {'id': 1, 'sucursal': 1, 'nombre': 'K', 'caja': 1, 'config': {'noPrintRollo': true}});
    await PrintUtils().print([IziPrintCut()], device);
    expect(events(), isEmpty);
    expect(health.toJson(), isNull);
  });
}
