import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/filters_comanda.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/domain/utils/date_formatter.dart';
import 'package:izi_kiosco/domain/dto/internal_movement_dto.dart';
part 'order_list_state.dart';
part 'order_list_inputs.dart';


class OrderListBloc extends Cubit<OrderListState>{
  final ComandaRepository _comandaRepository;
  OrderListBloc(this._comandaRepository):super(OrderListState.init());

  getOrders({bool first=false,FiltersComanda? filtersNew, bool puntoConsumo = false,
    required AuthState authState})async{
    try{
      final filters=filtersNew??state.filters;
      filters.sucursal=authState.currentSucursal?.id??0;
      if(first){
        emit(state.copyWith(
            status: OrderListStatus.waitingList,
            page: 0,
            loadItems: true
        ));
      }
      else{
        emit(state.copyWith(
            loadItems: true
        ));
      }
      List<ConsumptionPoint>? consumptionPoints;
      if(puntoConsumo){
        try{
          consumptionPoints=await _comandaRepository.getConsumptionPoints(authState.currentSucursal?.id??0, authState.currentContribuyente?.id??0);
        }
        catch(_){}
      }
      List<Comanda> orders=await _comandaRepository.getComandas(page: state.page+1,filters: filters);

      emit(state.copyWith(
        status: OrderListStatus.successList,
        page: state.page+1,
        filters: filters,
        consumptionPoints: consumptionPoints,
        loadItems: false,
        endItems: orders.isEmpty || orders.length<AppConstants.paginationSize,
        orders: first?orders:[...state.orders,...orders],
      ));
    }
    catch(e){
      log(e.toString());
      emit(state.copyWith(status: OrderListStatus.errorList));
      emit(state.copyWith(status: OrderListStatus.init));

    }
  }
  updateFilters(AuthState authState,FiltersComanda filtersComanda)async{
    try{
      emit(
          state.copyWith(
              statusInput: state.statusInput.changeValue(filtersComanda.status??""),
              dateStartInput: state.dateStartInput.changeValue(filtersComanda.dateStart?.dateFormat(DateFormatterType.visual)??""),
              dateEndInput: state.dateEndInput.changeValue(filtersComanda.dateEnd?.dateFormat(DateFormatterType.visual)??""),
              searchInput: state.searchInput.changeValue(filtersComanda.searchStr??""),
          )
      );
      getOrders(first: true,filtersNew: filtersComanda,authState: authState);
    }
    catch(e){
      emit(state.copyWith(status: OrderListStatus.errorList));
      emit(state.copyWith(status: OrderListStatus.successList));
    }

  }
  resetFilters(AuthState authState)async{
    try{
      FiltersComanda filters=FiltersComanda(sucursal: state.filters.sucursal);
      emit(
          state.copyWith(
              statusInput: state.statusInput.changeValue(""),
              dateStartInput: state.dateStartInput.changeValue(""),
              dateEndInput: state.dateEndInput.changeValue(""),
              searchInput: state.searchInput.changeValue(""),
          )
      );
      getOrders(first: true,filtersNew: filters,authState: authState);
    }
    catch(e){
      emit(state.copyWith(status: OrderListStatus.errorList));
      emit(state.copyWith(status: OrderListStatus.successList));
    }

  }

  resetStatus(){
    emit(state.copyWith(
      status: OrderListStatus.init,
    ));
  }

  changeInputs({
    String? status,
    DateTime? dateStart,
    DateTime? dateEnd,
    String? search
}){
    var filters = state.filters;
    if(status!=null){
      filters.status=status;
      emit(
          state.copyWith(
            statusInput: state.statusInput.changeValue(status),
            filters: filters
          )
      );
    }
    if(dateStart!=null){
      filters.dateStart=dateStart;
      emit(
          state.copyWith(
              dateStartInput: state.dateStartInput.changeValue(dateStart.dateFormat(DateFormatterType.visual)),
              filters: filters
          )
      );
    }
    if(dateEnd!=null){
      filters.dateEnd=dateEnd;
      emit(
          state.copyWith(
              dateEndInput: state.dateEndInput.changeValue(dateEnd.dateFormat(DateFormatterType.visual)),
              filters: filters
          )
      );
    }
    if(search!=null){
    filters.searchStr=search;
      emit(
          state.copyWith(
              searchInput: state.searchInput.changeValue(search),
              filters: filters
          )
      );
    }
  }

  cancelOrder(int orderId)async{
    try{

      await _comandaRepository.cancelOrder(orderId: orderId);
      List<Comanda> list=List.of(state.orders);
      int index=list.indexWhere((element) => element.id==orderId);
      if(index!=-1){
        list[index]=state.orders[index].copyWith(anulada: 1);
        emit(state.copyWith(orders: list));
      }
    }
    catch(e){
      emit(state.copyWith(status: OrderListStatus.errorCancel));
      emit(state.copyWith(status: OrderListStatus.successList));
    }
  }

  markInternal(Comanda orderSelect)async{
    try{
      var order=orderSelect;
      if(order.almacen==null){
        order = await _comandaRepository.getComanda(orderId: order.id);
      }
      if(order.almacen!=null){
        InternalMovementDto internalMovementDto = InternalMovementDto(
            comandaId: order.id,
            almacen: order.almacen!,
            fecha: DateTime.now()
        );
        await _comandaRepository.markInternal(internalMovementDto: internalMovementDto);
        List<Comanda> list=List.of(state.orders);
        int index=list.indexWhere((element) => element.id==order.id);
        if(index!=-1){
          list[index]=state.orders[index].copyWith(consumoInterno: true);
          emit(state.copyWith(orders: list));
        }
      }
    }
    catch(e){
      emit(state.copyWith(status: OrderListStatus.errorMarkInternal));
      emit(state.copyWith(status: OrderListStatus.successList));
    }
  }

}