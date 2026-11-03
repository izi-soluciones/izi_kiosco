// Archivo propio: si la guarda estática de la resolución queda tomada, no contamina otros tests
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/local/local_storage_atc_pending.dart';
import 'package:izi_kiosco/domain/blocs/home/home_bloc.dart';
import 'package:izi_kiosco/domain/models/atc_payment_status.dart';
import 'package:izi_kiosco/domain/models/atc_pending_payment.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _HangingComandaRepository implements ComandaRepository {
  final List<String> statusQueries = [];
  final List<String> confirmed = [];

  @override
  Future<AtcPaymentStatus> getPaymentStatusATC(String ref) async {
    statusQueries.add(ref);
    return AtcPaymentStatus(
        ref: ref,
        estado: AtcPaymentStatus.approved,
        resultado: {
          "status": true,
          "data": {"codigo_autorizacion": "413715", "cod_respuesta": "00"}
        },
        confirmado: false);
  }

  @override
  Future<void> confirmPaymentATC(String ref) async {
    confirmed.add(ref);
  }

  // El backbone no contesta nunca
  @override
  Future<void> markPaymentATC(String chargeUuid, int? internalId) =>
      Completer<void>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBusinessRepository implements BusinessRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  testWidgets('un markPaymentATC colgado no deja la resolución tomada para siempre',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final comandas = _HangingComandaRepository();
    await LocalStorageAtcPending.savePending(AtcPendingPayment(
        ref: 'a',
        uuid: 'venta-1',
        intentoPago: 77,
        kind: AtcPaymentKind.retail,
        amount: '30.00',
        createdAt: DateTime.now()));

    HomeBloc(_FakeBusinessRepository(), comandaRepository: comandas)
        .resolveAtcPending();
    await tester.pump(const Duration(minutes: 2));

    // Un home nuevo vuelve a resolver
    HomeBloc(_FakeBusinessRepository(), comandaRepository: comandas)
        .resolveAtcPending();
    await tester.pump(const Duration(minutes: 2));

    expect(comandas.statusQueries, ['a', 'a']);
    // Sin saber si quedó marcado no se confirma ni se borra
    expect(comandas.confirmed, isEmpty);
    expect((await LocalStorageAtcPending.getPending()).single.ref, 'a');
  });
}
