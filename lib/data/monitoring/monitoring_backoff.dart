import 'dart:math';

/// The backoff every monitoring loop of the kiosk retries with (contracts
/// §12.1): exponential from [first] up to [max], with ±[jitter] so a fleet
/// that saw the same outage does not come back in lockstep, and never out
/// of that range.
class MonitoringBackoff {
  /// The share of each wait that is random, either way.
  static const double jitter = 0.2;

  const MonitoringBackoff._();

  /// [first] after the first failure, doubling with each one up to [max].
  static Duration base({required Duration first, required Duration max, required int failures}) {
    final cap = max.inMilliseconds;
    final start = min(first.inMilliseconds, cap);
    final doubled = start * pow(2, min(failures <= 1 ? 0 : failures - 1, 30));
    return Duration(milliseconds: min(doubled, cap).toInt());
  }

  /// The wait after [failures] in a row: [base] moved by up to [jitter]
  /// either way, for [random] in [0, 1) (0.5 leaves it as is), and kept
  /// within [first] and [max].
  static Duration delay(
      {required Duration first,
      required Duration max,
      required int failures,
      required double random}) {
    final lowest = min(first.inMilliseconds, max.inMilliseconds);
    final wait = base(first: first, max: max, failures: failures).inMilliseconds;
    final r = random.isNaN ? 0.5 : random.clamp(0.0, 1.0);
    final jittered = (wait * (1 + jitter * (2 * r - 1))).round();
    return Duration(milliseconds: jittered.clamp(lowest, max.inMilliseconds));
  }
}
