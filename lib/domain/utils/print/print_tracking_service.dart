import 'dart:convert';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/data/local/local_storage_print_logs.dart';
import 'package:izi_kiosco/domain/dto/print_log_dto.dart';
import 'package:izi_kiosco/domain/repositories/print_log_repository.dart';
import 'package:izi_kiosco/domain/utils/print/client_info_stub.dart'
    if (dart.library.html) 'package:izi_kiosco/domain/utils/print/client_info_html.dart';
import 'package:izi_kiosco/domain/utils/print/print_result.dart';

class PrintTrackingService {
  final PrintLogRepository _printLogRepository;
  final Random _random = Random();

  PrintTrackingService(this._printLogRepository);

  String generarEventoId() {
    var ahora = DateTime.now().microsecondsSinceEpoch;
    var aleatorio = _random.nextInt(0xFFFFFF).toRadixString(16);
    return "$ahora-$aleatorio";
  }

  PrintLogDto construirEvento({
    required PrintResult resultado,
    required String tipoDocumento,
    required int intento,
    int? dispositivoId,
    String? dispositivoNombre,
    int? cajaId,
    int? comandaId,
    String? comandaUuid,
    int? facturaId,
    int? numeroOrden,
    int? numeroOrdenCustom,
  }) {
    return PrintLogDto(
      eventoId: generarEventoId(),
      dispositivoId: dispositivoId,
      dispositivoNombre: dispositivoNombre,
      cajaId: cajaId,
      comandaId: comandaId,
      comandaUuid: comandaUuid,
      facturaId: facturaId,
      numeroOrden: numeroOrden,
      numeroOrdenCustom: numeroOrdenCustom,
      tipoDocumento: tipoDocumento,
      via: resultado.viaLog,
      resultado: resultado.resultadoLog,
      intento: intento,
      errorMensaje: resultado.error,
      duracionMs: resultado.duracionMs,
      userAgent: obtenerUserAgent(),
      versionApp: AppConstants.appVersion,
      fechaDispositivo: DateTime.now().toIso8601String(),
    );
  }

  // Fire-and-forget: si el POST falla, el evento queda en el buffer local y se reintenta
  // en el próximo flush. Nunca propaga: el logging no puede tumbar el flujo de pago.
  Future<void> registrar(PrintLogDto evento,
      {required int sucursalId, required bool habilitado}) async {
    if (!habilitado) {
      return;
    }
    try {
      await _printLogRepository
          .sendLogs(eventos: [evento], sucursalId: sucursalId);
    } catch (e) {
      log("Log de impresión pendiente: $e");
      await LocalStoragePrintLogs.add(jsonEncode(evento.toJson()));
    }
  }

  Future<void> flush({required int sucursalId, required bool habilitado}) async {
    if (!habilitado) {
      return;
    }
    try {
      var pendientes = await LocalStoragePrintLogs.getAll();
      if (pendientes.isEmpty) {
        return;
      }

      List<PrintLogDto> eventos = [];
      List<String> enviados = [];
      for (var pendiente in pendientes) {
        try {
          eventos.add(PrintLogDto.fromJson(jsonDecode(pendiente)));
          enviados.add(pendiente);
        } catch (_) {
          // Entrada corrupta: se descarta para que no bloquee el buffer para siempre.
          enviados.add(pendiente);
        }
      }

      if (eventos.isNotEmpty) {
        await _printLogRepository.sendLogs(
            eventos: eventos, sucursalId: sucursalId);
      }
      await LocalStoragePrintLogs.remove(enviados);
    } catch (e) {
      log("Flush de logs de impresión falló: $e");
    }
  }
}
