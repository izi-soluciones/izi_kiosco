import 'dart:async';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/telemetry/platform_signals.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/data/telemetry/tracked_http_client.dart';

/// Why a call to the terminal failed, in one word:
/// `timeout`, `refused`, `unreachable`, `dns`, `closed`, `browser_blocked`
/// (web: CORS or a refused connection, told apart by [probePosFailure]),
/// `http_<status>`, or the error type when nothing more is known.
String posFailureCause(Object error) {
  final cause = error is IzifyPosException ? error.cause : error;
  if (error is IzifyPosException && cause == null && error.statusCode != null) {
    return 'http_${error.statusCode}';
  }
  if (cause == null) return (error is IzifyPosException ? error.code : null) ?? 'unknown';
  if (cause is TimeoutException) return 'timeout';
  if (cause is SocketException) {
    final code = cause.osError?.errorCode;
    // ECONNREFUSED on macOS / Linux+Android / Windows.
    if (const {61, 111, 10061}.contains(code)) return 'refused';
    // EHOSTUNREACH, ENETUNREACH.
    if (const {65, 113, 51, 101, 10065, 10051}.contains(code)) return 'unreachable';
    return 'socket_${code ?? 'error'}';
  }
  final text = cause.toString().toLowerCase();
  if (text.contains('xmlhttprequest')) return 'browser_blocked';
  if (text.contains('connection refused')) return 'refused';
  if (text.contains('failed host lookup')) return 'dns';
  if (text.contains('no route to host') || text.contains('network is unreachable')) {
    return 'unreachable';
  }
  if (text.contains('connection closed') || text.contains('connection reset')) {
    return 'closed';
  }
  if (cause is http.ClientException) return 'client_error';
  return cause.runtimeType.toString();
}

/// Details for a failed call to the terminal at [address]: the cause and,
/// when the browser hid it, what a `no-cors` probe found (see
/// [probeReachability]).
Future<Map<String, Object?>> probePosFailure(
    Object error, IzifyPosAddress address) async {
  final cause = posFailureCause(error);
  final data = <String, Object?>{'cause': cause};
  if (cause == 'browser_blocked') {
    final probe = await probeReachability(address.http('/health'));
    data['probe'] = probe.result;
    data['probeMs'] = probe.ms;
    data['cause'] = switch (probe.result) {
      'answered' => 'cors',
      'no_answer' => 'no_answer',
      // A refusal comes back at once; a network that gives up takes longer.
      'failed' when probe.ms < 1000 => 'refused',
      'failed' => 'unreachable',
      _ => cause,
    };
  }
  return data;
}

/// The kiosk state worth attaching to a failure: what the page and its
/// requests were doing at the time.
Map<String, Object?> kioskSnapshot() => {
      ...TrackedHttpClient.snapshot(),
      if (currentVisibility() != null) 'visibility': currentVisibility(),
      if (currentOnline() != null) 'online': currentOnline(),
    };

/// Follows one health loop's view of the terminal and records the failures
/// and the recoveries. [source] names the loop (`pos_config`, `home`): each
/// keeps its own count.
///
/// Every failure is recorded until [detailedFailures] in a row, then one in
/// [sampleEvery]: a terminal left off all night must not fill the log with
/// the same line. The recovery says how long it was down and how many
/// checks failed meanwhile.
class PosLinkTracker {
  static const int detailedFailures = 10;
  static const int sampleEvery = 10;

  final String source;
  int _failures = 0;
  DateTime? _downSince;
  String? _notReady;

  PosLinkTracker(this.source);

  int get consecutiveFailures => _failures;

  /// The terminal did not answer [rid] after [ms].
  Future<void> failed(
      {required IzifyPosAddress address,
      required String rid,
      required int ms,
      required Object error}) async {
    _failures++;
    _downSince ??= DateTime.now();
    if (_failures > detailedFailures && _failures % sampleEvery != 0) return;
    final details = await probePosFailure(error, address);
    Telemetry.event('pos.health_failed',
        level: TelemetryLevel.warning,
        data: {
          'source': source,
          'address': address.hostPort,
          'rid': rid,
          'ms': ms,
          'failures': _failures,
          ...details,
          ...kioskSnapshot(),
        });
  }

  /// The terminal answered in [ms]. [notReadyReason] is why it cannot
  /// charge, when it cannot.
  void answered(
      {required IzifyPosAddress address,
      int? ms,
      String? notReadyReason,
      String? appVersion}) {
    if (_failures > 0) {
      Telemetry.event('pos.health_recovered', data: {
        'source': source,
        'address': address.hostPort,
        if (ms != null) 'ms': ms,
        'failures': _failures,
        'downMs': DateTime.now().difference(_downSince!).inMilliseconds,
        if (appVersion != null) 'posVersion': appVersion,
        ...kioskSnapshot(),
      });
    }
    _failures = 0;
    _downSince = null;
    if (notReadyReason != _notReady) {
      Telemetry.event(notReadyReason == null ? 'pos.ready' : 'pos.not_ready',
          level: notReadyReason == null ? TelemetryLevel.info : TelemetryLevel.warning,
          data: {
            'source': source,
            'address': address.hostPort,
            if (notReadyReason != null) 'reason': notReadyReason,
          });
      _notReady = notReadyReason;
    }
  }
}
