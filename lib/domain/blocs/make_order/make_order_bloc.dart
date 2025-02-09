import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/new_order_dto.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/category_order.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/utils/print/print_template.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
part 'make_order_state.dart';

class MakeOrderBloc extends Cubit<MakeOrderState> {
  final ComandaRepository _comandaRepository;
  final BusinessRepository _businessRepository;
  MakeOrderBloc(this._comandaRepository,this._businessRepository, {String? tableId, int? numberDiners,Comanda? order})
      : super(MakeOrderState.init(tableId, numberDiners,order));

  init(AuthState authState) async {
    try {
      int indexCurrency = authState.currencies.indexWhere((element) =>
          element.id ==
          authState.currentContribuyente?.config["monedaInventario"]);
      Currency? currentCurrency;
      if (indexCurrency != -1) {
        currentCurrency = authState.currencies.elementAtOrNull(indexCurrency);
      }
      
      

      List<CategoryOrder> list = await _comandaRepository.getCategories(
          sucursal: authState.currentSucursal?.id ?? 0,
          contribuyente: authState.currentContribuyente?.id ?? 0);
      var indexAll = list.indexWhere((element) => element.nombre == " Todos");
      CategoryOrder? all;
      List<Item> itemsFeatured=[];
      if (indexAll != -1) {
        all = list.removeAt(indexAll);
        itemsFeatured=all.items.where((element) => element.customItem is Map && element.customItem?["kiosco"]?["destacado"]==true).toList();
      }
      list.sort(
        (a, b) {
          return a.nombre.toLowerCase().compareTo(b .nombre.toLowerCase());
        },
      );
      if(itemsFeatured.isNotEmpty){
        list.insert(0, CategoryOrder(nombre: "", items: itemsFeatured));
      }
      /*if (all != null) {
        all.nombre = all.nombre.trim();
        list.insert(0, all);
      }*/
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
            categories: list,
            indexCategory: 0,
            itemsFeatured: itemsFeatured,
            cashRegisters: cashRegisters,
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

  changeCategory(index) {
    emit(state.copyWith(indexCategory: index));
  }

  removeItem(int indexC, int indexItem) {
    List<CategoryOrder> categories = List.from(state.itemsSelected);
    for (var i = 0; i < state.itemsSelected.length; i++) {
      categories[i] = state.itemsSelected[i].copyWith();
    }
    categories[indexC].items.removeAt(indexItem);
    if (categories[indexC].items.isEmpty) {
      categories.removeAt(indexC);
    }
    emit(state.copyWith(itemsSelected: categories));
  }

  addItem({int? index, required Item item}) {
    num pM = 0;
    for (var m in item.modificadores) {
      for (var c in m.caracteristicas) {
        if (c.check) {
          pM += c.modPrecio * item.cantidad;
        }
      }
    }
    item.precioModificadores = pM;
    List<CategoryOrder> categories = List.from(state.itemsSelected);
    for (var i = 0; i < state.itemsSelected.length; i++) {
      categories[i] = state.itemsSelected[i].copyWith();
    }
    var indexCat =
        categories.indexWhere((element) => element.id == item.categoriaId);
    if (indexCat == -1) {
      categories.add(CategoryOrder(
          nombre: item.categoria ?? "", id: item.categoriaId, items: [item]));
    } else {
      int? indexItem;
      for (var iOld = 0; iOld < categories[indexCat].items.length; iOld++) {
        if (categories[indexCat].items[iOld].id != item.id) {
          continue;
        }
        var same = true;
        for (int i = 0; i < item.modificadores.length; i++) {
          for (int m = 0;
              m < item.modificadores[i].caracteristicas.length;
              m++) {
            if (item.modificadores[i].caracteristicas[m].check !=
                categories[indexCat]
                    .items[iOld]
                    .modificadores[i]
                    .caracteristicas[m]
                    .check) {
              same = false;
              break;
            }
          }
        }
        if (same) {
          indexItem = iOld;
          break;
        }
      }
      if (indexItem != null) {
        item.cantidad = categories[indexCat].items[indexItem].cantidad + 1;
        num pM = 0;
        item.modificadores.map((m) {
          m.caracteristicas.map((c) {
            pM += c.modPrecio * item.cantidad;
          });
        });
        item.precioModificadores = pM;
        categories[indexCat].items[indexItem] = item;
      } else {
        categories[indexCat].items.add(item);
      }
    }
    print(categories.length);
    emit(state.copyWith(itemsSelected: categories));
  }

  resetItems(){
    List<CategoryOrder> categories = [];
    emit(state.copyWith(itemsSelected: categories,indexCategory: 0));
  }

  reloadItems() {
    List<CategoryOrder> categories = List.from(state.itemsSelected);
    for (var i = 0; i < state.itemsSelected.length; i++) {
      categories[i] = state.itemsSelected[i].copyWith();
      for (var item in categories[i].items) {
        num pM = 0;
        for (var m in item.modificadores) {
          for (var c in m.caracteristicas) {
            if (c.check) {
              pM += c.modPrecio * item.cantidad;
            }
          }
        }
        item.precioModificadores = pM;
      }
    }
    emit(state.copyWith(itemsSelected: categories));
  }

  changeDiscountAmount(num? amount) {
    emit(state.copyWith(discountAmount: amount));
  }

  openDiscount(MakeOrderDiscountOffset offset) {
    emit(state.copyWith(offsetDiscount: () => offset));
  }

  closeDiscount() {
    emit(state.copyWith(offsetDiscount: () => null));
  }

  changeTableId(String id) {
    emit(state.copyWith(tableId: ()=>id));
  }
  changeNumberDiners(int number) {
    emit(state.copyWith(numberDiners: ()=>number));
  }

  changeTakeAway(bool takeAway){
    emit(state.copyWith(takeAway: takeAway));
  }

  Future<Comanda?> emitOrder(AuthState authState)async{
    try{
      int cajaUsuarioIndex=state.cashRegisters.indexWhere((element) => authState.currentDevice?.caja==element.id && element.abierta==true);
      CashRegister? cashRegister;
      if(cajaUsuarioIndex!=-1){
        cashRegister=state.cashRegisters[cajaUsuarioIndex];
      }
      else{
        cashRegister=state.cashRegisters.firstWhereOrNull((element) => element.abierta==true);
      }
      int tableIndex= state.tables.indexWhere((element) => element.id==state.tableId);
      ConsumptionPoint? table;
      if(tableIndex!=-1){
        table=state.tables[tableIndex];
      }
      List<Item> items=[];
      for(var c in state.itemsSelected){
        items.addAll(c.items);
      }
      NewOrderDto newOrderDto = NewOrderDto(
          caja: cashRegister?.id,
          cantidadComensales: state.numberDiners,
          nombreMesa: table?.nombre,
          descuentos: state.discountAmount,
          emisor: authState.currentContribuyente?.nit??"",
          fecha: DateTime.now(),
          listaItems: items,
          mesa: table?.id??"",
          anulada: true,
          deviceId: authState.currentDevice?.id??0,
          paraLlevar: state.takeAway,
          tipoComanda: AppConstants.restaurantEnv,
          sucursal: authState.currentSucursal?.id??0);
      Comanda comanda;
      if(state.order?.id!=null){
        newOrderDto.id=state.order!.id;
        comanda=await _comandaRepository.editOrder(newOrder: newOrderDto);
        emit(state.copyWith(status: MakeOrderStatus.successEdit));
        emit(state.copyWith(status: MakeOrderStatus.successGet));
      }
      else{
        comanda=await _comandaRepository.emitOrderPre(newOrder: newOrderDto);
        emit(state.copyWith(status: MakeOrderStatus.successEmit));
        emit(state.copyWith(status: MakeOrderStatus.successGet));
      }
      return comanda;
    }
    catch(err){
      log(err.toString());
      emit(state.copyWith(status: MakeOrderStatus.errorEmit,errorDescription: err.toString()));
      emit(state.copyWith(status: MakeOrderStatus.successGet));
      return null;
    }
  }

  resetOrder(){
    emit(state.copyWith(
        numberDiners: ()=>null,
        tableId: ()=>null,
        itemsSelected: [],
        discountAmount: 0,
        itemModal: ()=>null,
        status: MakeOrderStatus.waitingGet,
        indexCategory: 0,

        step: 0)
    );
  }
  printRollo(AuthState authState)async{
    var invoice = await _comandaRepository.getInvoice(1842665);
    var tmp = await PrintTemplate.invoice80(invoice, authState.currentContribuyente!, authState.currentSucursal!);
    var printUtils = PrintUtils();
    await printUtils.print(tmp);
  }


  setItemModal(Item item){
    emit(state.copyWith(itemModal: ()=>item));
  }
  resetItemModal(){
    emit(state.copyWith(itemModal: ()=>null));
  }
  updateItemSelected(Item itemNew, int indexC, indexI) {
    List<CategoryOrder> categories = List.from(state.itemsSelected);
    for (var i = 0; i < state.itemsSelected.length; i++) {
      categories[i] = state.itemsSelected[i].copyWith();
      for (var j = 0; j < categories[i].items.length; j++) {
        if (i == indexC && indexI == j) {
          categories[i].items[j] = itemNew;
        }
        final item = categories[i].items[j];
        num pM = 0;
        for (var m in item.modificadores) {
          for (var c in m.caracteristicas) {
            if (c.check) {
              pM += c.modPrecio * item.cantidad;
            }
          }
        }
        item.precioModificadores = pM;
      }
    }
    emit(state.copyWith(itemsSelected: categories));
  }

}
