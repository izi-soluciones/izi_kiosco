import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_backoff.dart';

void main() {
  test('cada valor queda en [30 s, 30 min]', () {
    final random = Random(1);
    for (var failures = 0; failures < 40; failures++) {
      for (var i = 0; i < 50; i++) {
        final d = bmBackoff(failures, random: random);
        expect(d >= const Duration(seconds: 30), isTrue, reason: '$failures $d');
        expect(d <= const Duration(minutes: 30), isTrue, reason: '$failures $d');
      }
    }
  });

  test('failures=0 da 30 s +-20 % dentro del rango', () {
    final random = Random(1);
    for (var i = 0; i < 100; i++) {
      final ms = bmBackoff(0, random: random).inMilliseconds;
      expect(ms, inInclusiveRange(30000, 36000));
    }
  });

  test('failures=3 queda en 240 s +-20 %', () {
    final random = Random(1);
    for (var i = 0; i < 100; i++) {
      final ms = bmBackoff(3, random: random).inMilliseconds;
      expect(ms, inInclusiveRange(192000, 288000));
    }
  });

  test('failures=20 da como máximo 30 min y no desborda', () {
    final random = Random(1);
    for (final f in [20, 63, 64, 1000000]) {
      for (var i = 0; i < 100; i++) {
        final d = bmBackoff(f, random: random);
        expect(d <= const Duration(minutes: 30), isTrue);
        expect(d >= const Duration(minutes: 24), isTrue);
      }
    }
  });

  test('sin Random explícito también funciona', () {
    expect(bmBackoff(2) >= const Duration(seconds: 30), isTrue);
  });
}
