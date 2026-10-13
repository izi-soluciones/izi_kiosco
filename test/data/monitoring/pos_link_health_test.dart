import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/pos_link_health.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/telemetry/pos_telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';

void main() {
  late DateTime now;
  late KioskCounters counters;
  late PosLinkHealth link;

  setUp(() {
    now = DateTime.utc(2026, 10, 12, 14);
    counters = KioskCounters(now: () => now);
    link = PosLinkHealth(now: () => now, counters: () => counters);
    Telemetry.install(Telemetry());
  });

  test('before any check nothing is known', () {
    final view = link.view();
    expect(view.lastOk, isNull);
    expect(view.lastOkAt, isNull);
    expect(view.consecutiveFailures, 0);
    expect(view.latencyMsP50, isNull);
    expect(view.failedRecently, isFalse);
  });

  test('an answer resets the failures in a row and keeps its latency', () {
    link.failed(address: '10.0.0.5:8081', cause: 'timeout');
    link.failed(address: '10.0.0.5:8081', cause: 'timeout');
    expect(link.view().consecutiveFailures, 2);
    expect(link.view().lastCause, 'timeout');

    now = now.add(const Duration(seconds: 30));
    link.answered(address: '10.0.0.5:8081', ms: 85);
    final view = link.view();
    expect(view.lastOk, isTrue);
    expect(view.lastOkAt, now);
    expect(view.consecutiveFailures, 0);
    expect(view.lastCause, isNull);
    expect(view.latencyMsP50, 85);
    expect(view.address, '10.0.0.5:8081');
    expect(view.failedRecently, isTrue, reason: 'the misses are within 5 minutes');
  });

  test('failures older than five minutes no longer count as recent', () {
    link.failed(cause: 'refused');
    link.answered(ms: 10);
    now = now.add(PosLinkHealth.degradedWindow + const Duration(seconds: 1));
    expect(link.view().failedRecently, isFalse);
  });

  test('the latency is the median of the last 20 answers', () {
    for (final ms in [10, 20, 30, 40, 500]) {
      link.answered(ms: ms);
    }
    expect(link.view().latencyMsP50, 30);
    link.answered(ms: 50);
    expect(link.view().latencyMsP50, 35, reason: 'even count: mean of the middle two');
    for (var i = 0; i < PosLinkHealth.latencySamples; i++) {
      link.answered(ms: 7);
    }
    expect(link.view().latencyMsP50, 7);
  });

  test('keeps the terminal report and why it cannot charge', () {
    final health = IzifyPosHealth.fromJson({'status': 'OK', 'batteryLevel': 12, 'name': 'izify-POS-1'});
    link.answered(ms: 40, notReadyReason: 'Sin papel', terminal: health);
    expect(link.view().terminal, same(health));
    expect(link.view().notReadyReason, 'Sin papel');
    link.answered(ms: 40);
    expect(link.view().terminal, same(health), reason: 'an answer without a report keeps the last one');
    expect(link.view().notReadyReason, isNull);
  });

  test('every check is counted, and every failure', () {
    link.answered(ms: 10);
    link.failed(cause: 'timeout');
    link.failed(cause: 'timeout');
    expect(counters[KioskCounters.posHealthChecks], 3);
    expect(counters[KioskCounters.posHealthFailures], 2);
  });

  group('causes', () {
    test('only the contract words go out', () {
      for (final cause in ['timeout', 'refused', 'unreachable', 'dns', 'closed', 'cors', 'no_answer', 'http_503']) {
        expect(PosLinkHealth.contractCause(cause), cause);
      }
      for (final cause in ['browser_blocked', 'socket_54', 'client_error', 'unknown', 'StateError']) {
        expect(PosLinkHealth.contractCause(cause), 'unreachable');
      }
    });

    test('a probe refines the browser\'s cause, and later sampled misses keep it', () {
      link.failed(cause: 'browser_blocked');
      expect(link.view().lastCause, 'unreachable');
      link.refineCause('cors');
      expect(link.view().lastCause, 'cors');
      link.failed(cause: 'browser_blocked');
      expect(link.view().lastCause, 'cors');
      link.failed(cause: 'timeout');
      expect(link.view().lastCause, 'timeout');
    });

    test('a probe that comes back after an answer changes nothing', () {
      link.failed(cause: 'browser_blocked');
      link.answered(ms: 10);
      link.refineCause('refused');
      expect(link.view().lastCause, isNull);
    });

    test('the ATC / Linkser bridge errors', () {
      final options = RequestOptions(path: '/verify-connection');
      expect(PosLinkHealth.bridgeFailureCause(
              DioException(requestOptions: options, type: DioExceptionType.receiveTimeout)),
          'timeout');
      expect(PosLinkHealth.bridgeFailureCause(DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: options, statusCode: 502))),
          'http_502');
      expect(PosLinkHealth.bridgeFailureCause(
              DioException(requestOptions: options, type: DioExceptionType.connectionError)),
          'unreachable');
      expect(PosLinkHealth.bridgeFailureCause('{"connection": false}'), 'unreachable');
    });
  });

  test('reset forgets the terminal', () {
    link.failed(address: '10.0.0.5:8081', cause: 'timeout');
    link.reset();
    final view = link.view();
    expect(view.lastOk, isNull);
    expect(view.address, isNull);
    expect(view.consecutiveFailures, 0);
  });

  group('PosLinkTracker feeds it', () {
    const address = IzifyPosAddress('10.0.0.5');

    test('failures and answers of every loop add up', () async {
      final config = PosLinkTracker('pos_config', link: () => link);
      final home = PosLinkTracker('home', link: () => link);
      await config.failed(
          address: address, rid: 'a', ms: 3000, error: IzifyPosException('x', cause: TimeoutException('health')));
      await home.failed(
          address: address, rid: 'b', ms: 3000, error: IzifyPosException('x', cause: TimeoutException('health')));
      expect(link.view().consecutiveFailures, 2);
      expect(link.view().lastCause, 'timeout');

      final health = IzifyPosHealth.fromJson({'status': 'OK', 'paired': true, 'name': 'izify-POS-1'});
      home.answered(address: address, ms: 60, health: health);
      expect(link.view().consecutiveFailures, 0);
      expect(link.view().terminal, same(health));
      expect(link.view().address, '10.0.0.5:8081');
    });
  });
}
