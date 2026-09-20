import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_izify_pos.dart';

/// Records the backend notifications the kiosk sends once a card charge is
/// confirmed (`/solicitudes-cobro/{uuid}/notificacion-pos`).
class _MarkingComandaRepository implements ComandaRepository {
  final List<(String, int?)> marked = [];
  final List<Map<String, dynamic>?> proofs = [];
  final List<Map<String, dynamic>> attempts = [];

  @override
  Future<void> markPaymentATC(String chargeUuid, int? internalId, {Map<String, dynamic>? transaccion}) async {
    marked.add((chargeUuid, internalId));
    proofs.add(transaccion);
  }

  @override
  Future<void> reportTerminalResult(String chargeUuid, int? internalId, Map<String, dynamic> transaccion) async {
    attempts.add(transaccion);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Unused implements BusinessRepository, SocketRepository {
  @override
  closeQrListening() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late FakeIzifyPos pos;
  late _MarkingComandaRepository comandas;
  late PaymentBloc bloc;
  late AuthState auth;
  final emitted = <PaymentState>[];

  Device device(FakeIzifyPos pos, {String? pin = '4826'}) => Device.fromJson({
        'id': 7,
        'sucursal': 1,
        'nombre': 'KIOSKO-TEST',
        'caja': 1,
        'config': {
          'ipEcopay': pos.hostPort,
          if (pin != null) 'pin': pin,
          // Numbers on purpose: the backend may store these ids as numbers.
          'ecopayConfig': {
            'mqttClientId': 'CAJA1000999',
            'mqttUserName': 1000999,
            'mqttPassword': 'PWD999',
            'commerceId': 22000999,
            'cajaId': 1,
          },
        },
      });

  CardPayment original({String status = 'ERROR', String? reference}) => CardPayment(
        response: 'Rechazada',
        cardNumber: '****',
        date: '2026-09-19',
        hour: '10:00',
        amount: '15000.00',
        currency: 'COP',
        reference: reference ?? 'KOS-OLD',
        status: status,
        markUuid: 'charge-uuid-1',
        markInternalId: 55,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pos = await FakeIzifyPos.start();
    comandas = _MarkingComandaRepository();
    bloc = PaymentBloc(comandas, _Unused(), _Unused(), izifyPosClient: IzifyPosClient());
    emitted.clear();
    bloc.stream.listen(emitted.add);
    auth = AuthState.init().copyWith(currentDevice: device(pos));
  });

  tearDown(() async {
    await bloc.close();
    await pos.close();
  });

  Iterable<PaymentStatus> statuses() => emitted.map((s) => s.status);

  // Cubit states reach stream listeners asynchronously.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('device config accepts numeric EcoPay ids and a numeric PIN', () {
    final d = Device.fromJson({
      'id': 1, 'sucursal': 1, 'nombre': 'K', 'caja': 1,
      'config': {'pin': 1234, 'ipEcopay': ' 10.0.0.2 ', 'ecopayConfig': {'mqttUserName': 1000220, 'commerceId': 22000169}},
    });
    expect(d.config.pin, '1234');
    expect(d.config.ipEcopay, '10.0.0.2');
    expect(d.config.mqttUserName, '1000220');
    expect(d.config.commerceId, '22000169');
  });

  test('a retry pairs on its own, charges, and registers the order', () async {
    final ok = await bloc.retryCardPayment(auth, original());

    expect(ok, isTrue);
    // Paired automatically from the backend config (nothing was paired yet).
    expect(pos.pairedKioskId, 'KIOSKO-TEST');
    expect(pos.ecopay['mqttUserName'], '1000999');
    expect(await TokenUtils.getPosToken(), pos.token);
    // Exactly one charge, and the backend order was notified.
    expect(pos.charges, hasLength(1));
    expect(comandas.marked, [('charge-uuid-1', 55)]);
    await flush();
    expect(statuses(), contains(PaymentStatus.cardVerified));
  });

  test('a terminal that forgot the kiosk is re-paired before charging', () async {
    await bloc.retryCardPayment(auth, original());
    final firstToken = pos.token;
    // Someone pressed "Desvincular dispositivo" on the terminal.
    pos.pairedKioskId = null;
    pos.token = null;

    final ok = await bloc.retryCardPayment(auth, original(reference: 'KOS-OLD-2'));

    expect(ok, isTrue);
    expect(pos.token, isNot(firstToken));
    expect(await TokenUtils.getPosToken(), pos.token);
  });

  Future<List<CardPayment>> rows() async => [
        for (final e in await LocalStorageCardErrors.getErrors())
          CardPayment.fromJsonStorage(jsonDecode(e)),
      ];

  test('an approved charge sends its proof of payment to iZi and stays in the list', () async {
    final ok = await bloc.retryCardPayment(auth, original());

    expect(ok, isTrue);
    final proof = comandas.proofs.single!;
    expect(proof['estado'], 'APROBADA');
    expect(proof['transactionId'], startsWith('TRX-1-'));
    expect(proof['codigoAutorizacion'], '654321');
    expect(proof['numeroTarjeta'], '****4242');
    expect(proof['marca'], 'VISA');
    expect(proof['terminal'], '11000999');
    expect(proof['recibo'], '000123');
    expect(proof['referenciaKiosko'], startsWith('KOS-'));
    final row = (await rows()).single;
    expect(row.status, 'SUCCESS');
    expect(row.authCode, '654321');
    expect(row.traceNumber, '000123');
  });

  test('a declined attempt is stored with its charge in iZi, never marked paid', () async {
    pos.outcome = 'ERROR';

    expect(await bloc.retryCardPayment(auth, original()), isFalse);
    await flush();

    expect(comandas.marked, isEmpty);
    expect(comandas.attempts.single['estado'], 'RECHAZADA');
    expect(comandas.attempts.single['mensaje'], contains('FONDOS INSUFICIENTES'));
  });

  test('a successful retry replaces the declined row instead of adding one', () async {
    final declined = original();
    await LocalStorageCardErrors.saveCardErrors(jsonEncode(declined.toJson()));

    expect(await bloc.retryCardPayment(auth, declined), isTrue);

    final list = await rows();
    expect(list, hasLength(1));
    expect(list.single.status, 'SUCCESS');
    expect(list.single.canRetry, isFalse, reason: 'a paid sale must never offer Reintentar again');
    expect(list.single.reference, isNot('KOS-OLD'));
  });

  test('a declined retry keeps one row, with the latest attempt', () async {
    final declined = original();
    await LocalStorageCardErrors.saveCardErrors(jsonEncode(declined.toJson()));
    pos.outcome = 'ERROR';

    expect(await bloc.retryCardPayment(auth, declined), isFalse);
    await flush();

    final list = await rows();
    expect(list, hasLength(1));
    expect(list.single.status, 'ERROR');
    expect(list.single.response, contains('FONDOS INSUFICIENTES'));
    expect(list.single.reference, pos.charges.single['reference']);
  });

  test('a terminal unpaired on purpose is not re-paired to charge', () async {
    await bloc.retryCardPayment(auth, original());
    // "Desvincular dispositivo" on the terminal: it is being handed over.
    pos
      ..pairedKioskId = null
      ..token = null
      ..unpairedByUser = true;
    final pairs = pos.pairRequests;

    final ok = await bloc.retryCardPayment(auth, original(reference: 'KOS-OLD-2'));

    expect(ok, isFalse);
    expect(pos.pairRequests, pairs);
    expect(pos.charges, hasLength(1));
  });

  test('a terminal unpaired on purpose is not re-paired even after this kiosk forgot it', () async {
    await bloc.retryCardPayment(auth, original());
    // "Desvincular" on both sides: the terminal was handed to another lane and
    // this kiosk no longer holds a session, so the charge would otherwise take
    // the "pair from scratch" path.
    pos
      ..pairedKioskId = null
      ..token = null
      ..unpairedByUser = true;
    await IzifyPosSession.forget();
    final pairs = pos.pairRequests;

    final ok = await bloc.retryCardPayment(auth, original(reference: 'KOS-OLD-9'));

    expect(ok, isFalse);
    expect(pos.pairRequests, pairs);
    expect(pos.charges, hasLength(1));
  });

  test('another terminal answering at the stored address is never charged', () async {
    await bloc.retryCardPayment(auth, original());
    // The router gave this kiosk's terminal address to a different terminal.
    await TokenUtils.savePosName('izify-POS-00001');

    final ok = await bloc.retryCardPayment(auth, original(reference: 'KOS-OLD-3'));

    expect(ok, isFalse);
    expect(pos.charges, hasLength(1));
  });

  test('a stale token (401) is re-paired and the same charge goes through once', () async {
    await bloc.retryCardPayment(auth, original());
    // The terminal was paired again by the same kiosk elsewhere: our token died
    // but the terminal still reports itself paired.
    await TokenUtils.savePosToken('stale-token');

    final ok = await bloc.retryCardPayment(auth, original(reference: 'KOS-OLD-3'));

    expect(ok, isTrue);
    expect(pos.charges, hasLength(2));
  });

  test('a decline shows the acquirer message and does not register the order', () async {
    pos.outcome = 'ERROR';
    pos.declineMessage = 'FONDOS INSUFICIENTES';

    final ok = await bloc.retryCardPayment(auth, original());

    expect(ok, isFalse);
    expect(comandas.marked, isEmpty);
    await flush();
    final error = emitted.firstWhere((s) => s.status == PaymentStatus.cardError);
    expect(error.errorDescription, 'FONDOS INSUFICIENTES');
  });

  test('a terminal that is not ready refuses up front with the reason', () async {
    await bloc.retryCardPayment(auth, original());
    pos.ecopayInstalled = false;

    final ok = await bloc.retryCardPayment(auth, original(reference: 'KOS-OLD-4'));

    expect(ok, isFalse);
    expect(pos.charges, hasLength(1)); // nothing new was sent
    await flush();
    final error = emitted.lastWhere((s) => s.status == PaymentStatus.cardError);
    expect(error.errorDescription, contains('EcoPay no está instalada'));
  });

  test('an unreachable terminal is a clean "not charged" error', () async {
    await pos.close();
    final ok = await bloc.retryCardPayment(auth, original());
    expect(ok, isFalse);
    await flush();
    final error = emitted.lastWhere((s) => s.status == PaymentStatus.cardError);
    expect(error.errorDescription, contains('No se pudo conectar'));
  });

  test('a lost /pay acknowledgement still ends in the real verdict', () async {
    // The terminal accepts and charges, but its 202 never reaches the kiosk.
    pos.payResponseDelay = IzifyPosClient.payTimeout + const Duration(seconds: 1);
    final ok = await bloc.retryCardPayment(auth, original());
    expect(ok, isTrue);
    expect(pos.charges, hasLength(1));
  }, timeout: const Timeout(Duration(seconds: 40)));

  group('verifyCardPayment', () {
    Future<CardPayment> storedPending(String reference) async {
      final cp = original(status: 'PENDING', reference: reference);
      await LocalStorageCardErrors.saveCardErrors(jsonEncode(cp.toJson()));
      return cp;
    }

    Future<Map> stored(String reference) async => (await LocalStorageCardErrors.getErrors())
        .map((e) => jsonDecode(e) as Map)
        .firstWhere((e) => e['referencia'] == reference);

    setUp(() async {
      // Pair once so the kiosk has a session to ask with.
      await bloc.retryCardPayment(auth, original(reference: 'SETUP'));
      comandas.marked.clear();
    });

    test('a pending charge the terminal later approved registers the order', () async {
      final cp = await storedPending('KOS-PEND-1');
      pos.accepted.add('KOS-PEND-1');
      pos.settle('KOS-PEND-1', 'SUCCESS');

      await bloc.verifyCardPayment(auth, cp);

      expect(comandas.marked, [('charge-uuid-1', 55)]);
      final record = await stored('KOS-PEND-1');
      expect(record['estado'], 'SUCCESS');
      expect(record['respuesta'], 'Aprobada - pedido registrado');
      await flush();
      expect(statuses(), contains(PaymentStatus.cardVerified));
    });

    test('a reference the terminal has no record of stays pending, never "not charged"', () async {
      // The terminal may have been reinstalled or swapped: absence of a record
      // is not proof the card was not charged.
      final cp = await storedPending('KOS-NEVER');
      await bloc.verifyCardPayment(auth, cp);
      final record = await stored('KOS-NEVER');
      expect(record['estado'], 'PENDING');
      expect(comandas.marked, isEmpty);
      await flush();
      expect(statuses(), contains(PaymentStatus.cardPending));
    });

    test('a charge still unconfirmed stays pending', () async {
      final cp = await storedPending('KOS-SLOW');
      pos.accepted.add('KOS-SLOW');
      await bloc.verifyCardPayment(auth, cp);
      expect((await stored('KOS-SLOW'))['estado'], 'PENDING');
      await flush();
      expect(statuses(), contains(PaymentStatus.cardPending));
    });
  });
}
