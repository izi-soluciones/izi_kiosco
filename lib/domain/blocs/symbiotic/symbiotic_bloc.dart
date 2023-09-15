import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'dart:developer' as developer;

import 'package:izi_symbiotic/izi_symbiotic.dart';

part 'symbiotic_state.dart';
class SymbioticBloc extends Cubit<SymbioticState>{

  final IziSymbiotic iziSymbiotic= IziSymbiotic();
  final num amount;
  SymbioticBloc(this.amount):super(SymbioticNormalState.init());

  initTerminal(AuthState authState)async {
    try{
      _initListeners(authState);
      IziSymbiotic().startActiveTerminalListener();
    }
    catch(error){
      emit(SymbioticErrorState(
          error: SymbioticErrorStatus.otherError,
          errorCode:  0,
          errorObject: error
      ));
    }

  }

  makeTransaction()async{
    emit(SymbioticNormalState(status: SymbioticStatus.makingPayment));
    //IziSymbiotic().makeTransaction();
  }

  activateTerminal()async{
    emit(SymbioticNormalState(status: SymbioticStatus.activatingTerminal));
    //IziSymbiotic().activateTerminal();
  }

  _initListeners(AuthState authState){

    iziSymbiotic.isTerminalActive().listen((event) {
      if(event){
        emit(SymbioticNormalState(status: SymbioticStatus.makingPayment));
        IziSymbiotic().makeTransaction(amount.symbioticFormat());
      }
      else{
        emit(SymbioticNormalState(status: SymbioticStatus.activatingTerminal));
        IziSymbiotic().activateTerminal(authState.currentPos?.token??"");
      }
    });
    iziSymbiotic.paymentStatus().listen((event) {
      if(event != null){
        developer.log(event.toString());
        if(event["paymentStatus"]==2){

          emit(SymbioticErrorState(
              error: SymbioticErrorStatus.paymentError,
              errorCode: event["error"] ?? 0,
              errorObject: null
          ));
          return;
        }
        emit(SymbioticNormalState(status: SymbioticStatus.paymentSuccess));
      }
      else{
        emit(SymbioticErrorState(
            error: SymbioticErrorStatus.paymentError,
            errorCode: 0,
            errorObject: null
        ));
      }
    }).onError((error)async{
      /*emit(SymbioticErrorState(
          error: SymbioticErrorStatus.paymentError,
          errorCode: 0,
          errorObject: null
      ));*/
      emit(SymbioticNormalState(status: SymbioticStatus.paymentSuccess));
      await Future.delayed(const Duration(seconds: 2));
      emit(SymbioticNormalState(status: SymbioticStatus.paymentSuccessBack));
    });

    iziSymbiotic.activatingStatus().listen((event) {
      if(event){
        emit(SymbioticNormalState(status: SymbioticStatus.makingPayment));
        IziSymbiotic().makeTransaction(amount.toDouble());
      }
      else{
        emit(SymbioticNormalState(status: SymbioticStatus.terminalInactive));
      }
    });
  }

}