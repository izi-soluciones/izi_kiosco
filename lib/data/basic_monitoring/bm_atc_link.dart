import 'dart:async';

import 'package:dio/dio.dart';

class BmAtcLink {
  BmAtcLink({required String serverUrl, Dio? dio, DateTime Function()? now})
      : _serverUrl = serverUrl,
        _dio = dio ?? Dio(),
        _now = now ?? DateTime.now {
    // Options de dio 5.3.2 (BK) no tiene connectTimeout, y sin los dos el XHR web no corta.
    _dio.options
      ..connectTimeout = _timeout
      ..receiveTimeout = _timeout;
  }

  static const _timeout = Duration(seconds: 3);
  static const _degradedWindow = Duration(minutes: 5);
  static const _downAfter = 3;
  static const _latencySamples = 20;

  final String _serverUrl;
  final Dio _dio;
  final DateTime Function() _now;

  bool _inFlight = false;
  int _checks = 0;
  int _failures = 0;
  int _consecutiveFailures = 0;
  bool _hasChecked = false;
  bool _lastWasOk = false;
  DateTime? _lastOkAt;
  DateTime? _lastFailureAt;
  String? _lastCause;
  final List<int> _latencies = [];

  Future<void> check() async {
    if (_inFlight) return;
    _inFlight = true;
    final cancelToken = CancelToken();
    // Respaldo duro: si el adaptador no corta solo, cancelamos nosotros.
    final guard = Timer(_timeout * 2, () {
      if (!cancelToken.isCancelled) cancelToken.cancel('bm_timeout');
    });
    try {
      final started = _now();
      final response = await _dio.get<dynamic>(
        '${_serverUrl.replaceAll(RegExp(r'/+$'), '')}/verify-connection',
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map && data['connection'] == true) {
        _recordOk(_now().difference(started).inMilliseconds);
      } else {
        _recordFailure('no_answer');
      }
    } catch (e) {
      _recordFailure(_causeOf(e));
    } finally {
      guard.cancel();
      _inFlight = false;
    }
  }

  void _recordOk(int latencyMs) {
    _checks++;
    _hasChecked = true;
    _lastWasOk = true;
    _consecutiveFailures = 0;
    _lastOkAt = _now();
    _lastCause = null;
    _latencies.add(latencyMs);
    if (_latencies.length > _latencySamples) _latencies.removeAt(0);
  }

  void _recordFailure(String cause) {
    _checks++;
    _failures++;
    _hasChecked = true;
    _lastWasOk = false;
    _consecutiveFailures++;
    _lastFailureAt = _now();
    _lastCause = cause;
  }

  String _causeOf(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'timeout';
        case DioExceptionType.badResponse:
          return 'http_${e.response?.statusCode ?? 0}';
        default:
          return 'unreachable';
      }
    }
    return 'unreachable';
  }

  Map<String, dynamic> posState({required String provider}) {
    if (provider == 'none') {
      return {
        'provider': provider,
        'status': 'not_configured',
        'lastOkAt': null,
        'latencyMsP50': null,
        'consecutiveFailures': 0,
        'lastCause': null,
      };
    }
    return {
      'provider': provider,
      'status': _status(),
      'address': _address(),
      'lastOkAt': _lastOkAt?.toUtc().toIso8601String(),
      'latencyMsP50': _median(),
      'consecutiveFailures': _consecutiveFailures,
      'lastCause': _lastCause,
    };
  }

  String _status() {
    if (_consecutiveFailures >= _downAfter) return 'down';
    if (!_hasChecked) return 'degraded';
    if (!_lastWasOk) return 'degraded';
    final failedAt = _lastFailureAt;
    if (failedAt != null && _now().difference(failedAt) < _degradedWindow) return 'degraded';
    return 'ok';
  }

  String? _address() {
    try {
      final uri = Uri.parse(_serverUrl);
      if (uri.host.isEmpty) return null;
      return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
    } catch (_) {
      return null;
    }
  }

  int? _median() {
    if (_latencies.isEmpty) return null;
    final sorted = [..._latencies]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return ((sorted[mid - 1] + sorted[mid]) / 2).round();
  }

  int takeChecks() {
    final v = _checks;
    _checks = 0;
    return v;
  }

  int takeFailures() {
    final v = _failures;
    _failures = 0;
    return v;
  }
}
