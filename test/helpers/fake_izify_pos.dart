import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// In-process stand-in for PayPOS (the EcoPay terminal app) that speaks the
/// same kiosk API: `/health`, `/pair`, `/unpair`, `/pay`,
/// `/payment-status/{reference}` and the `/payment-updates` socket.
///
/// Tests steer it through the public fields: what a charge ends in, how long
/// it takes, and whether the terminal answers at all.
class FakeIzifyPos {
  late final HttpServer _server;
  final List<WebSocket> _sockets = [];

  /// The mDNS name PayPOS 1.26+ reports on /health.
  String name = 'izify-POS-48151';
  String appVersion = '1.26-ecopay';

  String? pairedKioskId;
  String? token;
  String? pin;
  Map<String, dynamic> ecopay = {};

  /// Health knobs.
  bool ecopayInstalled = true;
  bool online = true;

  /// What the next charges end in: SUCCESS, ERROR or PENDING; null = never
  /// answer (the charge stays PROCESSING).
  String? outcome = 'SUCCESS';
  String? declineMessage = 'FONDOS INSUFICIENTES';
  Duration chargeDuration = const Duration(milliseconds: 200);

  /// Swallow the /pay response for this long before replying (after the
  /// charge was accepted), to simulate a lost acknowledgement.
  Duration? payResponseDelay;

  /// Reply 503 NOT_CONFIGURED / 409 BUSY to the next /pay.
  bool refuseNotReady = false;
  bool refuseBusy = false;

  final Map<String, Map<String, dynamic>> results = {};
  final Set<String> accepted = {};
  final List<Map<String, dynamic>> charges = [];
  int payRequests = 0;
  int pairRequests = 0;

  // Kept after close(), so a test can still name the address it had.
  late final int port;
  String get hostPort => '127.0.0.1:$port';

  static Future<FakeIzifyPos> start({int port = 0}) async {
    final pos = FakeIzifyPos();
    pos._server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    pos.port = pos._server.port;
    pos._server.listen(pos._handle);
    return pos;
  }

  Future<void> close() async {
    for (final s in _sockets) {
      await s.close();
    }
    await _server.close(force: true);
  }

  /// Settles [reference] later, as PayPOS does when a late broker answer
  /// arrives for a charge it reported PENDING.
  void settle(String reference, String status, {String? message}) {
    final result = {
      'status': status,
      'transactionId': 'TRX-1-${reference.hashCode.abs()}',
      'errorMessage': message,
      'reference': reference,
    };
    results[reference] = result;
    accepted.remove(reference);
    for (final s in _sockets) {
      s.add(jsonEncode(result));
    }
  }

  bool _authorized(HttpRequest req) {
    final header = req.headers.value('authorization');
    return token != null && header == 'Bearer $token';
  }

