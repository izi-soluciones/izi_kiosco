import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_snapshot.dart';
import 'package:izi_kiosco/data/monitoring/pos_link_health.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';

final _okAt = DateTime.utc(2026, 10, 12, 14, 2);

PosLinkView _answered({String? notReady, bool failedRecently = false, IzifyPosHealth? terminal}) =>
    PosLinkView(
        lastOk: true,
        lastOkAt: _okAt,
        notReadyReason: notReady,
        failedRecently: failedRecently,
        latencyMsP50: 85,
        terminal: terminal);

PosLinkView _failing(int failures, {String cause = 'timeout'}) => PosLinkView(
    lastOk: false,
    lastOkAt: _okAt,
    consecutiveFailures: failures,
    lastCause: cause,
    failedRecently: true);

final _terminal = IzifyPosHealth.fromJson({
  'status': 'OK',
  'paired': true,
  'ready': true,
  'isOnline': true,
  'hasPaper': true,
  'batteryLevel': 80,
  'appVersion': '1.29',
  'ecopayVersion': '1.1.8',
  'ecopayConnected': true,
  'terminalType': 'ECOPAY',
  'name': 'izify-POS-1234',
});

void main() {
  group('status rules (contracts §4.1)', () {
    String status(PosLinkView link, {String provider = PosProvider.izify, bool paired = true}) =>
        PosLinkStatus.of(provider: provider, paired: paired, link: link);

    test('not_configured when the kiosk charges with no terminal', () {
      expect(status(_failing(5), provider: PosProvider.none, paired: false),
          PosLinkStatus.notConfigured);
    });

    test('unpaired when there is no pairing, whatever the checks say', () {
      expect(status(_answered(), paired: false), PosLinkStatus.unpaired);
      expect(status(_failing(5), paired: false), PosLinkStatus.unpaired);
    });

    test('down from three failures in a row', () {
      expect(status(_failing(3)), PosLinkStatus.down);
      expect(status(_failing(12)), PosLinkStatus.down);
      expect(status(_failing(3), provider: PosProvider.atc), PosLinkStatus.down);
    });

    test('ok when the last check answered, it can charge and nothing failed lately', () {
      expect(status(_answered()), PosLinkStatus.ok);
      expect(status(_answered(), provider: PosProvider.linkser), PosLinkStatus.ok);
    });

    test('degraded when it answered but failed within 5 minutes', () {
      expect(status(_answered(failedRecently: true)), PosLinkStatus.degraded);
    });

    test('degraded when it answered but cannot charge', () {
      expect(status(_answered(notReady: 'Sin internet')), PosLinkStatus.degraded);
    });

    test('degraded after one or two misses, and before the first check', () {
      expect(status(_failing(1)), PosLinkStatus.degraded);
      expect(status(_failing(2)), PosLinkStatus.degraded);
      expect(status(PosLinkView.none), PosLinkStatus.degraded);
    });
  });

  group('state.pos', () {
    test('an Izify POS that answers: its report, ready, no cause', () {
      final pos = PosHealthSnapshot.build(
          provider: PosProvider.izify,
          paired: true,
          link: _answered(terminal: _terminal),
          address: '192.168.1.50:8081',
          name: 'stored-name');
      expect(pos.toJson(), {
        'provider': 'izify',
        'status': 'ok',
        'address': '192.168.1.50:8081',
        'name': 'izify-POS-1234',
        'lastOkAt': '2026-10-12T14:02:00.000Z',
        'latencyMsP50': 85,
        'consecutiveFailures': 0,
        'lastCause': null,
        'ready': true,
        'notReadyReason': null,
        'terminal': {
          'battery': 80,
          'hasPaper': true,
          'isOnline': true,
          'ecopayConnected': true,
          'appVersion': '1.29',
          'ecopayVersion': '1.1.8',
          'terminalType': 'ECOPAY',
        },
      });
    });

    test('the POS configuration report stands in until a health loop reports', () {
      final pos = PosHealthSnapshot.build(
          provider: PosProvider.izify,
          paired: true,
          link: _answered(),
          name: 'izify-POS-9',
          terminal: _terminal);
      expect(pos.terminal, same(_terminal));
    });

    test('a terminal down says why and is not ready', () {
      final pos = PosHealthSnapshot.build(
          provider: PosProvider.izify,
          paired: true,
          link: _failing(4, cause: 'refused'),
          address: '192.168.1.50:8081',
          problem: 'El datáfono no responde en 192.168.1.50.');
      expect(pos.status, 'down');
      expect(pos.ready, isFalse);
      expect(pos.lastCause, 'refused');
      expect(pos.consecutiveFailures, 4);
      expect(pos.notReadyReason, 'El datáfono no responde en 192.168.1.50.');
      expect(pos.lastOkAt, _okAt);
    });

    test('a terminal that says it is not paired is unpaired', () {
      final pos = PosHealthSnapshot.build(
          provider: PosProvider.izify,
          paired: true,
          link: _answered(
              notReady: 'El datáfono no está emparejado con este kiosko.',
              terminal: IzifyPosHealth.fromJson({'status': 'OK', 'paired': false})));
      expect(pos.status, 'unpaired');
      expect(pos.ready, isFalse);
    });

    test('ATC and Linkser have no report of their own', () {
      final pos = PosHealthSnapshot.build(
          provider: PosProvider.atc,
          paired: true,
          link: _answered(terminal: _terminal),
          address: '10.0.0.9',
          name: 'ignored');
      final json = pos.toJson();
      expect(json['provider'], 'atc');
      expect(json['status'], 'ok');
      expect(json['ready'], isTrue);
      expect(json['name'], isNull);
      expect(json.containsKey('terminal'), isFalse);
    });

    test('no terminal: not_configured and nothing else', () {
      final pos = PosHealthSnapshot.build(
          provider: PosProvider.none, paired: false, link: _failing(9));
      expect(pos.toJson(), {
        'provider': 'none',
        'status': 'not_configured',
        'address': null,
        'name': null,
        'lastOkAt': null,
        'latencyMsP50': null,
        'consecutiveFailures': 0,
        'lastCause': null,
        'ready': false,
        'notReadyReason': null,
      });
    });
  });

  group('state', () {
    KioskHealthSnapshot snapshot({String? notReady, Map<String, Object?>? printer}) =>
        KioskHealthSnapshot(
          takenAt: _okAt,
          screen: '/payment/:id',
          mode: 'paying',
          online: true,
          visibility: 'visible',
          chargeInProgress: true,
          pos: PosHealthSnapshot.build(
              provider: PosProvider.izify,
              paired: true,
              link: _answered(notReady: notReady)),
          pendingCardErrors: 2,
          printer: printer,
        );

    test('has the contract fields; the unknown sections are left out', () {
      final json = snapshot().toJson();
      expect(json.keys, [
        'screen', 'mode', 'online', 'visibility', 'chargeInProgress', 'pos',
        'pendingCardErrors', 'telemetryBacklog',
      ]);
      expect(json['screen'], '/payment/:id');
      expect(json['mode'], 'paying');
      expect(json['chargeInProgress'], isTrue);
      expect(json['pendingCardErrors'], 2);
      expect(json['telemetryBacklog'], isNull);
      expect((json['pos'] as Map)['status'], 'ok');
    });

    test('a section filled elsewhere goes in', () {
      final json = snapshot(printer: {'route': 'web_pdf', 'lastOkAt': null}).toJson();
      expect(json['printer'], {'route': 'web_pdf', 'lastOkAt': null});
    });

    test('goes through the redactor', () {
      final json = snapshot(
              notReady: 'Token izd_abcDEF123-_x rechazado, tarjeta 4111 1111 1111 1111',
              printer: {'lastError': 'Bearer abc.def', 'password': 'x'})
          .toJson();
      final reason = (json['pos'] as Map)['notReadyReason'] as String;
      expect(reason, isNot(contains('izd_')));
      expect(reason, isNot(contains('4111')));
      expect((json['printer'] as Map)['lastError'], 'Bearer ${TelemetryRedactor.mask}');
      expect((json['printer'] as Map)['password'], TelemetryRedactor.mask);
    });
  });
}
