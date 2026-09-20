import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:izi_kiosco/domain/models/pos_payment_result.dart';

/// Where an Izify POS (EcoPay terminal running PayPOS) listens on the LAN.
class IzifyPosAddress {
  static const int defaultPort = 8081;

  final String host;
  final int port;

  const IzifyPosAddress(this.host, [this.port = defaultPort]);

  /// Parses `ip`, `ip:port` or a value with stray spaces/scheme, as it may
  /// come from the backend (`config.ipEcopay`) or local storage.
  static IzifyPosAddress? tryParse(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.isEmpty) return null;
    value = value.replaceFirst(RegExp(r'^[a-z]+://', caseSensitive: false), '');
    value = value.split('/').first;
    final parts = value.split(':');
    final host = parts.first.trim();
    if (host.isEmpty) return null;
    final port = parts.length > 1 ? int.tryParse(parts[1].trim()) : null;
    return IzifyPosAddress(host, port ?? defaultPort);
  }

  String get hostPort => '$host:$port';

  Uri http(String path) => Uri.parse('http://$host:$port$path');

  Uri paymentUpdates(String token) => Uri.parse(
      'ws://$host:$port/payment-updates?token=${Uri.encodeQueryComponent(token)}');

  @override
  bool operator ==(Object other) =>
      other is IzifyPosAddress && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);

  @override
  String toString() => hostPort;
}

/// What the terminal reports on `GET /health`. Fields added in PayPOS 1.25
/// are null when talking to an older terminal.
class IzifyPosHealth {
  final bool? paired;
  final bool? ready;
  final bool? ecopayInstalled;
  final String? ecopayVersion;
  final List<String> missingConfig;
  final bool? busy;
  final bool? canOpenScreens;
  final bool? isOnline;
  final bool? hasPaper;
  final int? batteryLevel;
  final String? appVersion;

  /// The terminal's mDNS instance name (`izify-POS-<pin>`), stable across
  /// reboots and address changes. PayPOS 1.26+.
  final String? name;

  /// [IzifyPosClient.kioskHash] of the kiosk this terminal is paired with,
  /// null when unpaired. PayPOS 1.26+.
  final String? pairedKioskHash;

  /// True when the terminal was unpaired on purpose; a kiosk must not pair
  /// with it again by itself. PayPOS 1.26+.
  final bool? unpairedByUser;

  /// Which payment app the terminal drives: `ECOPAY`, `MOCK` or `AKUA`.
  /// PayPOS 1.26+; older ones are EcoPay when they report [ecopayInstalled].
  final String? terminalType;

  /// EcoPay's own report of its broker connection (PayPOS 1.26+); null when
  /// EcoPay has been silent (not initialized, or its service is not running).
  final bool? ecopayConnected;
  final Map<String, dynamic> raw;

  const IzifyPosHealth({
    this.paired,
    this.ready,
    this.ecopayInstalled,
    this.ecopayVersion,
    this.missingConfig = const [],
    this.busy,
    this.canOpenScreens,
    this.isOnline,
    this.hasPaper,
    this.batteryLevel,
    this.appVersion,
    this.name,
    this.pairedKioskHash,
    this.unpairedByUser,
    this.terminalType,
    this.ecopayConnected,
    this.raw = const {},
  });

  factory IzifyPosHealth.fromJson(Map<String, dynamic> json) => IzifyPosHealth(
        paired: json['paired'] as bool?,
        ready: json['ready'] as bool?,
        ecopayInstalled: json['ecopayInstalled'] as bool?,
        ecopayVersion: json['ecopayVersion']?.toString(),
        missingConfig: (json['missingConfig'] is List)
            ? (json['missingConfig'] as List).map((e) => e.toString()).toList()
            : const [],
        busy: json['busy'] as bool?,
        canOpenScreens: json['canOpenScreens'] as bool?,
        isOnline: json['isOnline'] as bool?,
        hasPaper: json['hasPaper'] as bool?,
        batteryLevel: (json['batteryLevel'] as num?)?.toInt(),
        appVersion: json['appVersion']?.toString(),
        name: json['name']?.toString(),
        pairedKioskHash: json['pairedKioskHash']?.toString(),
        unpairedByUser: json['unpairedByUser'] as bool?,
        terminalType: json['terminalType']?.toString().toUpperCase(),
        ecopayConnected: json['ecopayConnected'] as bool?,
        raw: json,
      );

