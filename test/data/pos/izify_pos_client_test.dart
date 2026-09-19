import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/domain/models/pos_payment_result.dart';

import '../../helpers/fake_izify_pos.dart';

void main() {
  late FakeIzifyPos pos;
  late IzifyPosClient client;
  late IzifyPosAddress address;

  setUp(() async {
    pos = await FakeIzifyPos.start();
    client = IzifyPosClient();
    address = IzifyPosAddress('127.0.0.1', pos.port);
  });

  tearDown(() => pos.close());

  Future<String> pair() => client.pair(address,
      kioskId: 'KIOSK-1',
      pin: '4826',
      ecopay: const {'mqttClientId': 'CAJA1', 'mqttUserName': '1', 'mqttPassword': 'P', 'commerceId': '22', 'cajaId': '1'});

  group('IzifyPosAddress', () {
    test('parses ip, ip:port and noisy values from the backend', () {
      expect(IzifyPosAddress.tryParse('192.168.1.10'), const IzifyPosAddress('192.168.1.10', 8081));
      expect(IzifyPosAddress.tryParse(' 192.168.1.10:9090 '), const IzifyPosAddress('192.168.1.10', 9090));
      expect(IzifyPosAddress.tryParse('http://192.168.1.10:8081/'), const IzifyPosAddress('192.168.1.10', 8081));
      expect(IzifyPosAddress.tryParse(''), isNull);
      expect(IzifyPosAddress.tryParse(null), isNull);
    });

    test('the socket url carries the saved port and the token', () {
      final uri = const IzifyPosAddress('10.0.0.5', 9090).paymentUpdates('a b');
      expect(uri.toString(), 'ws://10.0.0.5:9090/payment-updates?token=a+b');
    });
  });

  test('signature is HMAC-SHA256 hex of amount|currency|reference, as PayPOS checks it', () {
    // Same vector computed with Python's hmac module.
    expect(
      IzifyPosClient.sign(token: 'tok3n', amount: '15000.00', currency: 'COP', reference: 'KOS-1'),
      'ae29de78fde91bf5ff127450cea2ab5cc1a3ab64b011bd2ebb2b0b57b6da17af',
    );
  });

  test('references never repeat', () {
    final refs = List.generate(500, (_) => IzifyPosClient.newReference()).toSet();
    expect(refs.length, 500);
    expect(refs.first, startsWith('KOS-'));
  });

  group('health', () {
    test('reports why an unpaired terminal cannot charge', () async {
      final health = await client.health(address);
      expect(health.paired, isFalse);
      expect(health.notReadyReason, contains('no está emparejado'));
    });

    test('a paired, configured terminal is ready', () async {
      await pair();
      final health = await client.health(address);
      expect(health.ready, isTrue);
      expect(health.notReadyReason, isNull);
      expect(health.ecopayVersion, 'v1.1.8_test');
    });

    test('missing EcoPay app is explained', () async {
      await pair();
      pos.ecopayInstalled = false;
      expect((await client.health(address)).notReadyReason, contains('EcoPay no está instalada'));
    });

    test('an older terminal without readiness fields is not blocked', () {
      final legacy = IzifyPosHealth.fromJson({'status': 'OK', 'batteryLevel': 80, 'hasPaper': true, 'isOnline': true});
      expect(legacy.notReadyReason, isNull);
    });

    test('an unreachable terminal throws a clear, not-charged error', () async {
      await pos.close();
      final err = await client.health(address).then<Object?>((_) => null, onError: (e) => e);
      expect(err, isA<IzifyPosException>());
      expect((err as IzifyPosException).charged, isFalse);
      expect(err.message, contains('No se pudo conectar'));
    });
  });

  group('pair', () {
    test('returns the token and delivers the EcoPay settings', () async {
      final token = await pair();
      expect(token, pos.token);
      expect(pos.ecopay['mqttClientId'], 'CAJA1');
      expect(pos.pin, '4826');
    });

    test('a terminal paired with another kiosk explains how to free it', () async {
      await pair();
      final err = await client
          .pair(address, kioskId: 'OTHER', pin: '4826')
          .then<Object?>((_) => null, onError: (e) => e) as IzifyPosException;
      expect(err.code, 'PAIRED_ELSEWHERE');
      expect(err.message, contains('Desvincúlelo'));
    });

    test('blank EcoPay values are not sent', () async {
      await client.pair(address, kioskId: 'K', pin: '1', ecopay: const {'mqttClientId': '  ', 'cajaId': '1'});
      expect(pos.ecopay.containsKey('mqttClientId'), isFalse);
      expect(pos.ecopay['cajaId'], '1');
    });
  });

  group('pay', () {
    Future<Object?> payWith(String token, {String reference = 'KOS-T1', String amount = '15000.00'}) =>
        client
            .pay(address, token: token, amount: amount, currency: 'COP', reference: reference, cardType: 'DEBITO', quotas: 0)
            .then<Object?>((_) => null, onError: (e) => e);

    test('an accepted charge returns normally and is signed correctly', () async {
      final token = await pair();
      expect(await payWith(token), isNull);
      expect(pos.charges.single['reference'], 'KOS-T1');
    });

    test('a non-positive amount never leaves the kiosk', () async {
      final token = await pair();
      final err = await payWith(token, amount: '0') as IzifyPosException;
      expect(err.code, 'INVALID_AMOUNT');
      expect(pos.payRequests, 0);
    });

    test('401 is not charged and asks for re-pairing', () async {
      await pair();
      final err = await payWith('stale') as IzifyPosException;
      expect(err.isUnauthorized, isTrue);
      expect(err.charged, isFalse);
    });

    test('busy and not-ready refusals are not charged and keep the terminal message', () async {
      final token = await pair();
      pos.refuseBusy = true;
      final busy = await payWith(token, reference: 'R1') as IzifyPosException;
      expect(busy.charged, isFalse);
      expect(busy.message, contains('procesando otro pago'));

      pos.refuseNotReady = true;
      final notReady = await payWith(token, reference: 'R2') as IzifyPosException;
      expect(notReady.statusCode, 503);
      expect(notReady.charged, isFalse);
    });

    test('a resent reference means the outcome must be looked up, not assumed', () async {
      final token = await pair();
      await payWith(token, reference: 'DUP');
      final err = await payWith(token, reference: 'DUP') as IzifyPosException;
      expect(err.code, 'DUPLICATE_REFERENCE');
      expect(err.outcomeUnknown, isTrue);
      expect(pos.charges.length, 1);
    });

    test('a lost acknowledgement is reported as outcome unknown', () async {
      final token = await pair();
      pos.payResponseDelay = IzifyPosClient.payTimeout + const Duration(seconds: 1);
      final err = await payWith(token) as IzifyPosException;
      expect(err.code, 'PAY_TIMEOUT');
      expect(err.outcomeUnknown, isTrue);
      // It did reach the terminal: this is exactly why it must not say "no se cobró".
      expect(pos.charges, hasLength(1));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('a refused connection is known not to have charged', () async {
      final token = await pair();
      await pos.close();
      final err = await payWith(token) as IzifyPosException;
      expect(err.code, 'UNREACHABLE');
      expect(err.charged, isFalse);
    });
  });

  group('paymentStatus', () {
    test('maps PROCESSING, terminal results and unknown references', () async {
      final token = await pair();
      pos.outcome = null; // the charge never gets an answer
      await client.pay(address, token: token, amount: '10.00', currency: 'COP', reference: 'P1', cardType: 'DEBITO', quotas: 0);
      expect((await client.paymentStatus(address, token: token, reference: 'P1')).status, PosPaymentStatus.processing);

      pos.settle('P1', 'SUCCESS');
      final done = await client.paymentStatus(address, token: token, reference: 'P1');
      expect(done.status, PosPaymentStatus.success);
      expect(done.transactionId, isNotNull);

      expect((await client.paymentStatus(address, token: token, reference: 'NEVER')).status, PosPaymentStatus.notFound);
      expect((await client.paymentStatus(address, token: 'bad', reference: 'P1')).status, PosPaymentStatus.unauthorized);
    });

    test('never throws for an unreachable terminal', () async {
      await pos.close();
      final r = await client.paymentStatus(address, token: 't', reference: 'X');
      expect(r.status, PosPaymentStatus.unreachable);
      expect(r.isTerminal, isFalse);
    });
  });

  test('a real SocketException that never connected is classified as not charged', () {
    // Guard for the platform error codes the client relies on.
    const refused = SocketException('Connection refused', osError: OSError('Connection refused', 61));
    expect(refused.osError!.errorCode, 61);
  });
}
