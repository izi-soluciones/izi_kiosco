import 'dart:convert';

import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/repositories/comanda/comanda_repository_http.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_event.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/pos_payment_result.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';

/// Settles the card charges this kiosk lost track of.
///
/// The payment page writes each charge as `IN_PROGRESS` before waiting for
/// the terminal's verdict. When the page dies meanwhile (a crash, a restart,
/// someone pressing F5), the terminal still finishes the charge, and nothing
/// told iZi: the customer paid for an order that does not exist. On the next
/// start, once the terminal answers, this asks it about every such row:
/// - approved: registers the order with the charge's own token;
/// - declined or cancelled: records it, so it can be retried;
/// - still running or unknown: leaves it for the next pass.
///
/// It also retries the notice for charges that were approved but could not
/// be registered at the time (no network, no token), while their token lasts.
class CardChargeRecovery {
  CardChargeRecovery({ComandaRepository? repository, IzifyPosClient? client})
      : _givenRepository = repository,
        _client = client ?? IzifyPosClient();

  static final CardChargeRecovery instance = CardChargeRecovery();

  /// References the running page is still waiting for: not lost, not ours.
  static final Set<String> active = {};

  /// Between two passes.
  static const Duration minInterval = Duration(minutes: 1);

  final ComandaRepository? _givenRepository;
  // Built on first use: the HTTP client reads the app settings, which are not
  // loaded yet when the POS screen first checks the terminal.
  late final ComandaRepository _repository = _givenRepository ?? ComandaRepositoryHttp();
  final IzifyPosClient _client;
  DateTime? _lastRun;
  bool _running = false;

  /// Runs a pass unless one ran within [minInterval]. Never throws.
  Future<void> maybeRun(Device? device) async {
    final last = _lastRun;
    if (_running || (last != null && DateTime.now().difference(last) < minInterval)) {
      return;
    }
    _running = true;
    _lastRun = DateTime.now();
    try {
      await run(device);
    } catch (_) {
      // Best effort: the rows stay as they are for the next pass.
    } finally {
      _running = false;
    }
  }

  /// One pass over the stored charges. Returns how many rows it settled.
  Future<int> run(Device? device) async {
    final rows = await LocalStorageCardErrors.getErrors();
    final lost = <CardPayment>[];
    final unregistered = <CardPayment>[];
    for (final row in rows) {
      final CardPayment cp;
      try {
        final json = jsonDecode(row);
        if (json is! Map) continue;
        cp = CardPayment.fromJsonStorage(json);
      } catch (_) {
        continue;
      }
      final reference = cp.reference;
      if (reference == null || active.contains(reference)) continue;
      if (cp.inProgress) {
        lost.add(cp);
      } else if (cp.chargedNotRegistered &&
          cp.markUuid != null &&
          cp.markToken != null &&
          _tokenMayStillWork(cp)) {
        unregistered.add(cp);
      }
    }
    if (lost.isEmpty && unregistered.isEmpty) return 0;

    var settled = 0;
    for (final cp in unregistered) {
      if (await _register(cp, recovered: false)) settled++;
    }
    if (lost.isEmpty) return settled;

    final session = await IzifyPosSession.current(device);
    if (session == null) return settled;
    for (final cp in lost) {
      final result = await _client.paymentStatus(session.address,
          token: session.token, reference: cp.reference!);
      if (await _settleLost(cp, result)) settled++;
    }
    return settled;
  }

