import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// What the PC agent says on `GET /health` (contracts §12.7).
class KioskAgentHealth {
  final bool enrolled;

  /// `starting | not_enrolled | enrolling | ok | degraded | token_invalid |
  /// token_unreadable`.
  final String? status;
  final String? version;

  const KioskAgentHealth({required this.enrolled, this.status, this.version});

  /// Null when the answer is not the agent's.
  static KioskAgentHealth? tryParse(Object? json) {
    if (json is! Map || json['kind'] != 'agent' || json['enrolled'] is! bool) return null;
    return KioskAgentHealth(
        enrolled: json['enrolled'] as bool,
        status: json['status']?.toString(),
        version: json['version']?.toString());
  }
}

/// A call to the PC agent that failed.
class KioskAgentException implements Exception {
  /// The agent's `error` (`already_enrolled`, `enrollment_code_invalid`,
  /// `origin_not_allowed`...), or `unreachable` / `invalid_response` /
  /// `http_<status>`.
  final String code;
  final int? statusCode;

  const KioskAgentException(this.code, {this.statusCode});

  @override
  String toString() => 'KioskAgentException($code)';
}

/// The local API of the iZi agent on the kiosk PC (contracts §3.3, §12.7):
/// `GET /health` and `POST /enroll`, on `127.0.0.1:47800` only.
///
/// From the web kiosk these are cross-origin requests to loopback: the
/// agent answers CORS for the kiosk's origin. Without the agent installed,
/// or from an origin it does not allow, the browser reports a bare network
/// error: [KioskAgentException] `unreachable` either way.
class KioskAgentClient {
  static final Uri defaultBase = Uri.parse('http://127.0.0.1:47800');
  static const Duration healthTimeout = Duration(seconds: 3);

  /// The agent redeems the code against the gateway before answering.
  static const Duration enrollTimeout = Duration(seconds: 40);

  final http.Client _http;
  final Uri base;

  KioskAgentClient({http.Client? httpClient, Uri? base})
      : _http = httpClient ?? http.Client(),
        base = base ?? defaultBase;

  Future<KioskAgentHealth> health() async {
    final http.Response res;
    try {
      res = await _http.get(base.resolve('/health')).timeout(healthTimeout);
    } catch (_) {
      throw const KioskAgentException('unreachable');
    }
    if (res.statusCode != 200) throw _failure(res);
    final health = KioskAgentHealth.tryParse(_decode(res.body));
    if (health == null) throw KioskAgentException('invalid_response', statusCode: res.statusCode);
    return health;
  }

  /// Hands the agent a one-time [code] to enroll through [apiBaseUrl].
  Future<void> enroll({required String code, required String apiBaseUrl}) async {
    final http.Response res;
    try {
      res = await _http
          .post(base.resolve('/enroll'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'code': code, 'apiBaseUrl': apiBaseUrl}))
          .timeout(enrollTimeout);
    } catch (_) {
      throw const KioskAgentException('unreachable');
    }
    final data = _decode(res.body);
    if (res.statusCode == 200 && data is Map && data['enrolled'] == true) return;
    throw _failure(res, data);
  }

  void close() => _http.close();

  static KioskAgentException _failure(http.Response res, [Object? data]) {
    final body = data ?? _decode(res.body);
    final error = body is Map ? body['error'] : null;
    return KioskAgentException(
        error is String && error.isNotEmpty && error.length <= 60 ? error : 'http_${res.statusCode}',
        statusCode: res.statusCode);
  }

  static Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
