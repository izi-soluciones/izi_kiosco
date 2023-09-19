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

  final List<CategoryOrder> itemsSelected;

  final List<Item> itemsFeatured;

  final int indexCategory;

  final Currency? currentCurrency;

  final num discountAmount;

  final MakeOrderDiscountOffset? offsetDiscount;

  final String? tableId;
  final List<ConsumptionPoint> tables;
  final int? numberDiners;
  final List<CashRegister> cashRegisters;
  final bool review;




  const MakeOrderState({required this.review,required this.itemsFeatured,this.order,this.errorDescription,required this.cashRegisters,required this.tables,this.tableId,this.numberDiners,this.offsetDiscount,required this.discountAmount,required this.status,this.currentCurrency, required this.categories, required this.indexCategory,required this.itemsSelected});

  factory MakeOrderState.init(String? tableId,int? numberDiners,Comanda? order){
    List<CategoryOrder> initSelectItems=[];
    if(order!=null){
      for(var item in order.listaItems){
        var itemNew=Item(
            cantidad: item.cantidad ?? 0,
            codigo: item.codigo,
            customItem: item.customItem,
            descripcion: item.descripcion,
            imagen: item.imagen,
            modificadores: item.modificadoresEdit is List? (item.modificadoresEdit as List).map((e) => Modifier.fromJson(e)).toList():[],
            modificadoresRaw: item.modificadoresEdit,
            precioModificadores: item.precioModificadores??0,
            nombre: item.nombre,
            valor: item.valor,
            activo: true,
            id: item.item??0,
            precioUnitario: item.precioUnitario??0,
            categoria: item.categoria,
            categoriaId: item.categoriaId,
            centroProduccion: 1,
            codigoBarras: ""
        );

        int indexCategory= initSelectItems.indexWhere((element) => element.id==item.categoriaId);
        if(indexCategory==-1){
          initSelectItems.add(CategoryOrder(
              nombre: itemNew.categoria??"", id:itemNew.categoriaId, items:[itemNew]));
        }
        else{
          initSelectItems[indexCategory].items.add(itemNew);
        }
      }
    }
    return MakeOrderState(
        status: MakeOrderStatus.waitingGet,
        categories: const [],
        itemsSelected: initSelectItems,
        indexCategory: 0,
        discountAmount: order?.descuentos ?? 0,
        tableId: tableId ?? order?.mesa,
        numberDiners: numberDiners ?? (order?.custom is Map?order?.custom["cantidadComensales"]:null),
        tables: const [],
        cashRegisters: const [],
        order: order,
      itemsFeatured: const [],
      review:false,
    );
  }

  MakeOrderState copyWith({
    MakeOrderStatus? status,
    List<CategoryOrder>? categories,
    int? indexCategory,
    List<CategoryOrder>? itemsSelected,
    Currency? currentCurrency,
    num? discountAmount,
    MakeOrderDiscountOffset? Function()? offsetDiscount,
    String? Function()? tableId,
    int? Function()? numberDiners,
    List<ConsumptionPoint>? tables,
    List<CashRegister>? cashRegisters,
    String? errorDescription,
    List<Item>? itemsFeatured,
    bool? review
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
      review: review ?? this.review
    );
  }

  @override
  List<Object?> get props => [review,itemsFeatured,status,cashRegisters,tables,categories,errorDescription,indexCategory,itemsSelected,currentCurrency,discountAmount,offsetDiscount,tableId,numberDiners];

}