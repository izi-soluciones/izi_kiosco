import 'package:izi_kiosco/domain/models/currency.dart';

class FormatUtils{
  static String getCurrency(List<Currency> currencies,dynamic id){
    int index = currencies.indexWhere((element) => element.id == id);
    if(index!=-1){
      return currencies[index].simbolo;
    }
    return "Bs";
  }
}