// Runs the kiosk's own IzifyPosClient against a REAL terminal running a PayPOS
// debug build wired to the stand-in broker (izi-paypos/tools/e2e):
//
//   IZIFY_POS_IP=192.168.0.18 IZIFY_BROKER=http://127.0.0.1:8990 \
//     fvm flutter test test/live/izify_pos_live_test.dart
//
// Skipped unless IZIFY_POS_IP is set. Never point it at a terminal wired to
// EcoPay's real broker: it sends real charges.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/domain/models/pos_payment_result.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  final ip = Platform.environment['IZIFY_POS_IP'];
  final broker = Platform.environment['IZIFY_BROKER'] ?? 'http://127.0.0.1:8990';
  final skip = ip == null ? 'set IZIFY_POS_IP to run against a real terminal' : null;

  final client = IzifyPosClient();
  final address = IzifyPosAddress(ip ?? '127.0.0.1');
  const kioskId = 'LIVE-DART-KIOSK';

  Future<void> scenario(Map<String, Object> body) async {
    final http = HttpClient();
    final req = await http.postUrl(Uri.parse('$broker/_scenario'));
    req.headers.contentType = ContentType.json;
    final bytes = utf8.encode(jsonEncode(body));
    req.contentLength = bytes.length; // the stand-in broker needs it
    req.add(bytes);
    await (await req.close()).drain();
    http.close();
  }

  test('the kiosk client pairs, charges and reads the verdict from a real terminal', () async {
    final health = await client.health(address);
    expect(health.ecopayInstalled, isTrue, reason: 'install EcoPay MQTT on the terminal');

    final token = await client.pair(address, kioskId: kioskId, pin: '4826', ecopay: const {
      'mqttClientId': 'CAJA1000999',
      'mqttUserName': '1000999',
      'mqttPassword': 'PWD999',
      'commerceId': '22000999',
      'cajaId': '1',
    });
    expect((await client.health(address)).notReadyReason, isNull);

    // Approved charge, heard on the socket the payment bloc listens to.
    await scenario({'mode': 'approve', 'delay': 3});
    final socket = WebSocketChannel.connect(address.paymentUpdates(token));
    await socket.ready;
    final reference = IzifyPosClient.newReference();
    final verdict = socket.stream
        .map((m) => PosPaymentResult.fromJson(jsonDecode(m as String) as Map))
        .firstWhere((r) => r.reference == reference && r.isTerminal);
    await client.pay(address, token: token, amount: '12500.00', currency: 'COP', reference: reference, cardType: 'CREDITO', quotas: 3);
    expect((await client.paymentStatus(address, token: token, reference: reference)).status,
        anyOf(PosPaymentStatus.processing, PosPaymentStatus.success));
    final result = await verdict.timeout(const Duration(seconds: 30));
    expect(result.status, PosPaymentStatus.success);
    expect((await client.paymentStatus(address, token: token, reference: reference)).transactionId,
        result.transactionId);
    await socket.sink.close();

    // A resent reference is never charged twice.
    final dup = await client
        .pay(address, token: token, amount: '12500.00', currency: 'COP', reference: reference, cardType: 'CREDITO', quotas: 3)
        .then<Object?>((_) => null, onError: (e) => e);
    expect((dup as IzifyPosException).outcomeUnknown, isTrue);

    // A decline carries the acquirer message back to the kiosk.
    await scenario({'mode': 'decline', 'delay': 2});
    final declined = IzifyPosClient.newReference();
    await client.pay(address, token: token, amount: '5000.00', currency: 'COP', reference: declined, cardType: 'DEBITO', quotas: 0);
    PosPaymentResult status;
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    do {
      await Future<void>.delayed(const Duration(seconds: 1));
      status = await client.paymentStatus(address, token: token, reference: declined);
    } while (!status.isTerminal && DateTime.now().isBefore(deadline));
    expect(status.status, PosPaymentStatus.error);
    expect(status.errorMessage, 'FONDOS INSUFICIENTES');

    // Unknown references are reported as never received.
    expect((await client.paymentStatus(address, token: token, reference: 'KOS-NEVER-SENT')).status,
        PosPaymentStatus.notFound);

    await client.unpair(address, token);
    expect((await client.health(address)).paired, isFalse);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