  /// Whether pairing needs the EcoPay CAJA credentials.
  bool get isEcoPay => terminalType != null ? terminalType == 'ECOPAY' : ecopayInstalled != null;

  /// True when the answer comes from PayPOS and not from some other HTTP
  /// server that happens to listen on the same port.
  bool get isIzifyPos =>
      raw['status'] == 'OK' &&
      (raw.containsKey('isOnline') || raw.containsKey('paired') || name != null);

  /// Why a charge cannot start on this terminal, in Spanish, or null.
  /// Older terminals that do not report readiness are given the benefit of
  /// the doubt; `/pay` will still refuse if they are not ready.
  String? get notReadyReason {
    if (paired == false) return 'El datáfono no está emparejado con este kiosko.';
    if (ecopayInstalled == false) {
      return 'La app EcoPay no está instalada en el datáfono.';
    }
    if (missingConfig.isNotEmpty) {
      return 'Faltan datos de EcoPay en el datáfono (${missingConfig.join(', ')}).';
    }
    if (isOnline == false) return 'El datáfono no tiene conexión a internet.';
    if (ecopayConnected == false) {
      return 'La app EcoPay del datáfono no está conectada a su servidor.';
    }
    if (ready == false) return 'El datáfono no está listo para cobrar.';
    return null;
  }
}

/// A call to the terminal that failed.
///
/// [charged] says what the kiosk may assume about the card:
/// - `false`: the terminal refused before charging, or never received the
///   request. Safe to show "no se cobró" and let the customer retry.
/// - `null`: unknown. The request may have reached the terminal, so the
///   outcome has to be looked up by reference before anything else.
class IzifyPosException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final bool? charged;

  const IzifyPosException(this.message,
      {this.code, this.statusCode, this.charged = false});

  bool get outcomeUnknown => charged == null;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// HTTP client for the PayPOS kiosk API (`/health`, `/pair`, `/pay`,
/// `/payment-status/{reference}`, `/unpair`). See the PayPOS repo README for
/// the contract. Every call has a deadline: the kiosk UI must never hang on a
/// terminal that went away.
class IzifyPosClient {
  static const Duration healthTimeout = Duration(seconds: 4);
  static const Duration pairTimeout = Duration(seconds: 8);
  static const Duration payTimeout = Duration(seconds: 10);
  static const Duration statusTimeout = Duration(seconds: 5);

  final http.Client _http;

  /// Builds the connection used for each `/pay`. A charge never reuses a
  /// pooled keep-alive socket: if the terminal restarted since the last
  /// call, a stale socket fails as "connection closed", which cannot tell
  /// "never received" from "received and charging". A fresh connection
  /// fails as "refused" instead, which is unambiguous.
  final http.Client Function() _payClientFactory;
  final bool _closePayClient;

  IzifyPosClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client(),
        _payClientFactory = httpClient != null ? (() => httpClient) : http.Client.new,
        _closePayClient = httpClient == null;

  static final Random _random = Random.secure();

