import 'package:izi_kiosco/domain/utils/date_formatter.dart';
class InternalMovementDto{
  int comandaId;
  int almacen;
  DateTime fecha;

  InternalMovementDto({required this.comandaId, required this.almacen, required this.fecha});

  Map<String,dynamic> toJson()=>{
    "tipoMovimiento":"interna",
    "almacen":almacen,
    "fecha":fecha.dateFormat(DateFormatterType.dataWithHour)
  };
}