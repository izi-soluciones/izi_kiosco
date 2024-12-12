part of 'make_order_bloc.dart';
enum MakeOrderStatus{waitingGet,successGet,errorGet,successEmit,errorCashRegisters,errorEmit,successEdit}


class MakeOrderDiscountOffset{
  double x;
  double y;

  MakeOrderDiscountOffset(this.x, this.y);
}
class MakeOrderState extends Equatable{
  final Comanda? order;
  final String? errorDescription;

  final MakeOrderStatus status;
  final List<CategoryOrder> categories;

  final List<Item> itemsSelected;

  final List<Item> itemsFeatured;

  final int indexCategory;

  final Currency? currentCurrency;

  final num discountAmount;

  final MakeOrderDiscountOffset? offsetDiscount;

  final String? tableId;
  final List<ConsumptionPoint> tables;
  final int? numberDiners;
  final List<CashRegister> cashRegisters;
  final int step;

  final bool takeAway;


  final Item? itemModal;




  const MakeOrderState({required this.itemModal,required this.takeAway,required this.step,required this.itemsFeatured,this.order,this.errorDescription,required this.cashRegisters,required this.tables,this.tableId,this.numberDiners,this.offsetDiscount,required this.discountAmount,required this.status,this.currentCurrency, required this.categories, required this.indexCategory,required this.itemsSelected});

  factory MakeOrderState.init(){
    List<Item> initSelectItems=[];
    return MakeOrderState(
        status: MakeOrderStatus.waitingGet,
        categories: const [],
        itemsSelected: initSelectItems,
        indexCategory: 0,
        discountAmount: 0,
        tables: const [],
        cashRegisters: const [],
      takeAway: true,
      itemsFeatured: const [],
      itemModal: null,
      step:0,
    );
  }

  MakeOrderState copyWith({
    MakeOrderStatus? status,
    List<CategoryOrder>? categories,
    int? indexCategory,
    List<Item>? itemsSelected,
    Currency? currentCurrency,
    num? discountAmount,
    MakeOrderDiscountOffset? Function()? offsetDiscount,
    String? Function()? tableId,
    int? Function()? numberDiners,
    List<ConsumptionPoint>? tables,
    List<CashRegister>? cashRegisters,
    String? errorDescription,
    List<Item>? itemsFeatured,
    int? step,
bool? takeAway,
    Item? Function()? itemModal
}){
    return MakeOrderState(
        status: status ?? this.status,
        categories: categories ?? this.categories,
        indexCategory: indexCategory ?? this.indexCategory,
      itemsSelected: itemsSelected ?? this.itemsSelected,
      currentCurrency: currentCurrency ?? this.currentCurrency,
      discountAmount: discountAmount ?? this.discountAmount,
      offsetDiscount:offsetDiscount !=null?offsetDiscount() : this.offsetDiscount,
      tableId: tableId !=null? tableId() : this.tableId,
      numberDiners: numberDiners !=null?numberDiners() : this.numberDiners,
      tables: tables ?? this.tables,
      cashRegisters: cashRegisters ?? this.cashRegisters,
      errorDescription: errorDescription ?? this.errorDescription,
      order: order,
      itemsFeatured: itemsFeatured ?? this.itemsFeatured,
      step: step ?? this.step,
takeAway: takeAway ?? this.takeAway,
      itemModal: itemModal != null? itemModal():this.itemModal
    );
  }

  @override
  List<Object?> get props => [itemModal,takeAway,step,itemsFeatured,status,cashRegisters,tables,categories,errorDescription,indexCategory,itemsSelected,currentCurrency,discountAmount,offsetDiscount,tableId,numberDiners];

}