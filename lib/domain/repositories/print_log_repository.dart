import 'package:izi_kiosco/domain/dto/print_log_dto.dart';

abstract class PrintLogRepository{

  Future<void> sendLogs({required List<PrintLogDto> eventos, required int sucursalId});
}
