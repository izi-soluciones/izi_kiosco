import 'package:easy_localization/easy_localization.dart';

enum DateFormatterType{visual,data,visual2,hour,dateHour,dataWithHour}

extension DateFormatter on DateTime{

  String dateFormat(DateFormatterType dateFormatterType){
    switch(dateFormatterType){
      case DateFormatterType.visual:
        return "${day.toString().padLeft(2,"0")}/${month.toString().padLeft(2,"0")}/$year";

      case DateFormatterType.data:
        return "$year-${month.toString().padLeft(2,"0")}-${day.toString().padLeft(2,"0")}";
      case DateFormatterType.dataWithHour:
        return toUtc().toIso8601String();
      case DateFormatterType.visual2:
        return "${day.toString().padLeft(2,"0")} ${"general.date.months.${month.toString()}".tr()} $year";
      case DateFormatterType.dateHour:
        return "${day.toString().padLeft(2,"0")}/${month.toString().padLeft(2,"0")}/$year ${hour.toString().padLeft(2,"0")}:${minute.toString().padLeft(2,"0")}";
      case DateFormatterType.hour:
        return "${hour.toString().padLeft(2,"0")}:${minute.toString().padLeft(2,"0")}";
    }
  }

  static String changeFormatter(String date,DateFormatterType dateFormatterType){
    var pattern="";
    var patternDif="";
    switch(dateFormatterType){
      case DateFormatterType.visual:
        pattern="-";
        patternDif="/";
        break;
      case DateFormatterType.data:
        pattern="/";
        patternDif="-";
        break;
      default:
        return "";
    }
    var data=date.split(pattern);
    if(data.length!=3){
      return date;
    }
    return data[2]+patternDif+data[1]+patternDif+data[0];
  }

  static double getDateFactorChart({required DateTime init,required DateTime end,required int interval}){
    return (end.millisecondsSinceEpoch-init.millisecondsSinceEpoch)/interval;
  }

}