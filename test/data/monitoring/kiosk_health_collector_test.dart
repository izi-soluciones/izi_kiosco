import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_collector.dart';
import 'package:izi_kiosco/data/monitoring/pos_link_health.dart';
import 'package:izi_kiosco/data/pos/card_charge_recovery.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/pos_config/pos_config_bloc.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:shared_preferences/shared_preferences.dart';

AuthState _auth(Map<String, dynamic> config) => AuthState.init().copyWith(
    status: AuthStatus.okAuth,
    currentDevice: Device.fromJson(
        {'id': 7, 'sucursal': 1, 'nombre': 'KIOSKO-01', 'caja': 1, 'config': config}));

void main() {
  late DateTime now;
  late PosLinkHealth link;
  late KioskActivity activity;
  IzifyPosSession? session;
  IzifyPosAddress? configured;

  KioskHealthCollector build({Future<int> Function()? pending}) => KioskHealthCollector(
        activity: () => activity,
        link: () => link,
        session: (_) async => session,
        configuredAddress: (_) async => configured,
        posName: () async => 'izify-POS-stored',
        pendingCardErrors: pending ?? () async => 0,
        visibility: () => 'visible',
        online: () => true,
        now: () => now,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 10, 12, 14);
    link = PosLinkHealth(now: () => now, counters: () => KioskCounters());
    activity = KioskActivity();
    session = null;
    configured = null;
  });

  tearDown(CardChargeRecovery.active.clear);

  test('an Izify POS paired on this kiosk, with what the POS configuration knows', () async {
    session = const IzifyPosSession(IzifyPosAddress('192.168.1.50'), 'tok');
    final terminal = IzifyPosHealth.fromJson({'status': 'OK', 'paired': true, 'batteryLevel': 50});
    link.answered(address: '192.168.1.50:8081', ms: 40);
    final collector = build()
      ..attachStates(
          auth: () => _auth({'ipEcopay': '192.168.1.50'}),
          posConfig: () => PosConfigState.init().copyWith(health: () => terminal));
    activity.screenChanged(RoutesKeys.homeLink);

    final snapshot = await collector.collect();
    final json = snapshot.toJson();
    expect(json['screen'], '/home');
    expect(json['mode'], 'idle');
    expect(json['online'], isTrue);
    expect(json['visibility'], 'visible');
    expect(json['chargeInProgress'], isFalse);
    final pos = json['pos'] as Map;
    expect(pos['provider'], 'izify');
    expect(pos['status'], 'ok');
    expect(pos['address'], '192.168.1.50:8081');
    expect(pos['name'], 'izify-POS-stored');
    expect((pos['terminal'] as Map)['battery'], 50);
  });

  test('an Izify POS configured but never paired is unpaired', () async {
    configured = const IzifyPosAddress('192.168.1.50', 8081);
    final collector = build()..attachStates(auth: () => _auth({'ipEcopay': '192.168.1.50'}));
    final pos = (await collector.collect()).pos;
    expect(pos.provider, 'izify');
    expect(pos.status, 'unpaired');
    expect(pos.address, '192.168.1.50:8081');
  });

  test('Linkser before ATC, as the payment page chooses', () async {
    link.answered(ms: 15);
    var collector = build()
      ..attachStates(auth: () => _auth({'ipLinkser': '10.0.0.8', 'ipAtc': '10.0.0.9'}));
    var pos = (await collector.collect()).pos;
    expect(pos.provider, 'linkser');
    expect(pos.address, '10.0.0.8');
    expect(pos.status, 'ok');

    collector = build()..attachStates(auth: () => _auth({'ipAtc': '10.0.0.9'}));
    pos = (await collector.collect()).pos;
    expect(pos.provider, 'atc');
    expect(pos.address, '10.0.0.9');
  });

  test('no terminal configured', () async {
    final collector = build()..attachStates(auth: () => _auth({}));
    expect((await collector.collect()).pos.status, 'not_configured');
  });

  test('before the login is attached it still answers', () async {
    final snapshot = await build().collect();
    expect(snapshot.pos.provider, 'none');
    expect(snapshot.mode, 'idle');
  });

  test('a charge on its way makes the mode paying', () async {
    activity
      ..screenChanged(RoutesKeys.paymentLink)
      ..paymentBusyChanged(true);
    final snapshot = await build().collect();
    expect(snapshot.chargeInProgress, isTrue);
    expect(snapshot.mode, 'paying');
  });

  test('a source that fails leaves its part unknown, never the whole snapshot', () async {
    final collector = KioskHealthCollector(
      activity: () => activity,
      link: () => throw StateError('link'),
      session: (_) async => throw StateError('prefs'),
      pendingCardErrors: () async => throw StateError('prefs'),
      visibility: () => throw StateError('js'),
      online: () => throw StateError('js'),
    )
      ..attachStates(auth: () => _auth({'ipEcopay': '192.168.1.50'}))
      ..printer = (() => throw StateError('printer'));
    final snapshot = await collector.collect();
    expect(snapshot.pos.provider, 'none');
    expect(snapshot.pendingCardErrors, 0);
    expect(snapshot.visibility, isNull);
    expect(snapshot.printer, isNull);
  });

  test('the sections other tasks fill go in once they do', () async {
    final collector = build()
      ..printer = (() => {'route': 'web_pdf'})
      ..agent = (() => {'reachable': true, 'enrolled': false})
      ..telemetryBacklog = (() => 12);
    final json = (await collector.collect()).toJson();
    expect(json['printer'], {'route': 'web_pdf'});
    expect(json['agent'], {'reachable': true, 'enrolled': false});
    expect(json['telemetryBacklog'], 12);
  });

  group('pending card errors', () {
    String row(String status, {String reference = 'KOS-1', String response = ''}) => jsonEncode(
        CardPayment(
                response: response,
                cardNumber: '****',
                date: '2026-10-12',
                hour: '14:00',
                reference: reference,
                status: status)
            .toJson());

    test('counts the charges someone has to look at', () async {
      SharedPreferences.setMockInitialValues({
        'cardErrors': [
          row('SUCCESS', reference: 'A', response: 'Aprobada - pedido registrado'),
          row('SUCCESS', reference: 'B', response: 'Aprobada - Error sync server: 500'),
          row('ERROR', reference: 'C', response: 'Rechazada'),
          row('PENDING', reference: 'D'),
          row('UNKNOWN', reference: 'E'),
          row('IN_PROGRESS', reference: 'F'),
          row('IN_PROGRESS', reference: 'G'),
          'not json',
        ],
      });
      CardChargeRecovery.active.add('G');
      // B (not registered), D, E (unconfirmed), F (cut off, nobody waiting).
      expect(await KioskHealthCollector.countPendingCardErrors(), 4);
    });

    test('an empty list is none', () async {
      expect(await KioskHealthCollector.countPendingCardErrors(), 0);
    });
  });
}