  Future<bool> _settleLost(CardPayment cp, PosPaymentResult result) async {
    _takeProof(cp, result);
    switch (result.status) {
      case PosPaymentStatus.success:
        cp.status = 'SUCCESS';
        cp.response = 'Aprobada';
        return _register(cp, recovered: true);
      case PosPaymentStatus.error:
      case PosPaymentStatus.cancelled:
        final cancelled = result.status == PosPaymentStatus.cancelled;
        cp.status = cancelled ? 'CANCELLED' : 'ERROR';
        cp.response = 'Rechazada - ${result.errorMessage ?? 'verificada al reanudar'}'.trim();
        await _store(cp);
        final uuid = cp.markUuid;
        if (uuid != null) {
          try {
            await _repository.reportTerminalResult(uuid, cp.markInternalId,
                cp.terminalData(cancelled ? 'CANCELADA' : 'RECHAZADA'),
                token: cp.markToken);
          } catch (_) {}
        }
        Telemetry.event('charge.recovered',
            chargeId: cp.chargeId,
            reference: cp.reference,
            data: {'status': cp.status});
        return true;
      case PosPaymentStatus.notFound:
        // The terminal has no record of it: it may have been reinstalled or
        // replaced since, so this is no proof that nothing was charged.
        cp.status = 'UNKNOWN';
        cp.response = 'Sin confirmar - el datáfono no tiene registro del cobro';
        await _store(cp);
        Telemetry.event('charge.recovered',
            level: TelemetryLevel.warning,
            issue: true,
            chargeId: cp.chargeId,
            reference: cp.reference,
            data: const {'status': 'not_found'});
        return true;
      case PosPaymentStatus.pending:
      case PosPaymentStatus.processing:
      case PosPaymentStatus.unknown:
      case PosPaymentStatus.unauthorized:
      case PosPaymentStatus.unreachable:
        // No verdict yet: asked again on the next pass.
        return false;
    }
  }

  /// Tells iZi an approved charge was paid. Returns whether it was registered.
  Future<bool> _register(CardPayment cp, {required bool recovered}) async {
    final uuid = cp.markUuid;
    Object? error;
    var registered = false;
    if (uuid != null) {
      try {
        await _repository.markPaymentATC(uuid, cp.markInternalId,
            transaccion: cp.terminalData('APROBADA'), token: cp.markToken);
        registered = true;
      } catch (e) {
        error = e;
      }
    }
    cp.status = 'SUCCESS';
    cp.response = registered
        ? 'Aprobada - pedido registrado${recovered ? ' (recuperado)' : ''}'
        : uuid == null
            ? 'Aprobada - registre el pedido manualmente'
            // iZi holds another payment for it: a person has to look, and
            // asking again cannot change the answer.
            : error is PaymentConflict
                ? 'Aprobada - conflicto en iZi: $error'
                : 'Aprobada - Error sync server: ${error ?? 'desconocido'}';
    await _store(cp);
    Telemetry.event(registered ? 'charge.registered_late' : 'charge.register_failed',
        level: registered ? TelemetryLevel.warning : TelemetryLevel.error,
        issue: !registered,
        chargeId: cp.chargeId,
        reference: cp.reference,
        data: {
          'recovered': recovered,
          if (error != null) 'error': '$error',
        });
    return registered;
  }

  /// iZi signs each charge's token for two days: past that, asking again
  /// every minute would only repeat the same rejection.
  bool _tokenMayStillWork(CardPayment cp) {
    final day = DateTime.tryParse(cp.date);
    return day != null && DateTime.now().difference(day) < const Duration(days: 2);
  }

  Future<void> _store(CardPayment cp) =>
      LocalStorageCardErrors.updateByReference(cp.reference!, jsonEncode(cp.toJson()));

  void _takeProof(CardPayment cp, PosPaymentResult result) {
    if (result.transactionId != null) cp.transactionId = result.transactionId;
    if (result.cardMasked != null) cp.cardNumber = result.cardMasked;
    cp.authCode = result.authCode ?? cp.authCode;
    cp.cardBrand = result.cardBrand ?? cp.cardBrand;
    cp.cardType = result.cardType ?? cp.cardType;
    cp.acquirerTerminalId = result.acquirerTerminalId ?? cp.acquirerTerminalId;
    cp.traceNumber = result.traceNumber ?? cp.traceNumber;
  }
}
