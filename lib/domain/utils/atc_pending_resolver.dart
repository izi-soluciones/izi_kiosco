import 'dart:developer';

import 'package:izi_kiosco/data/local/local_storage_atc_pending.dart';
import 'package:izi_kiosco/domain/models/atc_payment_status.dart';
import 'package:izi_kiosco/domain/models/atc_pending_payment.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';

/// Cierra los intentos de cobro ATC guardados localmente (contingencia, sección 4.5).
class AtcPendingResolver {
  AtcPendingResolver._();

  // Más viejos que esto se borran: siguen visibles en la página de contingencia del servidor
  static const Duration maxAge = Duration(days: 7);
  static bool _running = false;

  /// Confirma al servidor (best-effort) y borra el intento local. Nunca lanza.
  static Future<void> settle(
      ComandaRepository comandaRepository, AtcPendingPayment pending,
      {bool confirm = true}) async {
    if (confirm) {
      try {
        await comandaRepository.confirmPaymentATC(pending.ref);
      } catch (e) {
        log("No se pudo confirmar el cobro ATC ${pending.ref}: $e");
      }
    }
    try {
      await LocalStorageAtcPending.removePending(pending.ref);
    } catch (e) {
      log("No se pudo borrar el cobro ATC ${pending.ref}: $e");
    }
  }

  /// resuelto por caja → borrar; aprobado → markPaymentATC + confirmar + borrar; rechazado →
  /// confirmar + borrar; noEncontrado → borrar; enCurso, sinRespuesta o sin respuesta del
  /// servidor → se deja; pasado maxAge, sinRespuesta/enCurso o sin respuesta del servidor → borrar.
  static Future<void> resolve(ComandaRepository comandaRepository,
      {Duration markTimeout = const Duration(seconds: 30)}) async {
    if (_running) {
      return;
    }
    _running = true;
    try {
      final pendingList = await LocalStorageAtcPending.getPending();
      for (var pending in pendingList) {
        AtcPaymentStatus status;
        try {
          status = await comandaRepository.getPaymentStatusATC(pending.ref);
        } catch (e) {
          log("Cobro ATC ${pending.ref} sin respuesta del servidor: $e");
          if (DateTime.now().difference(pending.createdAt) > maxAge) {
            await settle(comandaRepository, pending, confirm: false);
          }
          continue;
        }
        // Caja lo resolvió con la página de contingencia: el kiosko no lo registra
        if (status.resuelto) {
          await settle(comandaRepository, pending, confirm: false);
          continue;
        }
        if (status.isApproved) {
          // Ya confirmado: el kiosko lo procesó y no alcanzó a borrarlo
          if (!status.confirmado) {
            try {
              // Con timeout: un markPaymentATC colgado dejaría tomada la guarda hasta reiniciar
              await comandaRepository
                  .markPaymentATC(pending.uuid, pending.intentoPago)
                  .timeout(markTimeout);
            } catch (e) {
              final sameAttempt = _paidBySameAttempt(e, pending);
              if (sameAttempt == null) {
                log("No se pudo completar el cobro ATC ${pending.ref}: $e");
                continue;
              }
              // Ya estaba pagado: si fue este mismo intento se confirma; si no se sabe,
              // se borra sin confirmar para que caja lo vea como "Aprobado sin confirmar"
              log("Cobro ATC ${pending.ref} ya estaba pagado: $e");
              await settle(comandaRepository, pending, confirm: sameAttempt);
              continue;
            }
          }
          await settle(comandaRepository, pending, confirm: !status.confirmado);
        } else if (status.isRejected || status.isNotFound) {
          await settle(comandaRepository, pending, confirm: status.isRejected);
        } else if ((status.estado == AtcPaymentStatus.noResponse ||
                status.estado == AtcPaymentStatus.inProgress) &&
            DateTime.now().difference(pending.createdAt) > maxAge) {
          // Ya no llega un resultado tardío (el servidor los asigna dentro de 10 min): sin confirmar,
          // la página de contingencia lo sigue mostrando a caja
          await settle(comandaRepository, pending, confirm: false);
        }
      }
    } catch (e) {
      log("Error resolviendo cobros ATC pendientes: $e");
    } finally {
      _running = false;
    }
  }

  /// El backbone rechaza un segundo markPaymentATC con "ya fue pagado" (procesarNotificacionPago).
  /// null: no es ese rechazo. true: lo pagó este mismo intento, porque el registro que quedó pagado
  /// es solo suyo: el intento de pago en retail ("El intento de pago ya fue pagado") o la solicitud
  /// de cobro en comanda (generarSolicitudCobro crea una por intento). false: no se puede saber
  /// (en retail "El cobro ya fue pagado" es la venta entera, que otro intento o medio pudo pagar).
  static bool? _paidBySameAttempt(Object error, AtcPendingPayment pending) {
    final message = error.toString();
    if (!message.contains("ya fue pagado")) {
      return null;
    }
    if (pending.kind == AtcPaymentKind.retail) {
      return message.contains("El intento de pago ya fue pagado");
    }
    return message.contains("El cobro ya fue pagado");
  }
}
