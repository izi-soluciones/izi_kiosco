import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/repositories/comanda/comanda_repository_http.dart';
import 'package:izi_kiosco/domain/models/atc_payment_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servidor POS falso en 127.0.0.1: cada test decide qué responde.
class _FakeAtcServer {
  late HttpServer server;
  final List<HttpRequest> requests = [];
  Future<void> Function(HttpRequest request) handler = (request) async {
    request.response.statusCode = 404;
  };

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request);
      try {
        await handler(request);
      } finally {
        try {
          await request.response.close();
        } catch (_) {}
      }
    });
  }

  String get url => 'http://127.0.0.1:${server.port}';

  static void json(HttpRequest request, Object body, {int status = 200}) {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
  }
}

Future<AtcPaymentError> _atcError(Future future) async {
  try {
    await future;
  } catch (e) {
    expect(e, isA<AtcPaymentError>());
    return e as AtcPaymentError;
  }
  fail('se esperaba un AtcPaymentError');
}

void main() {
  late _FakeAtcServer pos;
  late ComandaRepositoryHttp repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pos = _FakeAtcServer();
    await pos.start();
    dotenv.testLoad(fileInput: 'API_URL=${pos.url}\nATC_SERVER_URL=${pos.url}');
    repository = ComandaRepositoryHttp();
  });

  tearDown(() => pos.server.close(force: true));

  Future<dynamic> pay({String? ref, CancelToken? cancelToken}) =>
      repository.callCardPaymentATC(
          amount: '30.00',
          ip: '192.168.0.101',
          cancelToken: cancelToken ?? CancelToken(),
          contactless: true,
          ref: ref);

  test('manda el ref del intento como query ?ref=', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request, {
          "status": true,
          "data": {
            "codigo_autorizacion": "413715",
            "ult_4_digitos": "4167",
            "cod_respuesta": "00"
          }
        });

    final cardPayment = await pay(ref: 'venta-1-77-abc123');

    expect(pos.requests.single.uri.path, '/v2/ctl/192.168.0.101/30.00/0');
    expect(pos.requests.single.uri.queryParameters['ref'], 'venta-1-77-abc123');
    expect(cardPayment.response, '413715');
  });

  test('un rechazo del POS (status false) es un rechazo', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request, {
          "status": false,
          "data": {
            "error": {"cod_error": "51", "mensaje_error": "FONDOS INSUFICIENTES"}
          }
        });

    final error = await _atcError(pay(ref: 'r1'));

    expect(error.type, AtcPaymentErrorType.rejected);
  });

  test('codigo pagoEnCurso no es un pago incierto', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request, {
          "ipcaja": "192.168.0.101",
          "status": "error",
          "codigo": "pagoEnCurso",
          "resp": "Pago en curso en el POS"
        });

    final error = await _atcError(pay(ref: 'r1'));

    expect(error.type, AtcPaymentErrorType.paymentInProgress);
  });

  test('el tiempo de espera superado del propio servidor es incierto', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request, {
          "ipcaja": "192.168.0.101",
          "status": "error",
          "resp": "Pago Ctl: Tiempo de espera superado"
        });

    final error = await _atcError(pay(ref: 'r1'));

    expect(error.type, AtcPaymentErrorType.uncertain);
  });

  test('una respuesta de texto sin status es incierta', () async {
    pos.handler = (request) async {
      request.response.write('Error');
    };

    final error = await _atcError(pay(ref: 'r1'));

    expect(error.type, AtcPaymentErrorType.uncertain);
  });

  test('status true sin cod_respuesta 00 no es una aprobación: es incierto', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request, {
          "status": true,
          "data": {"codigo_autorizacion": "", "ult_4_digitos": "4167"}
        });

    final error = await _atcError(pay(ref: 'r1'));

    expect(error.type, AtcPaymentErrorType.uncertain);
  });

  // Respuestas que el servidor da antes de contactar al POS: el POS no cobró
  for (final preventa in <String, Object>{
    'texto "El IP no existe"': 'El IP no existe o el POS no está conectado',
    'JSON "El número IP … no existe"': jsonEncode(
        {"resp": "El número IP192.168.0.101 no existe"}),
    'texto "El monto debe ser…"': 'El monto debe ser un numero entero mayor a cero',
    'codigo refInvalido': {
      "ipcaja": "192.168.0.101",
      "status": "error",
      "codigo": "refInvalido",
      "resp": "Referencia de pago inválida"
    },
  }.entries) {
    test('${preventa.key} es un error definitivo, no incierto', () async {
      pos.handler = (request) async {
        if (preventa.value is String) {
          request.response.write(preventa.value);
        } else {
          _FakeAtcServer.json(request, preventa.value);
        }
      };

      final error = await _atcError(pay(ref: 'r1'));

      expect(error.type.name, 'notSent');
    });
  }

  test('codigo refRepetido sigue siendo incierto', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request, {
          "ipcaja": "192.168.0.101",
          "status": "error",
          "codigo": "refRepetido",
          "resp": "Ese intento de pago ya se envió al POS",
          "estado": "enCurso"
        });

    final error = await _atcError(pay(ref: 'r1'));

    expect(error.type, AtcPaymentErrorType.uncertain);
  });

  test('la cancelación del cliente es incierta', () async {
    final responder = Completer<void>();
    pos.handler = (request) => responder.future;
    final cancelToken = CancelToken();

    final pending = _atcError(pay(ref: 'r1', cancelToken: cancelToken));
    await Future.delayed(const Duration(milliseconds: 100));
    cancelToken.cancel();
    final error = await pending;
    responder.complete();

    expect(error.type, AtcPaymentErrorType.uncertain);
  });

  test('sin conexión con el servidor es incierto', () async {
    await pos.server.close(force: true);

    final error = await _atcError(pay(ref: 'r1'));

    expect(error.type, AtcPaymentErrorType.uncertain);
  });

  test('GET /v2/pago/:ref devuelve el estado y el resultado del POS', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request, {
          "ref": "r1",
          "estado": "aprobado",
          "resultado": {
            "status": true,
            "data": {
              "codigo_autorizacion": "413715",
              "ult_4_digitos": "4167",
              "cod_respuesta": "00"
            }
          },
          "confirmado": false,
          "inicio": "2026-10-22T13:05:00.000Z",
          "fin": "2026-10-22T13:05:16.000Z"
        });

    final status = await repository.getPaymentStatusATC('r1');

    expect(pos.requests.single.method, 'GET');
    expect(pos.requests.single.uri.path, '/v2/pago/r1');
    expect(status.estado, 'aprobado');
    expect(status.isApproved, isTrue);
    expect(status.confirmado, isFalse);
    expect(status.cardPayment?.response, '413715');
  });

  test('GET /v2/pago/:ref rechazado con resultado status true no es una aprobación', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request, {
          "ref": "r1",
          "estado": "rechazado",
          "resultado": {
            "status": true,
            "data": {"codigo_autorizacion": "413715", "cod_respuesta": "00"}
          },
          "confirmado": false
        });

    final status = await repository.getPaymentStatusATC('r1');

    expect(status.isApproved, isFalse);
    expect(status.isRejected, isTrue);
  });

  test('GET /v2/pago/:ref aprobado sin cod_respuesta 00 no es una aprobación', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request, {
          "ref": "r1",
          "estado": "aprobado",
          "resultado": {
            "status": true,
            "data": {"codigo_autorizacion": "", "cod_respuesta": "51"}
          },
          "confirmado": false
        });

    final status = await repository.getPaymentStatusATC('r1');

    expect(status.isApproved, isFalse);
    expect(status.isRejected, isFalse);
  });

  test('GET /v2/pago/:ref con noEncontrado no es una aprobación', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request,
        {"ref": "r1", "estado": "noEncontrado", "resultado": null});

    final status = await repository.getPaymentStatusATC('r1');

    expect(status.isNotFound, isTrue);
    expect(status.isApproved, isFalse);
  });

  test('POST /v2/pago/:ref/confirmar llega al servidor POS', () async {
    pos.handler = (request) async => _FakeAtcServer.json(request, {"ok": true});

    await repository.confirmPaymentATC('r1');

    expect(pos.requests.single.method, 'POST');
    expect(pos.requests.single.uri.path, '/v2/pago/r1/confirmar');
  });
}
