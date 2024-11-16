part of 'make_order_retail_bloc.dart';
enum MakeOrderRetailStatus{waitingGet,successGet,errorGet,successEmit,errorCashRegisters,errorStore,errorEmit,successEdit,errorActivity}


class MakeOrderRetailState extends Equatable{

  final MakeOrderRetailStatus status;
  final List<Item> items;

  final List<Item> itemsSelected;

  final Currency? currentCurrency;
  final int step;




  const MakeOrderRetailState({required this.items,required this.step,required this.status,this.currentCurrency, required this.itemsSelected});

  factory MakeOrderRetailState.init(){
    return const MakeOrderRetailState(
      items:[],
        status: MakeOrderRetailStatus.waitingGet,
        itemsSelected:[],
        step:0,
    );
  }

  MakeOrderRetailState copyWith({
    MakeOrderRetailStatus? status,
    List<Item>? itemsSelected,
    List<Item>? items,
    Currency? currentCurrency,
    List<Item>? itemsFeatured,
    int? step
}){
    return MakeOrderRetailState(
        status: status ?? this.status,
      items: items ?? this.items,
      itemsSelected: itemsSelected ?? this.itemsSelected,
      currentCurrency: currentCurrency ?? this.currentCurrency,
      step: step ?? this.step,
    );
  }

  @override
  List<Object?> get props => [items,step,status,itemsSelected,currentCurrency];

}