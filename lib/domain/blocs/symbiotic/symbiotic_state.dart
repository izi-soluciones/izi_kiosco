part of 'symbiotic_bloc.dart';


abstract class SymbioticState extends Equatable{
}
enum SymbioticStatus{
  init,
  initializing,
  error,
  terminalActive,
  terminalInactive,
  activatingTerminal,
  makingPayment,
  paymentSuccess,
  paymentSuccessBack
}
class SymbioticNormalState extends SymbioticState{
  final SymbioticStatus status;

  SymbioticNormalState(
  {
    required this.status
  });
  factory SymbioticNormalState.init() => SymbioticNormalState(
    status: SymbioticStatus.activatingTerminal
  );


  @override
  List<Object?> get props => [status];
}

enum SymbioticErrorStatus{
  paymentError,
  initError,
  otherError
}

class SymbioticErrorState extends SymbioticState{
  final SymbioticErrorStatus error;
  final num? errorCode;
  final Object? errorObject;

  SymbioticErrorState(
      {
        required this.error,
        required this.errorCode,
        required this.errorObject
      });
  @override
  List<Object?> get props => [error,errorCode,errorObject];

}
