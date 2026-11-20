import 'dart:math';

const _minMs = 30 * 1000;
const _maxMs = 30 * 60 * 1000;

Duration bmBackoff(int failures, {Random? random}) {
  final exp = failures < 0 ? 0 : (failures > 10 ? 10 : failures);
  final base = min(_minMs * (1 << exp), _maxMs);
  final lo = max(_minMs, (base * 0.8).round());
  final hi = min(_maxMs, (base * 1.2).round());
  final r = random ?? Random();
  return Duration(milliseconds: lo + r.nextInt(hi - lo + 1));
}
