import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/domain/dto/add_kiosk_dto.dart';
import 'package:izi_kiosco/domain/dto/new_sale_link_dto.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/repositories/auth_repository.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/repositories/pos_repository.dart';
import 'package:izi_kiosco/domain/repositories/socket_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBusinessRepository extends Mock implements BusinessRepository {}

class MockComandaRepository extends Mock implements ComandaRepository {}

class MockPosRepository extends Mock implements PosRepository {}

class MockSocketRepository extends Mock implements SocketRepository {}

/// Mock of the HTTP wrapper injected into the *RepositoryHttp classes.
class MockDioClient extends Mock implements DioClient {}

// Fallbacks required by mocktail's any() for non-primitive argument types.
class _FakeAddKioskDto extends Fake implements AddKioskDto {}

class _FakeNewSaleLinkDto extends Fake implements NewSaleLinkDto {}

/// Registers all fallback values used across bloc tests. Call once in main().
void registerCommonFallbacks() {
  registerFallbackValue(_FakeAddKioskDto());
  registerFallbackValue(_FakeNewSaleLinkDto());
}

/// Registers fallbacks needed to `any()`-match Dio argument types.
void registerDioFallbacks() {
  registerFallbackValue(Options());
  registerFallbackValue(CancelToken());
}

/// Builds a Dio [Response] for stubbing [DioClient] calls.
Response<dynamic> dioResponse(dynamic data, {int statusCode = 200, String path = '/'}) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      statusCode: statusCode,
      data: data,
    );

/// The gateway behind a real [Dio] ([client]): answers every request with
/// [status] and [body] as JSON, or throws [error], and remembers each one.
class FakeGateway implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  int status = 200;
  Object? body = const {'ok': true};

  /// Thrown instead of answering, when set.
  Object? error;

  /// A [Dio] that talks to this gateway.
  Dio get client => Dio(BaseOptions(baseUrl: 'http://gateway.test'))..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (error != null) throw error!;
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Convenience builder for an open/closed cash register.
CashRegister buildCashRegister({int id = 1, bool abierta = true}) =>
    CashRegister.fromJson({
      'id': id,
      'nombre': 'Caja $id',
      'estado': true,
      'abierta': abierta,
    });
