import 'dart:async';
import 'dart:developer' as developer;

import 'bm_api.dart';
import 'bm_backoff.dart';
import 'bm_store.dart';

enum BmReport { ok, final_, retry }

typedef BmReportFn = Future<BmReport> Function(String id, Map<String, dynamic> body, {String? deviceToken});

final _idPattern = RegExp(r'^[A-Za-z0-9_-]+$');
final _tokenPattern = RegExp(r'^izd_[A-Za-z0-9_-]{16,128}$');
const _retryLimit = Duration(hours: 24);

class _Pending {
  final String id;
  final Map<String, dynamic> body;
  final String? deviceToken;
  final DateTime receivedAt;
  int failures = 1;

  _Pending(this.id, this.body, this.deviceToken, this.receivedAt);
}

class BmCommands {
  final BmStore _store;
  final BmReportFn _report;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _delay;
  final _queue = <_Pending>[];
  Future<void>? _worker;

  BmCommands({
    required BmStore store,
    required BmReportFn report,
    DateTime Function()? now,
    Future<void> Function(Duration)? delay,
  })  : _store = store,
        _report = report,
        _now = now ?? DateTime.now,
        _delay = delay ?? Future<void>.delayed;

  Future<void> get idle => _worker ?? Future<void>.value();

  Future<void> handle(List<BmCommand> commands, DateTime serverTime) async {
    for (final command in commands) {
      try {
        await _handleOne(command, serverTime);
      } catch (e) {
        developer.log('comando ${command.type} falló: ${e.runtimeType}', name: 'monitoreo');
      }
    }
  }

  Future<void> _handleOne(BmCommand command, DateTime serverTime) async {
    if (!_idPattern.hasMatch(command.id)) return;
    if (_store.seenCommand(command.id)) return;
    await _store.markCommand(command.id, serverTime);

    final expiresAt = command.expiresAt;
    if (expiresAt == null) return _reject(command.id, 'invalid_command');
    if (!expiresAt.isAfter(serverTime)) return _reject(command.id, 'expired');

    if (command.type != 'rotate_token') return _reject(command.id, 'unsupported');

    final token = command.args['deviceToken'];
    if (token is! String || !_tokenPattern.hasMatch(token)) return _reject(command.id, 'invalid_command');
    await _store.replaceDeviceToken(token);
    await _send(command.id, {'status': 'succeeded', 'detail': 'token_rotated'}, token);
  }

  Future<void> _reject(String id, String reason) {
    return _send(id, {
      'status': 'rejected',
      'detail': reason,
      'data': {'reason': reason},
    }, null);
  }

  Future<void> _send(String id, Map<String, dynamic> body, String? deviceToken) async {
    final result = await _attempt(id, body, deviceToken);
    if (result != BmReport.retry) return;
    _queue.add(_Pending(id, body, deviceToken, _now()));
    _worker ??= _drain();
  }

  Future<BmReport> _attempt(String id, Map<String, dynamic> body, String? deviceToken) async {
    try {
      return await _report(id, body, deviceToken: deviceToken);
    } catch (_) {
      return BmReport.retry;
    }
  }

  Future<void> _drain() async {
    try {
      while (_queue.isNotEmpty) {
        final item = _queue.first;
        await _delay(bmBackoff(item.failures));
        if (_now().difference(item.receivedAt) >= _retryLimit) {
          developer.log('resultado de comando descartado tras 24 h', name: 'monitoreo');
          _queue.removeAt(0);
          continue;
        }
        final result = await _attempt(item.id, item.body, item.deviceToken);
        if (result == BmReport.retry) {
          item.failures++;
        } else {
          _queue.removeAt(0);
        }
      }
    } finally {
      _worker = null;
    }
  }
}
