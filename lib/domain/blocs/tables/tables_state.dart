part of 'tables_bloc.dart';

enum TablesStatus {
  init,
  errorGet,
  successGet,
  waitingGet,
  errorRooms,
  getOrder,
  successGetOrder,
  errorGetOrder,
  errorCancelOrder,
  errorCancelTable,
  errorCashRegisters,
  errorPermissions
}

class TablesState extends Equatable {
  //data
  final List<List<ConsumptionPoint?>> consumptionPoints;
  final List<Room> rooms;
  final List<CashRegister> cashRegisters;

  //STATUS
  final TablesStatus status;

  //VARIABLES
  final int roomSelected;

  const TablesState(
      {required this.status,
      required this.consumptionPoints,
      required this.rooms,
      required this.roomSelected,
      required this.cashRegisters});

  factory TablesState.init() {
    return const TablesState(
        consumptionPoints: [],
        status: TablesStatus.init,
        rooms: [],
        roomSelected: 0,
        cashRegisters: []);
  }

  TablesState copyWith(
      {List<List<ConsumptionPoint?>>? consumptionPoints,
      List<Room>? rooms,
      TablesStatus? status,
      int? roomSelected,
      List<CashRegister>? cashRegisters}) {
    return TablesState(
        status: status ?? this.status,
        consumptionPoints: consumptionPoints ?? this.consumptionPoints,
        rooms: rooms ?? this.rooms,
        roomSelected: roomSelected ?? this.roomSelected,
        cashRegisters: cashRegisters ?? this.cashRegisters);
  }

  @override
  List<Object?> get props =>
      [consumptionPoints, status, rooms, cashRegisters, roomSelected];
}
