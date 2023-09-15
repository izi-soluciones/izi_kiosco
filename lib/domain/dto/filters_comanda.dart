import 'package:izi_kiosco/domain/utils/date_formatter.dart';

class FiltersComanda{
  String? status;
  String? searchStr;
  int? sucursal;
  DateTime? dateStart;
  DateTime? dateEnd;

  FiltersComanda({this.status, this.searchStr, this.sucursal,this.dateEnd,this.dateStart});

  Map<String,dynamic> toJson()=>{
    "estado": status,
    "searchStr": searchStr,
    "sucursal": sucursal,
    "desde": dateStart?.dateFormat(DateFormatterType.data),
    "hasta": dateEnd?.dateFormat(DateFormatterType.data),
  };

  @override
  String toString() {
    return 'FiltersComanda{status: $status, searchStr: $searchStr, sucursal: $sucursal, dateStart: $dateStart, dateEnd: $dateEnd}';
  }
}