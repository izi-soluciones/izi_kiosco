import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/data/local/local_storage_room.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/internal_movement_dto.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/domain/models/room.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/utils/download_utils.dart';
part 'tables_state.dart';

class TablesBloc extends Cubit<TablesState> {
  final ComandaRepository _comandaRepository;
  final BusinessRepository _businessRepository;
  TablesBloc(this._comandaRepository,this._businessRepository) : super(TablesState.init());

  init(AuthState authState) async {
    try {
      if(authState.currentContribuyente?.habilitadoMesas==false || (authState.currentSucursal?.config?["restaurantPagoAdelantado"] ?? false)==true){
        emit(state.copyWith(status: TablesStatus.errorPermissions));
        emit(state.copyWith(status: TablesStatus.init));
        return;
      }
      emit(state.copyWith(status: TablesStatus.waitingGet));
      List<Room> rooms = await _comandaRepository.getRooms(
          authState.currentSucursal?.id ?? 0,
          authState.currentContribuyente?.id ?? 0);
      rooms.removeWhere((element) => element.activo==false);
      if(rooms.isEmpty){
        emit(state.copyWith(status: TablesStatus.errorRooms));
        emit(state.copyWith(status: TablesStatus.init));
        return;
      }
      var currentRoom = await LocalStorageRoom.getRoom();
      var roomIndex = rooms.indexWhere((element) => element.id == currentRoom);
      String? roomId;
      if (roomIndex != -1) {
        roomId = rooms[roomIndex].id;
      } else {
        roomIndex=0;
        roomId = rooms.firstOrNull?.id;
      }
      List<ConsumptionPoint> consumptionPoints =
      await _comandaRepository.getConsumptionPoints(
          authState.currentSucursal?.id ?? 0,
          authState.currentContribuyente?.id ?? 0,roomId: roomId);
      consumptionPoints.removeWhere((element) => element.activo==false);
      List<List<ConsumptionPoint?>> matriz=[];
      List.generate(rooms[roomIndex].height, (indexY) {
        List<ConsumptionPoint?> row=[];
        List.generate(rooms[roomIndex].width, (indexX) {
          var indexCP=consumptionPoints.indexWhere((element) => element.x == indexX && element.y==indexY);
          if(indexCP==-1){
            row.add(null);
          }
          else{
            row.add(consumptionPoints[indexCP]);
          }
        });
        matriz.add(row);
      });
      List<CashRegister> cashRegisters =
      await _businessRepository.getCashRegisters(
          contribuyenteId: authState.currentContribuyente?.id ?? 0,
          sucursalId: authState.currentSucursal?.id ?? 0);
      var indexCashRegisters=cashRegisters.indexWhere((element) => element.abierta==true);
      if(indexCashRegisters==-1){
        emit(state.copyWith(status: TablesStatus.errorCashRegisters));
        emit(state.copyWith(status: TablesStatus.init));
        return;
      }

      emit(state.copyWith(
          status: TablesStatus.successGet,
          rooms: rooms,
          cashRegisters: cashRegisters,
          roomSelected: roomIndex,
          consumptionPoints: matriz));
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(status: TablesStatus.errorGet));
      emit(state.copyWith(status: TablesStatus.init));
    }
  }

  changeRoom(index,String roomId,AuthState authState)async{
    try {
      emit(state.copyWith(status: TablesStatus.waitingGet));
      List<ConsumptionPoint> consumptionPoints =
          await _comandaRepository.getConsumptionPoints(
          authState.currentSucursal?.id ?? 0,
          authState.currentContribuyente?.id ?? 0,roomId: roomId);
      List<List<ConsumptionPoint?>> matriz=[];
      List.generate(state.rooms[index].height, (indexY) {
        List<ConsumptionPoint?> row=[];
        List.generate(state.rooms[index].width, (indexX) {
          var indexCP=consumptionPoints.indexWhere((element) => element.x == indexX && element.y==indexY);
          if(indexCP==-1){
            row.add(null);
          }
          else{
            row.add(consumptionPoints[indexCP]);
          }
        });
        matriz.add(row);
      });
      await LocalStorageRoom.saveRoom(roomId);
      emit(state.copyWith(
          status: TablesStatus.successGet,
          roomSelected: index,
          consumptionPoints: matriz));
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(status: TablesStatus.errorGet));
      emit(state.copyWith(status: TablesStatus.waitingGet));
    }
  }

  downloadDetail(int indexX,int indexY)async {
    try{

      List<List<ConsumptionPoint?>> listOld=List.from(state.consumptionPoints);
      for(var i=0;i<state.consumptionPoints.length;i++){
        listOld[i]=List.from(state.consumptionPoints[i]);
      }
      if(listOld[indexY][indexX]!=null && listOld[indexY][indexX]?.comandaId!=0){
        var newConsumptionPoint = listOld[indexY][indexX]!.copyWith(loading: true);
        listOld[indexY][indexX]= newConsumptionPoint;
        emit(state.copyWith(consumptionPoints: listOld),);
        Comanda order = await _comandaRepository.getComanda(orderId: newConsumptionPoint.comandaId);

        String? pdf = order.detallePdf;
        if(pdf!=null){
          await DownloadUtils().downloadFile(pdf);
        }
        List<List<ConsumptionPoint?>> listNew=List.from(listOld);
        for(var i=0;i<listOld.length;i++){
          listNew[i]=List.from(listOld[i]);
        }
        listNew[indexY][indexX]= newConsumptionPoint.copyWith(loading: false);
        emit(state.copyWith(consumptionPoints: listNew));
        return order;
      }
      return null;
    }
    catch(e){
      log(e.toString());
    }
  }
  Future<Comanda?> getComanda(int indexX,int indexY)async{
    try{

      List<List<ConsumptionPoint?>> listOld=List.of(state.consumptionPoints);
      for(var i=0;i<state.consumptionPoints.length;i++){
        listOld[i]=List.from(state.consumptionPoints[i]);
      }
      if(listOld[indexY][indexX]!=null && listOld[indexY][indexX]?.comandaId!=0){
        var newConsumptionPoint = listOld[indexY][indexX]!.copyWith(loading: true);
        listOld[indexY][indexX]= newConsumptionPoint;
        emit(state.copyWith(consumptionPoints: listOld),);
        Comanda order = await _comandaRepository.getComanda(orderId: newConsumptionPoint.comandaId);

        List<List<ConsumptionPoint?>> listNew=List.of(listOld);
        for(var i=0;i<listOld.length;i++){
          listNew[i]=List.from(listOld[i]);
        }
        listNew[indexY][indexX]= newConsumptionPoint.copyWith(loading: false);
        emit(state.copyWith(consumptionPoints: listNew));
        return order;
      }
      return null;
    }
    catch(e){
      log(e.toString());
      emit(state.copyWith(status: TablesStatus.errorGetOrder));
      emit(state.copyWith(status: TablesStatus.successGet));
      return null;
    }
  }

  Future changeTableStatus(AuthState authState,indexX,indexY)async{
    try{
      if(state.consumptionPoints[indexY][indexX]!=null){
        await _comandaRepository.freeConsumptionPoint(id:state.consumptionPoints[indexY][indexX]!.id,contribuyente: authState.currentContribuyente?.id??0,sucursal: authState.currentSucursal?.id??0);
        List<List<ConsumptionPoint?>> listNew=List.of(state.consumptionPoints);
        for(var i=0;i<state.consumptionPoints.length;i++){
          listNew[i]=List.from(state.consumptionPoints[i]);
        }
        listNew[indexY][indexX]= state.consumptionPoints[indexY][indexX]!.copyWith(status: ConsumptionPointStatus.available);
        emit(state.copyWith(consumptionPoints: listNew));
      }
    }
    catch(e){
      log(e.toString());
      emit(state.copyWith(status: TablesStatus.errorCancelTable));
      emit(state.copyWith(status: TablesStatus.successGet));
    }
  }

  cancelOrder(int orderId,String? consumptionPointId)async{
    try{
      if(consumptionPointId!=null){
        await _comandaRepository.cancelOrder(orderId: orderId);
        List<List<ConsumptionPoint?>> listNew=List.of(state.consumptionPoints);
        int? index;
        int? indexY;
        for(var i=0;i<state.consumptionPoints.length;i++){
          listNew[i]=List.from(state.consumptionPoints[i]);
          index=state.consumptionPoints[i].indexWhere((element) => element?.id==consumptionPointId);
          if(index != -1){
            indexY=i;
            break;
          }
        }
        if(index !=null && index!=-1 && indexY!=null ){
          listNew[indexY][index]=state.consumptionPoints[indexY][index]?.copyWith(status: ConsumptionPointStatus.available);
          emit(state.copyWith(consumptionPoints: listNew));
        }
      }
    }
    catch(e){
      emit(state.copyWith(status: TablesStatus.errorCancelOrder));
      emit(state.copyWith(status: TablesStatus.successGet));
    }
  }
  markInternal(Comanda orderSelect,String? consumptionPointId)async{
    try{
      var order=orderSelect;
      if(consumptionPointId!=null){
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
          List<List<ConsumptionPoint?>> listNew=List.of(state.consumptionPoints);
          int? index;
          int? indexY;
          for(var i=0;i<state.consumptionPoints.length;i++){
            listNew[i]=List.from(state.consumptionPoints[i]);
            index=state.consumptionPoints[i].indexWhere((element) => element?.id==consumptionPointId);
            if(index != -1){
              indexY=i;
              break;
            }
          }
          if(index !=null && index!=-1 && indexY!=null ){
            listNew[indexY][index]=state.consumptionPoints[indexY][index]?.copyWith(status: ConsumptionPointStatus.available);
            emit(state.copyWith(consumptionPoints: listNew));
          }
        }
      }
    }
    catch(e){
      emit(state.copyWith(status: TablesStatus.errorCancelOrder));
      emit(state.copyWith(status: TablesStatus.successGet));
    }
  }
  
}
