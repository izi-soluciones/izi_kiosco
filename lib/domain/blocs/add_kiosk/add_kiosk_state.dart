part of 'add_kiosk_bloc.dart';
enum AddKioskStatus {init,waiting,okSave,okCashRegister,errorSave,errorCashRegister}
class AddKioskState extends Equatable{
  final AddKioskStatus status;
  final List<CashRegister> cashRegisters;
  const AddKioskState({required this.status,required this.cashRegisters});

  factory AddKioskState.init()=>const AddKioskState(status: AddKioskStatus.init,cashRegisters: []);

  AddKioskState copyWith({
    AddKioskStatus? status,
    List<CashRegister>? cashRegisters,
}){
    return AddKioskState(status: status?? this.status,cashRegisters: cashRegisters ?? this.cashRegisters);
  }
  @override
  List<Object?> get props => [status,cashRegisters];

}