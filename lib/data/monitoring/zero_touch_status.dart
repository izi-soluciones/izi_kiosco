/// How the zero-touch enrollment of the terminal or the PC agent is going
/// (contracts §3.3), for the diagnostics.
class ZeroTouchStatus {
  /// `stopped`, `waiting` (see [reason]), `checking`, `enrolling`,
  /// `enrolled`, `unsupported` or `failed` (see [lastCause]).
  final String state;

  /// Why it is waiting: `not_enrolled` (the kiosk itself), `not_paired`,
  /// `unhealthy`, `busy`, `agent_unreachable`...
  final String? reason;
  final String? lastCause;
  final int failures;
  final DateTime? lastCheckAt;
  final DateTime? nextAt;

  const ZeroTouchStatus(
      {required this.state,
      this.reason,
      this.lastCause,
      this.failures = 0,
      this.lastCheckAt,
      this.nextAt});

  static const ZeroTouchStatus stopped = ZeroTouchStatus(state: 'stopped');

  Map<String, Object?> toJson() => {
        'state': state,
        if (reason != null) 'reason': reason,
        if (lastCause != null) 'lastCause': lastCause,
        'failures': failures,
        'lastCheckAt': lastCheckAt?.toUtc().toIso8601String(),
        'nextAt': nextAt?.toUtc().toIso8601String(),
      };
}
