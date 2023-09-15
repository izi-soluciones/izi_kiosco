part of 'order_list_bloc.dart';

enum OrderListStatus {
  init,
  errorList,
  successList,
  waitingList,
  errorCancel,
  errorMarkInternal
}
class OrderListState extends Equatable{

  //INPUT VARIABLES
  final InputObj searchInput;
  final InputObj statusInput;
  final InputObj dateStartInput;
  final InputObj dateEndInput;

  //data
  final List<Comanda> orders;
  final List<ConsumptionPoint> consumptionPoints;
  final FiltersComanda filters;


  //STATUS
  final OrderListStatus status;


  //PAGINATION
  final int page;
  final bool loadItems;
  final bool endItems;
  final int totalItems;

  const OrderListState({
    required this.searchInput,
    required this.statusInput,
    required this.dateStartInput,
    required this.dateEndInput,
    required this.orders,
    required this.status,
    required this.filters,
    required this.endItems,
    required this.loadItems,
    required this.totalItems,
    required this.page,
    required this.consumptionPoints
  });

  factory OrderListState.init(){
    return OrderListState(
        searchInput: OrderListInputs.searchInput(),
        statusInput: OrderListInputs.statusInput(value: ""),
        dateEndInput: OrderListInputs.dateEndInput(),
        dateStartInput: OrderListInputs.dateStartInput(),
        orders: const [],
        consumptionPoints: const [],
        status: OrderListStatus.init,
        filters: FiltersComanda(),
        endItems: false,
        loadItems: false,
        totalItems: 0,
        page: 0
    );
  }

  OrderListState copyWith({
    InputObj? searchInput,
    InputObj? statusInput,
    InputObj? dateStartInput,
    InputObj? dateEndInput,
    List<Comanda>? orders,
    List<ConsumptionPoint>? consumptionPoints,
    OrderListStatus? status,
    FiltersComanda? filters,
    int? page,
    bool? loadItems,
    bool? endItems,
    int? totalItems
  }){
    return OrderListState(
        searchInput: searchInput??this.searchInput,
        statusInput: statusInput??this.statusInput,
        dateStartInput: dateStartInput??this.dateStartInput,
        dateEndInput: dateEndInput??this.dateEndInput,
        status: status??this.status,
        filters: filters??this.filters,
        page: page??this.page,
        totalItems: totalItems??this.totalItems,
        loadItems: loadItems??this.loadItems,
        endItems: endItems??this.endItems,
      consumptionPoints: consumptionPoints?? this.consumptionPoints,
      orders: orders?? this.orders
    );
  }


  @override
  List<Object?> get props => [
    searchInput,
    statusInput,
    consumptionPoints,
    dateStartInput,
    dateEndInput,
    orders,
    status,
    endItems,
    loadItems,
    totalItems
  ];
}