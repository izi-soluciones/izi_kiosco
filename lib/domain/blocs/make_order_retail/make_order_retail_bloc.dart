import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
part 'make_order_retail_state.dart';

class MakeOrderRetailBloc extends Cubit<MakeOrderRetailState> {
  final ComandaRepository _comandaRepository;
  final BusinessRepository _businessRepository;
  MakeOrderRetailBloc(this._comandaRepository,this._businessRepository)
      : super(MakeOrderRetailState.init());

  init(AuthState authState) async {
    try {
      int indexCurrency = authState.currencies.indexWhere((element) =>
          element.id ==
          authState.currentContribuyente?.config["monedaInventario"]);
      Currency? currentCurrency;
      if (indexCurrency != -1) {
        currentCurrency = authState.currencies.elementAtOrNull(indexCurrency);
      }



      List<Item> list = await _comandaRepository.getSaleItems(authState.currentSucursal?.id ?? 0,);

      List<CashRegister> cashRegisters =
      await _businessRepository.getCashRegisters(
          contribuyenteId: authState.currentContribuyente?.id ?? 0,
          sucursalId: authState.currentSucursal?.id ?? 0);
      var indexCashRegisters=cashRegisters.indexWhere((element) => element.abierta==true);
      if(indexCashRegisters==-1){
        emit(state.copyWith(status: MakeOrderStatus.errorCashRegisters));
        emit(state.copyWith(status: MakeOrderStatus.waitingGet));
        return;
      }
      if(!isClosed){
        emit(state.copyWith(
            status: MakeOrderStatus.successGet,
            items: list,
            currentCurrency: currentCurrency));
      }
    } catch (e) {
      log(e.toString());

      emit(state.copyWith(status: MakeOrderStatus.errorGet));
      emit(state.copyWith(status: MakeOrderStatus.waitingGet));
    }
  }

  changeStepStatus(int step){
    emit(state.copyWith(step:step));
  }



  addItem({int? index, required Item item}) {
  }

  resetItems(){
    emit(state.copyWith(itemsSelected: []));
  }



  Future<Comanda?> emitOrder(AuthState authState)async{
    try{
      return null;
    }
    catch(err){
      log(err.toString());
      emit(state.copyWith(status: MakeOrderStatus.errorEmit));
      emit(state.copyWith(status: MakeOrderStatus.successGet));
      return null;
    }
  }


}
