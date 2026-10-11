import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_diagnostics.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';

void main() {
  Map<String, Object?> event(int i) =>
      {'seq': i, 'ts': '2026-10-12T14:${(i % 60).toString().padLeft(2, '0')}:00.000Z', 'type': 'e$i', 'pad': 'x' * 200};

  int size(Map<String, Object?> report) => utf8.encode(jsonEncode(report)).length;

  test('a report that fits is sent as it is', () {
    final report = {
      'kiosk': {'events': [event(1)]},
      'terminal': {'unavailable': 'not_paired'},
    };
    expect(KioskDiagnostics.fit(report, limit: 10000), report);
  });

  test('a report too big loses its older events first, on both sides', () {
    final report = {
      'kiosk': {'state': {'mode': 'idle'}, 'events': [for (var i = 59; i >= 0; i--) event(i)]},
      'terminal': {'app': {'version': '1.29'}, 'events': [for (var i = 0; i < 60; i++) event(i)]},
    };
    final fitted = KioskDiagnostics.fit(report, limit: 12000);
    expect(size(fitted), lessThanOrEqualTo(12000));
    final kioskEvents = (fitted['kiosk'] as Map)['events'] as List;
    final terminalEvents = (fitted['terminal'] as Map)['events'] as List;
    expect(kioskEvents, isNotEmpty);
    // The newest are kept, whatever order each side lists them in.
    expect((kioskEvents.first as Map)['seq'], 59);
    expect((terminalEvents.first as Map)['seq'], 59);
    expect((fitted['kiosk'] as Map)['state'], {'mode': 'idle'});
    expect((fitted['terminal'] as Map)['app'], {'version': '1.29'});
  });

  test('when even that does not fit, the events go and the terminal is left out', () {
    final report = {
      'kiosk': {'events': [event(1)], 'state': {'blob': 'y' * 5000}},
      'terminal': {'dump': 'z' * 5000},
    };
    final fitted = KioskDiagnostics.fit(report, limit: 1000);
    expect((fitted['kiosk'] as Map)['events'], isEmpty);
    expect(fitted['terminal'], {'unavailable': 'too_large'});
  });

  test('the redaction for a report keeps hundreds of events, and no secret', () {
    final redacted = TelemetryRedactor.redact({
      'kiosk': {
        'events': [for (var i = 0; i < 300; i++) {'seq': i, 'data': {'token': 'izd_secret_value_123456'}}],
      },
    }, maxDepth: 12, maxItems: 1000);
    final events = (redacted['kiosk'] as Map)['events'] as List;
    expect(events, hasLength(300));
    expect(jsonEncode(redacted), isNot(contains('izd_secret')));
    // The default stays as tight as before.
    expect(
        ((TelemetryRedactor.redact({'l': List.generate(50, (i) => i)}))['l'] as List).length, 20);
  });
}
