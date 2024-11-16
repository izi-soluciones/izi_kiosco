class PaymentObj {
  num amount;
  int id;
  bool isComanda;
  Map custom;
  List<ItemPaymentObj> items;
  String? uuid;

  PaymentObj(
      {required this.id,
      required this.custom,
      required this.amount,
        this.uuid,
      required this.isComanda,
        required this.items});
}

class ItemPaymentObj {
  num quantity;
  String name;
  Map? custom;

  ItemPaymentObj(
      {required this.quantity, required this.custom, required this.name});
}
