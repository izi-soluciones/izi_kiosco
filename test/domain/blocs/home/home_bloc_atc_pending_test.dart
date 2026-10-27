import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/local/local_storage_atc_pending.dart';
import 'package:izi_kiosco/domain/blocs/home/home_bloc.dart';
import 'package:izi_kiosco/domain/models/atc_payment_status.dart';
import 'package:izi_kiosco/domain/models/atc_pending_payment.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeComandaRepository implements ComandaRepository {
  final Map<String, Object> statuses = {};
  final List<String> statusQueries = [];
  final List<String> confirmed = [];
  final List<List<Object?>> marked = [];
  bool markFails = false;
  Object markError = 'Network Error';

  @override
  Future<AtcPaymentStatus> getPaymentStatusATC(String ref) async {
    statusQueries.add(ref);
    final status = statuses[ref];
    if (status is AtcPaymentStatus) {
      return status;
    }
    throw status ?? 'Network Error';
  }

  @override
  Future<void> confirmPaymentATC(String ref) async {
    confirmed.add(ref);
  }

  @override
  Future<void> markPaymentATC(String chargeUuid, int? internalId) async {
    if (markFails) {
      throw markError;
    }
    marked.add([chargeUuid, internalId]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBusinessRepository implements BusinessRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

AtcPendingPayment _pending(String ref,
        {AtcPaymentKind kind = AtcPaymentKind.retail,
        String uuid = 'venta-1',
        int? intentoPago = 77,
        DateTime? createdAt}) =>
    AtcPendingPayment(
        ref: ref,
        uuid: uuid,
        intentoPago: intentoPago,
        kind: kind,
        amount: '30.00',
        createdAt: createdAt ?? DateTime.now());

AtcPaymentStatus _status(String estado, {Object? resultado, bool confirmado = false}) =>
    AtcPaymentStatus(
        ref: 'r', estado: estado, resultado: resultado, confirmado: confirmado);

const _approvedResult = {
  "status": true,
  "data": {
    "codigo_autorizacion": "413715",
    "ult_4_digitos": "4167",
    "cod_respuesta": "00"
  }
};

// GET /v2/pago/:ref tal como lo parsea el repositorio (incluye resuelto aunque el modelo no lo exponga)
AtcPaymentStatus _statusJson(Map<String, Object?> json) =>
    AtcPaymentStatus.fromJson({"ref": "r", ...json});

Future<List<String>> _pendingRefs() async =>
    (await LocalStorageAtcPending.getPending()).map((e) => e.ref).toList();

void main() {
  late _FakeComandaRepository comandas;
  late HomeBloc bloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    comandas = _FakeComandaRepository();
    bloc = HomeBloc(_FakeBusinessRepository(), comandaRepository: comandas);
  });

  tearDown(() => bloc.close());

  test('al arrancar, un intento aprobado se marca, se confirma y se borra', () async {
    await LocalStorageAtcPending.savePending(_pending('venta-1-77-a'));
    await LocalStorageAtcPending.savePending(_pending('cobro-9-b',
        kind: AtcPaymentKind.comanda, uuid: 'cobro-9', intentoPago: null));
    comandas.statuses['venta-1-77-a'] =
        _status(AtcPaymentStatus.approved, resultado: _approvedResult);
    comandas.statuses['cobro-9-b'] =
        _status(AtcPaymentStatus.approved, resultado: _approvedResult);

    await bloc.resolveAtcPending();

    expect(comandas.marked, [
      ['venta-1', 77],
      ['cobro-9', null]
    ]);
    expect(comandas.confirmed, ['venta-1-77-a', 'cobro-9-b']);
    expect(await _pendingRefs(), isEmpty);
  });

  test('al arrancar, un intento rechazado se confirma y se borra sin marcar', () async {
    await LocalStorageAtcPending.savePending(_pending('venta-1-77-a'));
    comandas.statuses['venta-1-77-a'] = _status(AtcPaymentStatus.rejected,
        resultado: {"status": false, "data": {}});

    await bloc.resolveAtcPending();

    expect(comandas.marked, isEmpty);
    expect(comandas.confirmed, ['venta-1-77-a']);
    expect(await _pendingRefs(), isEmpty);
  });

  test('noEncontrado se borra sin confirmar', () async {
    await LocalStorageAtcPending.savePending(_pending('venta-1-77-a'));
    comandas.statuses['venta-1-77-a'] = _status(AtcPaymentStatus.notFound);

    await bloc.resolveAtcPending();

    expect(comandas.marked, isEmpty);
    expect(comandas.confirmed, isEmpty);
    expect(await _pendingRefs(), isEmpty);
  });

  test('enCurso, sinRespuesta o sin servidor se dejan para la próxima', () async {
    await LocalStorageAtcPending.savePending(_pending('a'));
    await LocalStorageAtcPending.savePending(_pending('b'));
    await LocalStorageAtcPending.savePending(_pending('c'));
    comandas.statuses['a'] = _status(AtcPaymentStatus.inProgress);
    comandas.statuses['b'] = _status(AtcPaymentStatus.noResponse);

    await bloc.resolveAtcPending();

    expect(comandas.statusQueries, ['a', 'b', 'c']);
    expect(comandas.marked, isEmpty);
    expect(comandas.confirmed, isEmpty);
    expect(await _pendingRefs(), ['a', 'b', 'c']);
  });

  test('si markPaymentATC falla el aprobado queda para la próxima sin confirmar', () async {
    await LocalStorageAtcPending.savePending(_pending('a'));
    comandas.statuses['a'] =
        _status(AtcPaymentStatus.approved, resultado: _approvedResult);
    comandas.markFails = true;

    await bloc.resolveAtcPending();

    expect(comandas.confirmed, isEmpty);
    expect(await _pendingRefs(), ['a']);
  });

  test('un aprobado ya confirmado se borra sin volver a marcarlo', () async {
    await LocalStorageAtcPending.savePending(_pending('a'));
    comandas.statuses['a'] = _status(AtcPaymentStatus.approved,
        resultado: _approvedResult, confirmado: true);

    await bloc.resolveAtcPending();

    expect(comandas.marked, isEmpty);
    expect(await _pendingRefs(), isEmpty);
  });

  test('un aprobado que caja marcó resuelto se borra sin marcar ni confirmar', () async {
    await LocalStorageAtcPending.savePending(_pending('a'));
    comandas.statuses['a'] = _statusJson({
      "estado": "aprobado",
      "resultado": _approvedResult,
      "confirmado": false,
      "resuelto": true
    });

    await bloc.resolveAtcPending();

    expect(comandas.marked, isEmpty);
    expect(comandas.confirmed, isEmpty);
    expect(await _pendingRefs(), isEmpty);
  });

  test('rechazado aunque el resultado traiga status true: se confirma y se borra sin marcar', () async {
    await LocalStorageAtcPending.savePending(_pending('a'));
    comandas.statuses['a'] =
        _status(AtcPaymentStatus.rejected, resultado: _approvedResult);

    await bloc.resolveAtcPending();

    expect(comandas.marked, isEmpty);
    expect(comandas.confirmed, ['a']);
    expect(await _pendingRefs(), isEmpty);
  });

  test('retail: "El intento de pago ya fue pagado" es este mismo intento: confirma y borra', () async {
    await LocalStorageAtcPending.savePending(_pending('a'));
    comandas.statuses['a'] =
        _status(AtcPaymentStatus.approved, resultado: _approvedResult);
    comandas.markFails = true;
    comandas.markError = 'El intento de pago ya fue pagado';

    await bloc.resolveAtcPending();

    expect(comandas.confirmed, ['a']);
    expect(await _pendingRefs(), isEmpty);
  });

  test('comanda: "El cobro ya fue pagado" es este mismo cobro: confirma y borra', () async {
    await LocalStorageAtcPending.savePending(_pending('a',
        kind: AtcPaymentKind.comanda, uuid: 'cobro-9', intentoPago: null));
    comandas.statuses['a'] =
        _status(AtcPaymentStatus.approved, resultado: _approvedResult);
    comandas.markFails = true;
    comandas.markError = 'El cobro ya fue pagado (race condition)';

    await bloc.resolveAtcPending();

    expect(comandas.confirmed, ['a']);
    expect(await _pendingRefs(), isEmpty);
  });

  test('retail: "El cobro ya fue pagado" puede ser otro pago: borra sin confirmar', () async {
    await LocalStorageAtcPending.savePending(_pending('a'));
    comandas.statuses['a'] =
        _status(AtcPaymentStatus.approved, resultado: _approvedResult);
    comandas.markFails = true;
    comandas.markError = 'El cobro ya fue pagado';

    await bloc.resolveAtcPending();

    expect(comandas.confirmed, isEmpty);
    expect(await _pendingRefs(), isEmpty);
  });

  test('más de 7 días y aprobado sin confirmar: se consulta y se marca igual', () async {
    await LocalStorageAtcPending.savePending(_pending('viejo',
        createdAt: DateTime.now().subtract(const Duration(days: 8))));
    comandas.statuses['viejo'] =
        _status(AtcPaymentStatus.approved, resultado: _approvedResult);

    await bloc.resolveAtcPending();

    expect(comandas.statusQueries, ['viejo']);
    expect(comandas.marked, [
      ['venta-1', 77]
    ]);
    expect(comandas.confirmed, ['viejo']);
    expect(await _pendingRefs(), isEmpty);
  });

  test('más de 7 días y sinRespuesta o enCurso: se consulta y se borra sin confirmar', () async {
    final viejo = DateTime.now().subtract(const Duration(days: 8));
    await LocalStorageAtcPending.savePending(_pending('sin', createdAt: viejo));
    await LocalStorageAtcPending.savePending(_pending('curso', createdAt: viejo));
    await LocalStorageAtcPending.savePending(_pending('nuevo'));
    comandas.statuses['sin'] = _status(AtcPaymentStatus.noResponse);
    comandas.statuses['curso'] = _status(AtcPaymentStatus.inProgress);
    comandas.statuses['nuevo'] = _status(AtcPaymentStatus.noResponse);

    await bloc.resolveAtcPending();

    expect(comandas.statusQueries, ['sin', 'curso', 'nuevo']);
    expect(comandas.confirmed, isEmpty);
    expect(comandas.marked, isEmpty);
    expect(await _pendingRefs(), ['nuevo']);
  });

  test('más de 7 días y el servidor no contesta: se borra', () async {
    await LocalStorageAtcPending.savePending(_pending('viejo',
        createdAt: DateTime.now().subtract(const Duration(days: 8))));

    await bloc.resolveAtcPending();

    expect(await _pendingRefs(), isEmpty);
  });
}
