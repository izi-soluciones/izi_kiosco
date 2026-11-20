import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

class BmAgentLink {
  BmAgentLink({
    Dio? dio,
    Dio? enrollDio,
    required Future<String?> Function() issueCode,
    required String apiBaseUrl,
    Duration Function(int failures)? backoff,
    DateTime Function()? now,
  })  : _dio = dio ?? Dio(),
        _enrollDio = enrollDio ?? Dio(),
        _issueCode = issueCode,
        _apiBaseUrl = apiBaseUrl.endsWith('/') ? apiBaseUrl : '$apiBaseUrl/',
        _backoff = backoff ?? _defaultBackoff,
        _now = now ?? DateTime.now {
    // Options de dio 5.3.2 (BK) no tiene connectTimeout, y sin los dos el XHR web no corta.
    _dio.options
      ..connectTimeout = _timeout
      ..receiveTimeout = _timeout;
    // El agente canjea con el contexto de la petición (hasta 35 s): si el XHR se corta antes, el canje se aborta.
    _enrollDio.options
      ..connectTimeout = _enrollTimeout
      ..receiveTimeout = _enrollTimeout;
  }

  static const _baseUrl = 'http://127.0.0.1:47800';
  static const _timeout = Duration(seconds: 3);
  static const _enrollTimeout = Duration(seconds: 40);
  static const _enrollGuard = Duration(seconds: 45);
  static const _issueCodeTimeout = Duration(seconds: 30);
  static const _hold = Duration(minutes: 30);
  static const _minBackoff = Duration(seconds: 30);
  static const _maxBackoff = Duration(minutes: 30);

  final Dio _dio;
  final Dio _enrollDio;
  final Future<String?> Function() _issueCode;
  final String _apiBaseUrl;
  final Duration Function(int failures) _backoff;
  final DateTime Function() _now;

  bool _inFlight = false;
  bool _reachable = false;
  bool _everResponded = false;
  bool _enrolled = false;
  int _enrollFailures = 0;
  DateTime? _nextEnrollAt;

  static Duration _defaultBackoff(int failures) {
    final exp = min(max(failures, 1) - 1, 10);
    final baseMs = min(_minBackoff.inMilliseconds * (1 << exp), _maxBackoff.inMilliseconds);
    final lo = max((baseMs * 0.8).round(), _minBackoff.inMilliseconds);
    final hi = min((baseMs * 1.2).round(), _maxBackoff.inMilliseconds);
    return Duration(milliseconds: lo + Random().nextInt(hi - lo + 1));
  }

  Future<void> tick() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      await _tick();
    } catch (_) {
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _tick() async {
    final Map<dynamic, dynamic> health;
    try {
      final response = await _get('$_baseUrl/health');
      final data = response.data;
      if (data is! Map) throw const FormatException('health');
      health = data;
    } catch (_) {
      _reachable = false;
      return;
    }
    _reachable = true;
    _everResponded = true;
    _enrolled = health['enrolled'] == true;
    final status = health['status'];
    if (_enrolled || (status != 'not_enrolled' && status != 'token_invalid')) return;

    final nextAt = _nextEnrollAt;
    if (nextAt != null && _now().isBefore(nextAt)) return;

    String? code;
    try {
      code = await _issueCode().timeout(_issueCodeTimeout);
    } catch (_) {
      _failEnroll();
      return;
    }
    if (code == null || code.isEmpty) return;

    try {
      final response = await _post('$_baseUrl/enroll', {'code': code, 'apiBaseUrl': _apiBaseUrl});
      final httpStatus = response.statusCode ?? 0;
      if (httpStatus >= 200 && httpStatus < 300) {
        _enrolled = true;
        _enrollFailures = 0;
        _nextEnrollAt = null;
        return;
      }
      final data = response.data;
      final error = data is Map ? data['error'] : null;
      if ((httpStatus == 409 && error == 'api_base_url_mismatch') || (httpStatus == 403 && error == 'origin_not_allowed')) {
        _nextEnrollAt = _now().add(_hold);
        return;
      }
      _failEnroll();
    } catch (_) {
      _failEnroll();
    }
  }

  void _failEnroll() {
    _enrollFailures++;
    _nextEnrollAt = _now().add(_backoff(_enrollFailures));
  }

  Future<Response<dynamic>> _get(String url) {
    final cancelToken = CancelToken();
    final guard = Timer(_timeout * 2, () {
      if (!cancelToken.isCancelled) cancelToken.cancel('bm_timeout');
    });
    return _dio.get<dynamic>(url, cancelToken: cancelToken).whenComplete(guard.cancel);
  }

  Future<Response<dynamic>> _post(String url, Map<String, dynamic> body) {
    final cancelToken = CancelToken();
    final guard = Timer(_enrollGuard, () {
      if (!cancelToken.isCancelled) cancelToken.cancel('bm_timeout');
    });
    return _enrollDio
        .post<dynamic>(
          url,
          data: body,
          cancelToken: cancelToken,
          options: Options(contentType: Headers.jsonContentType, validateStatus: (_) => true),
        )
        .whenComplete(guard.cancel);
  }

  Map<String, dynamic> agentState() {
    if (!_everResponded) return {'reachable': false};
    return {'reachable': _reachable, 'enrolled': _reachable && _enrolled};
  }
}