  Future<void> _json(HttpRequest req, int status, Object? body) async {
    req.response.statusCode = status;
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(body));
    await req.response.close();
  }

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path;
    try {
      if (path == '/payment-updates' && WebSocketTransformer.isUpgradeRequest(req)) {
        final ws = await WebSocketTransformer.upgrade(req);
        if (req.uri.queryParameters['token'] != token || token == null) {
          await ws.close(1008, 'Invalid token');
          return;
        }
        _sockets.add(ws);
        ws.listen((_) {}, onDone: () => _sockets.remove(ws));
        return;
      }

      final body = req.method == 'POST'
          ? jsonDecode(await utf8.decoder.bind(req).join().then((b) => b.isEmpty ? '{}' : b))
          : null;

      switch (path) {
        case '/health':
          return _json(req, 200, {
            'status': 'OK',
            'batteryLevel': 90,
            'hasPaper': true,
            'isOnline': online,
            'paired': pairedKioskId != null,
            'ready': pairedKioskId != null && ecopayInstalled && ecopay.isNotEmpty,
            'ecopayInstalled': ecopayInstalled,
            'ecopayVersion': ecopayInstalled ? 'v1.1.8_test' : null,
            'missingConfig': pairedKioskId == null
                ? ['mqttClientId', 'mqttUserName', 'mqttPassword', 'commerceId']
                : const <String>[],
            'busy': accepted.isNotEmpty,
            'canOpenScreens': true,
            'appVersion': appVersion,
            'name': name,
            'pairedKioskHash': pairedKioskId == null
                ? null
                : sha256.convert(utf8.encode(pairedKioskId!)).toString().substring(0, 16),
          });
        case '/pair':
          pairRequests++;
          if (body['pin'] == null || body['pin'].toString().isEmpty) {
            return _json(req, 400, {'success': false, 'token': null, 'message': 'PIN is required'});
          }
          if (pairedKioskId != null && pairedKioskId != body['kioskId']) {
            return _json(req, 409, {'success': false, 'token': null, 'message': 'Device is already paired to another Kiosk'});
          }
          pairedKioskId = body['kioskId'];
          pin = body['pin'];
          ecopay = Map.of(body)..remove('kioskId')..remove('pin');
          token = 'tok-${DateTime.now().microsecondsSinceEpoch}';
          return _json(req, 200, {'success': true, 'token': token, 'message': 'Paired successfully'});
        case '/unpair':
          if (!_authorized(req)) return _json(req, 401, 'Invalid or missing Bearer token');
          pairedKioskId = null;
          token = null;
          return _json(req, 200, 'Unpaired successfully');
        case '/pay':
          payRequests++;
          if (!_authorized(req)) {
            return _json(req, 401, {'success': false, 'code': 'UNAUTHORIZED', 'message': 'Invalid or missing Bearer token'});
          }
          final reference = body['reference'] as String?;
          final expected = Hmac(sha256, utf8.encode(token!))
              .convert(utf8.encode('${body['amount']}|${body['currency'] ?? 'COP'}|${reference ?? ''}'))
              .toString();
          if (body['signature'] != expected) {
            return _json(req, 403, {'success': false, 'code': 'INVALID_SIGNATURE', 'message': 'Invalid Signature'});
          }
          if (refuseNotReady) {
            refuseNotReady = false;
            return _json(req, 503, {'success': false, 'code': 'NOT_CONFIGURED', 'message': 'Faltan datos de EcoPay en el emparejamiento.'});
          }
          if (refuseBusy) {
            refuseBusy = false;
            return _json(req, 409, {'success': false, 'code': 'BUSY', 'message': 'El datáfono está procesando otro pago.'});
          }
          if (accepted.contains(reference) || results.containsKey(reference)) {
            return _json(req, 409, {'success': false, 'code': 'DUPLICATE_REFERENCE', 'message': 'Este pago ya fue recibido; consulte su estado.'});
          }
          accepted.add(reference!);
          charges.add(Map<String, dynamic>.from(body));
          final outcomeNow = outcome;
          if (outcomeNow != null) {
            Timer(chargeDuration, () => settle(reference, outcomeNow,
                message: outcomeNow == 'SUCCESS' ? null : declineMessage));
          }
          if (payResponseDelay != null) await Future.delayed(payResponseDelay!);
          return _json(req, 202, {'success': true, 'message': 'Payment initiated', 'reference': reference});
        default:
          if (path.startsWith('/payment-status/')) {
            if (!_authorized(req)) return _json(req, 401, 'Invalid or missing Bearer token');
            final reference = Uri.decodeComponent(path.substring('/payment-status/'.length));
            final result = results[reference];
            if (result != null) return _json(req, 200, result);
            if (accepted.contains(reference)) {
              return _json(req, 200, {'status': 'PROCESSING', 'reference': reference});
            }
            return _json(req, 404, {'success': false, 'code': 'UNKNOWN_REFERENCE', 'message': 'No result for reference'});
          }
          return _json(req, 404, 'not found');
      }
    } catch (e) {
      try {
        await _json(req, 500, {'message': '$e'});
      } catch (_) {}
    }
  }
}
