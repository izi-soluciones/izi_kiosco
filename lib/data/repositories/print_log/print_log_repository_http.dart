import 'package:dio/dio.dart';
import 'package:izi_kiosco/data/core/dio_client.dart';
import 'package:izi_kiosco/domain/dto/print_log_dto.dart';
import 'package:izi_kiosco/domain/repositories/print_log_repository.dart';

class PrintLogRepositoryHttp extends PrintLogRepository{
  final DioClient _dioClient = DioClient();

  @override
  Future<void> sendLogs({required List<PrintLogDto> eventos, required int sucursalId}) async{
    String path = "/dispositivos/logs-impresion";
    var response = await _dioClient.post(
        uri: path,
        body: {"eventos": eventos.map((e) => e.toJson()).toList()},
        options: Options(responseType: ResponseType.json,headers: {
      "Izi-Sucursal":sucursalId
    }));
    if (response.statusCode != 200) {
      throw response.data;
    }
  }
}
