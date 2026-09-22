// Full path with the REAL EcoPay MQTT app, on a terminal set up with the
// izi-paypos full-path rig (tools/fullpath: local TMS + MQTT broker + bridge):
//
//   kiosk client → PayPOS → bridge → mosquitto → EcoPay app (card screen)
//                ← PayPOS ← bridge ← mosquitto ← EcoPay answer
//
//   IZIFY_POS_IP=192.168.0.18 IZIFY_FULLPATH=1 \
//     fvm flutter test test/live/izify_pos_fullpath_test.dart
//
// With no card presented, EcoPay's card read times out (30 s) and it answers
// with an error that never reached a bank: the kiosk must get a definitive
// "not charged". Present a card to exercise the bank leg instead (the rig's
// ISO host never approves, so expect PENDING then).
//
// Skipped unless both variables are set. Never point it at a terminal wired
// to EcoPay's real broker: it sends real charges.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/domain/models/pos_payment_result.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  final ip = Platform.environment['IZIFY_POS_IP'];
  final enabled = Platform.environment['IZIFY_FULLPATH'] == '1';
  final skip = ip == null || !enabled
      ? 'set IZIFY_POS_IP and IZIFY_FULLPATH=1 on a terminal wired to the full-path rig'
      : null;

  final client = IzifyPosClient();
  final address = IzifyPosAddress(ip ?? '127.0.0.1');

  test('a kiosk charge travels through the real EcoPay app and back', () async {
    final health = await client.health(address);
    expect(health.ecopayInstalled, isTrue);

    final token = await client.pair(address, kioskId: 'FULLPATH-KIOSK', pin: '4826', ecopay: const {
      'mqttClientId': 'CAJA1000999',
      'mqttUserName': '1000999',
      'mqttPassword': 'PWD999',
      'commerceId': '22000999',
      'cajaId': '1',
    });
    expect((await client.health(address)).notReadyReason, isNull);

    // Refused by PayPOS before anything reaches EcoPay.
    final low = await client
        .pay(address, token: token, amount: '1500.00', currency: 'COP',
            reference: IzifyPosClient.newReference(), cardType: 'DEBITO', quotas: 0)
        .then<Object?>((_) => null, onError: (e) => e);
    expect((low as IzifyPosException).code, 'AMOUNT_TOO_LOW');
    expect(low.charged, isFalse);

    final socket = WebSocketChannel.connect(address.paymentUpdates(token));
    await socket.ready;
    final reference = IzifyPosClient.newReference();
    final verdict = socket.stream
        .map((m) => PosPaymentResult.fromJson(jsonDecode(m as String) as Map))
        .firstWhere((r) => r.reference == reference && r.isTerminal);

    final started = DateTime.now();
    await client.pay(address, token: token, amount: '12500.00', currency: 'COP',
        reference: reference, cardType: 'DEBITO', quotas: 0);
    final result = await verdict.timeout(const Duration(seconds: 150));
    final took = DateTime.now().difference(started);
    // ignore: avoid_print
    print('VERDICT after ${took.inSeconds}s: ${result.status} "${result.errorMessage}" txn=${result.transactionId}');

    // The answer came from EcoPay itself (not PayPOS's own 90 s timeout).
    expect(took, lessThan(const Duration(seconds: 85)));
    expect(result.status, anyOf(PosPaymentStatus.error, PosPaymentStatus.pending, PosPaymentStatus.success));
    final status = await client.paymentStatus(address, token: token, reference: reference);
    expect(status.status, result.status);
    await socket.sink.close();

    await client.unpair(address, token);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 4)));
}
