import 'package:http/http.dart' as http;
import 'package:izi_kiosco/data/telemetry/telemetry.dart';

/// Counts the requests to the terminal still open, and reports those that
/// finish long after every caller gave up on them.
///
/// On web a Dart `timeout()` does not cancel the browser request: it stays
/// open until the browser itself gives up, which can take minutes when the
/// terminal stopped answering. Chrome runs at most 6 requests per host at a
/// time, so enough of them make every later call to the terminal wait in
/// line, even once it answers again. [inFlight] and `http.late_settle` show
/// whether that is happening.
class TrackedHttpClient extends http.BaseClient {
  /// Longer than any deadline the kiosk gives the terminal (`/pay`: 10 s).
  static const Duration defaultLateAfter = Duration(seconds: 12);

  /// Shared by every client: all of them talk to the same terminal.
  static final Set<Stopwatch> _open = {};

  final http.Client _inner;
  final Duration lateAfter;

  TrackedHttpClient(this._inner, {this.lateAfter = defaultLateAfter});

  static int get inFlight => _open.length;

  /// How long the oldest open request has been waiting, in ms.
  static int get oldestInFlightMs => _open.isEmpty
      ? 0
      : _open.map((w) => w.elapsedMilliseconds).reduce((a, b) => a > b ? a : b);

  static Map<String, Object?> snapshot() =>
      {'inFlight': inFlight, 'oldestInFlightMs': oldestInFlightMs};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final watch = Stopwatch()..start();
    _open.add(watch);
    String outcome = 'error';
    try {
      final response = await _inner.send(request);
      outcome = '${response.statusCode}';
      return response;
    } catch (e) {
      outcome = e.runtimeType.toString();
      rethrow;
    } finally {
      _open.remove(watch);
      if (watch.elapsed > lateAfter) {
        Telemetry.event('http.late_settle',
            level: TelemetryLevel.warning,
            data: {
              'method': request.method,
              // Path only: a query string may carry a token.
              'path': request.url.path,
              'host': request.url.host,
              'ms': watch.elapsedMilliseconds,
              'outcome': outcome,
              'inFlight': inFlight,
            });
      }
    }
  }

  @override
  void close() => _inner.close();
}
