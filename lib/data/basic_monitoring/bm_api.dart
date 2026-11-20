import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum BmFailure { tokenInvalid, transient, rejected }

class BmApiException implements Exception {
  final BmFailure kind;
  final int? status;
  final String? code;

  BmApiException(this.kind, {this.status, this.code});

  @override
  String toString() => 'BmApiException($kind, status: $status, code: $code)';
}

class BmEnrollment {
  final String deviceId, applianceId, deviceToken;

  BmEnrollment({required this.deviceId, required this.applianceId, required this.deviceToken});
}

class BmCommand {
  final String id, type;
  final Map<String, dynamic> args;
  final DateTime? expiresAt;

  BmCommand({required this.id, required this.type, required this.args, this.expiresAt});
}

class BmHeartbeatResponse {
  final DateTime serverTime;
  final int nextInSec;
  final List<BmCommand> commands;

  BmHeartbeatResponse({required this.serverTime, required this.nextInSec, required this.commands});
}

class BmApi {
  final String _base;
  final Dio _dio;

  // Dio propio: con el de la app un 401 o 403 dispararía /refrescar-token.
  BmApi({required String apiUrl, @visibleForTesting Dio? dio})
      : _base = apiUrl.replaceFirst(RegExp(r'/+$'), ''),
        _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 15)
      ..validateStatus = (_) => true;
  }

  @visibleForTesting
  Dio get debugDio => _dio;

  Future<BmEnrollment> enroll({
    required String publicToken,
    String? sucursal,
    required Map<String, dynamic> body,
  }) async {
    final data = await _post('kiosco/enrolamiento', body, {
      'X-Public-Token': publicToken,
      if (sucursal != null) 'Izi-Sucursal': sucursal,
    });
    final deviceId = data['deviceId'];
    final applianceId = data['applianceId'];
    final deviceToken = data['deviceToken'];
    if (deviceId is! String || applianceId is! String || deviceToken is! String || deviceToken.isEmpty) {
      throw BmApiException(BmFailure.transient);
    }
    return BmEnrollment(deviceId: deviceId, applianceId: applianceId, deviceToken: deviceToken);
  }

  Future<String> issueAgentCode({
    required String publicToken,
    required String deviceToken,
    String? sucursal,
  }) async {
    final data = await _post('kiosco/codigos-enrolamiento', {'for': 'agent'}, {
      'X-Public-Token': publicToken,
      'X-Device-Token': deviceToken,
      if (sucursal != null) 'Izi-Sucursal': sucursal,
    });
    final code = data['code'];
    if (code is! String || code.isEmpty) throw BmApiException(BmFailure.transient);
    return code;
  }

  Future<BmHeartbeatResponse> heartbeat({
    required String deviceToken,
    required Map<String, dynamic> body,
  }) async {
    final data = await _post('ingesta/heartbeat', body, {'X-Device-Token': deviceToken});
    final next = data['nextInSec'];
    final serverTime = data['serverTime'] is String ? DateTime.tryParse(data['serverTime'] as String) : null;
    final commands = <BmCommand>[];
    final raw = data['commands'];
    if (raw is List) {
      for (final c in raw) {
        if (c is! Map || c['id'] is! String || c['type'] is! String) continue;
        final args = c['args'];
        final expiresAt = c['expiresAt'] is String ? DateTime.tryParse(c['expiresAt'] as String) : null;
        commands.add(BmCommand(
          id: c['id'] as String,
          type: c['type'] as String,
          args: args is Map ? Map<String, dynamic>.from(args) : <String, dynamic>{},
          expiresAt: expiresAt,
        ));
      }
    }
    return BmHeartbeatResponse(
      serverTime: serverTime ?? DateTime.now().toUtc(),
      nextInSec: next is num ? next.toInt().clamp(10, 3600) : 60,
      commands: commands,
    );
  }

  Future<void> commandResult({
    required String deviceToken,
    required String id,
    required Map<String, dynamic> body,
  }) async {
    await _post('ingesta/comandos/${Uri.encodeComponent(id)}/resultado', body, {'X-Device-Token': deviceToken});
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, Map<String, String> headers) async {
    final Response<dynamic> res;
    try {
      res = await _dio.post<dynamic>(
        '$_base/monitoreo/$path',
        data: body,
        options: Options(contentType: Headers.jsonContentType, headers: headers),
      );
    } catch (_) {
      throw BmApiException(BmFailure.transient);
    }
    final status = res.statusCode ?? 0;
    final data = res.data;
    final code = data is Map && data['error'] is String ? data['error'] as String : null;
    if (status >= 200 && status < 300) {
      if (data is Map) return Map<String, dynamic>.from(data);
      throw BmApiException(BmFailure.transient, status: status);
    }
    if (status == 401 && code == 'device_token_invalid') {
      throw BmApiException(BmFailure.tokenInvalid, status: status, code: code);
    }
    if (status == 400 || status == 411 || status == 413 || status == 415) {
      throw BmApiException(BmFailure.rejected, status: status, code: code);
    }
    throw BmApiException(BmFailure.transient, status: status, code: code);
  }
}