  /// A reference no other kiosk order will reuse. The terminal refuses a
  /// reference it has already seen, so it has to be unique per attempt.
  static String newReference() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final suffix = List.generate(4, (_) => _random.nextInt(36).toRadixString(36))
        .join()
        .toUpperCase();
    return 'KOS-$millis-$suffix';
  }

  /// The fields an EcoPay pairing needs, as `/pair` names them.
  static const ecoPayRequiredFields = ['mqttClientId', 'mqttUserName', 'mqttPassword', 'commerceId'];

  /// What to tell the technician when an EcoPay terminal is paired without
  /// its CAJA credentials.
  static String missingEcoPayMessage(List<String> missing) =>
      'Este datáfono es EcoPay y faltan sus credenciales de caja'
      '${missing.isEmpty ? '' : ' (${missing.join(', ')})'}. '
      'Cárguelas en el backend (ecopayConfig del dispositivo) o en "Parámetros Avanzados EcoPay" y vuelva a emparejar.';

  /// How a terminal names the kiosk it is paired with on `/health`: the first
  /// 16 hex chars of SHA-256([kioskId]).
  static String kioskHash(String kioskId) =>
      sha256.convert(utf8.encode(kioskId)).toString().substring(0, 16);

  /// HMAC-SHA256 of `amount|currency|reference`, keyed with the pairing token.
  static String sign(
          {required String token,
          required String amount,
          required String currency,
          required String reference}) =>
      Hmac(sha256, utf8.encode(token))
          .convert(utf8.encode('$amount|$currency|$reference'))
          .toString();

  Future<IzifyPosHealth> health(IzifyPosAddress address, {Duration timeout = healthTimeout}) async {
    final http.Response res;
    try {
      res = await _http.get(address.http('/health')).timeout(timeout);
    } catch (e) {
      throw IzifyPosException(_unreachable(address), code: 'UNREACHABLE');
    }
    if (res.statusCode != 200) {
      throw IzifyPosException('El datáfono respondió ${res.statusCode}.',
          statusCode: res.statusCode);
    }
    final data = _decode(res.body);
    return IzifyPosHealth.fromJson(data is Map<String, dynamic> ? data : {});
  }

  /// Pairs this kiosk and returns the token for every later call.
  Future<String> pair(
    IzifyPosAddress address, {
    required String kioskId,
    required String pin,
    Map<String, String?> ecopay = const {},
  }) async {
    final http.Response res;
    try {
      res = await _http
          .post(
            address.http('/pair'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'kioskId': kioskId,
              'pin': pin,
              for (final e in ecopay.entries)
                if (e.value != null && e.value!.trim().isNotEmpty)
                  e.key: e.value!.trim(),
            }),
          )
          .timeout(pairTimeout);
    } catch (e) {
      throw IzifyPosException(_unreachable(address), code: 'UNREACHABLE');
    }

    final data = _decode(res.body);
    if (res.statusCode == 200 && data is Map && data['success'] == true) {
      final token = data['token']?.toString();
      if (token != null && token.isNotEmpty) return token;
    }
    switch (res.statusCode) {
      case 409:
        throw const IzifyPosException(
            'El datáfono ya está emparejado con otro kiosko. Desvincúlelo desde su panel de control (esquina superior izquierda) y vuelva a intentar.',
            code: 'PAIRED_ELSEWHERE',
            statusCode: 409);
      case 400 when data is Map && data['code'] == 'MISSING_ECOPAY_CONFIG':
        throw IzifyPosException(
            IzifyPosClient.missingEcoPayMessage(
                (data['missing'] as List?)?.map((e) => e.toString()).toList() ?? const []),
            code: 'MISSING_ECOPAY_CONFIG',
            statusCode: 400);
      case 400:
        throw IzifyPosException(
            'El datáfono rechazó el emparejamiento: ${_message(data) ?? 'solicitud inválida'}. Verifique el PIN del dispositivo y la versión de PayPOS.',
            code: 'PAIR_REJECTED',
            statusCode: 400);
      default:
        throw IzifyPosException(
            'No se pudo emparejar el datáfono (${res.statusCode}).',
            statusCode: res.statusCode);
    }
  }

  Future<void> unpair(IzifyPosAddress address, String token) async {
    try {
      await _http
          .post(address.http('/unpair'),
              headers: {'Authorization': 'Bearer $token'})
          .timeout(healthTimeout);
    } catch (_) {
      // Best effort: the kiosk forgets the pairing either way.
    }
  }

  /// Asks the terminal to charge [amount]. Returns once the terminal accepted
  /// the request (HTTP 202); the verdict comes later over the socket or
  /// [paymentStatus].
  Future<void> pay(
    IzifyPosAddress address, {
    required String token,
    required String amount,
    required String currency,
    required String reference,
    required String cardType,
    required int quotas,
  }) async {
    final parsed = double.tryParse(amount);
    if (parsed == null || parsed <= 0) {
      throw const IzifyPosException('El monto debe ser un número positivo.',
          code: 'INVALID_AMOUNT');
    }

    final http.Response res;
    final payClient = _payClientFactory();
    try {
      res = await payClient
          .post(
            address.http('/pay'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'amount': amount,
              'currency': currency,
              'reference': reference,
              'signature': sign(
                  token: token,
                  amount: amount,
                  currency: currency,
                  reference: reference),
              'cardType': cardType,
              'quotas': quotas,
              'sendTicket': 0,
            }),
          )
          .timeout(payTimeout);
    } on TimeoutException {
      throw const IzifyPosException('El datáfono no confirmó la recepción del cobro.',
          code: 'PAY_TIMEOUT', charged: null);
    } catch (e) {
      // Connection refused / no route: the request never left this kiosk.
      // A reset after connecting is different: it may have been read.
      // package:http wraps socket errors in ClientException, so both are
      // classified by what the platform said.
      if (_neverConnected(e)) {
        throw IzifyPosException(_unreachable(address), code: 'UNREACHABLE');
      }
      throw IzifyPosException('Se perdió la conexión con el datáfono.',
          code: 'CONNECTION_LOST', charged: null);
    } finally {
      if (_closePayClient) payClient.close();
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = _decode(res.body);
      if (data is Map && data['success'] == false) {
        throw IzifyPosException(
            _message(data) ?? 'Transacción rechazada por el datáfono.',
            statusCode: res.statusCode);
      }
      return;
    }

    final data = _decode(res.body);
    final code = data is Map ? data['code']?.toString() : null;
    final message = _message(data);
    if (res.statusCode == 409 && code == 'DUPLICATE_REFERENCE') {
      // The terminal already has this order: whatever happened to it is
      // what happened. Only the status lookup can tell.
      throw IzifyPosException(message ?? 'El datáfono ya recibió este cobro.',
          code: code, statusCode: 409, charged: null);
    }
    throw IzifyPosException(
      switch (res.statusCode) {
        401 => 'El datáfono no reconoce a este kiosko. Es necesario volver a emparejar.',
        403 => 'El datáfono rechazó la firma del cobro. Verifique que el kiosko y PayPOS estén actualizados.',
        409 => message ?? 'El datáfono está procesando otro pago.',
        503 => message ?? 'El datáfono no está listo para cobrar.',
        _ => message ?? 'El datáfono rechazó el cobro (${res.statusCode}).',
      },
      code: code,
      statusCode: res.statusCode,
    );
  }

  /// Looks up the outcome of the charge sent with [reference]. Never throws:
  /// an unreachable terminal is reported as [PosPaymentStatus.unreachable].
  Future<PosPaymentResult> paymentStatus(
    IzifyPosAddress address, {
    required String token,
    required String reference,
  }) async {
    try {
      final res = await _http.get(
        address.http('/payment-status/${Uri.encodeComponent(reference)}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(statusTimeout);
      if (res.statusCode == 404) {
        return PosPaymentResult(
            status: PosPaymentStatus.notFound, reference: reference);
      }
      if (res.statusCode == 401) {
        return PosPaymentResult(
            status: PosPaymentStatus.unauthorized, reference: reference);
      }
      if (res.statusCode == 200) {
        final data = _decode(res.body);
        if (data is Map) return PosPaymentResult.fromJson(data);
      }
      return PosPaymentResult(
          status: PosPaymentStatus.unknown, reference: reference);
    } catch (_) {
      return PosPaymentResult(
          status: PosPaymentStatus.unreachable, reference: reference);
    }
  }

  /// Whether [token] still opens the terminal at [address]: `false` when it
  /// answers 401 (it was unpaired, reinstalled or paired with another kiosk),
  /// null when it could not be asked. Probes a reference that never exists,
  /// so it works with every PayPOS version and never touches a charge.
  Future<bool?> tokenAccepted(IzifyPosAddress address, String token) async {
    final probe = await paymentStatus(address,
        token: token, reference: 'KOS-PROBE-${DateTime.now().millisecondsSinceEpoch}');
    return switch (probe.status) {
      PosPaymentStatus.unauthorized => false,
      PosPaymentStatus.notFound => true,
      _ => null,
    };
  }

  static bool _neverConnected(Object e) {
    // ECONNREFUSED (61 macOS / 111 Linux+Android), EHOSTUNREACH (65/113),
    // ENETUNREACH (51/101): no connection ever existed.
    const neverConnected = {61, 111, 65, 113, 51, 101};
    if (e is SocketException) {
      final code = e.osError?.errorCode;
      if (code != null && neverConnected.contains(code)) return true;
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('connection refused') ||
        msg.contains('failed host lookup') ||
        msg.contains('no route to host') ||
        msg.contains('network is unreachable') ||
        msg.contains('errno = 61') ||
        msg.contains('errno = 111');
  }

  static String _unreachable(IzifyPosAddress address) =>
      'No se pudo conectar con el datáfono en ${address.hostPort}. Verifique que esté encendido y en la misma red que el kiosko.';

  static dynamic _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static String? _message(dynamic data) {
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
