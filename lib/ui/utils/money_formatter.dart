extension DateFormatter on num{
  String moneyFormat({String? currency}){
    return "${currency?.isNotEmpty ?? false? "$currency ":""}${toStringAsFixed(2)}";
  }

  double symbioticFormat(){
    return num.parse(toStringAsFixed(2))*100;
  }
}