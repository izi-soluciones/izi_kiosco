/// What the monitoring service answers a batch of events (contracts §5).
class MonitoringEventsResponse {
  /// The highest `seq` of [stream] the service keeps: the kiosk forgets
  /// every event up to it.
  final int ackSeq;
  final String stream;

  const MonitoringEventsResponse({required this.ackSeq, required this.stream});

  /// Null without a usable `ackSeq` and `stream`: an answer that does not
  /// say what was kept acknowledges nothing.
  static MonitoringEventsResponse? tryParse(Object? json) {
    if (json is! Map) return null;
    final ack = json['ackSeq'];
    final stream = json['stream'];
    if (ack is! num || !ack.isFinite || ack < 0) return null;
    if (stream is! String || stream.isEmpty) return null;
    return MonitoringEventsResponse(ackSeq: ack.toInt(), stream: stream);
  }
}
