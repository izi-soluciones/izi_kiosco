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
  MakeOrderBloc(this._comandaRepository,this._businessRepository)
      : super(MakeOrderState.init());

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
        sucursal: 0,
          contribuyente: authState.currentContribuyente?.id ?? 0);
      list.sort(
            (a, b) => a.nombre.compareTo(b.nombre),
      );

      List<Item> listItems = await _comandaRepository.getSaleItems(catalog: authState.currentSucursal?.catalogo??"");


      listItems.sort(
            (a, b){
              var splitA = a.codigoBarras?.split("-");
              var splitB = b.codigoBarras?.split("-");
              var valA = int.tryParse(splitA?.firstOrNull??"") ?? 10000000;
              var valB = int.tryParse(splitB?.firstOrNull??"") ?? 10000000;
              return valA.compareTo(valB);
            },
      );
      for (var cat in list) {
        List<Item> itemsCat = [];
        for (var i in listItems) {
          if (i.categoriaId == cat.id && i.categoriaId != null) {
            i.categoria = cat.nombre;
            itemsCat.add(i);
          }
        }
        cat.items = itemsCat;
      }
      list.removeWhere((element) => element.items.isEmpty);
      List<Item> itemsFeatured=[];
      itemsFeatured=listItems.where((element) => element.customItem is Map && element.customItem?["kiosco"]?["destacado"]==true).toList();
      itemsFeatured.sort(
            (a, b){
          var splitA = a.codigoBarras?.split("-");
          var splitB = b.codigoBarras?.split("-");
          var valA = int.tryParse(splitA?.lastOrNull??"") ?? 10000000;
          var valB = int.tryParse(splitB?.lastOrNull??"") ?? 10000000;
          return valA.compareTo(valB);
        },
      );
      list.sort(
        (a, b) {
          return a.nombre.toLowerCase().compareTo(b .nombre.toLowerCase());
        },
      );
      list.sort((a,b)=>a.prioridad?.compareTo(b.prioridad??1000)??1000);
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

  removeItem(int indexItem) {
    List<Item> categories = List.from(state.itemsSelected);
    categories.removeAt(indexItem);
    emit(state.copyWith(itemsSelected: categories));
  }
  reloadItems() {
    List<Item> categories = [];
    for (var i = 0; i < state.itemsSelected.length; i++) {
      var item = state.itemsSelected[i].copyWith();
      num pM = 0;
      for (var m in item.modificadores) {
        for (var c in m.caracteristicas) {
          if (c.check) {
            pM += c.modPrecio * item.cantidad;
          }
        }
      }
      item.precioModificadores = pM;
      categories.add(item);
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
    List<Item> categories = List.from(state.itemsSelected);
    int? indexItem;
    for (var iOld = 0; iOld < categories.length; iOld++) {
      if (categories[iOld].id != item.id) {
        continue;
      }
      var same = true;
      for (int i = 0; i < item.modificadores.length; i++) {
        for (int m = 0;
        m < item.modificadores[i].caracteristicas.length;
        m++) {
          if (item.modificadores[i].caracteristicas[m].check !=
              categories[iOld]
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
      item.cantidad = categories[indexItem].cantidad + 1;
      num pM = 0;
      for (var m in item.modificadores) {
        for (var c in m.caracteristicas) {
          if(c.check){
            pM += c.modPrecio * item.cantidad;
          }
        }
      }
      item.precioModificadores = pM;
      categories[indexItem] = item;
    } else {
      categories.add(item);
    }
    emit(state.copyWith(itemsSelected: categories));
  }

  resetItems(){
    List<Item> categories = [];
    emit(state.copyWith(itemsSelected: categories,indexCategory: 0));
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
      List<Item> items=state.itemsSelected;
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
    emit(state.copyWith(numberDiners: ()=>null,tableId: ()=>null,itemsSelected: [],discountAmount: 0));
  }

  initOrder(){
    emit(MakeOrderState.init());
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
  updateItemSelected(Item itemNew, indexI) {
    List<Item> categories = List.from(state.itemsSelected);

    for (var i = 0; i < state.itemsSelected.length; i++) {
      var same = true;
      if(categories[i].id==itemNew.id){
        for (int j = 0; j < itemNew.modificadores.length; j++) {
          for (int m = 0;
          m < itemNew.modificadores[j].caracteristicas.length;
          m++) {
            if (itemNew.modificadores[j].caracteristicas[m].check !=
                categories[i]
                    .modificadores[j]
                    .caracteristicas[m]
                    .check) {
              same = false;
              break;
            }
          }
        }
      }
      if (same && i!=indexI && categories[i].id==itemNew.id) {
        var item = categories[i];
        item.cantidad = categories[i].cantidad + itemNew.cantidad;
        num pM = 0;
        for (var m in item.modificadores) {
          for (var c in m.caracteristicas) {
            if (c.check) {
              pM += c.modPrecio * item.cantidad;
            }
          }
        }
        item.precioModificadores = pM;
        categories[i] = item;
        categories.removeAt(indexI);
        break;
      }
      categories[i] = state.itemsSelected[i];
      if (i == indexI) {
        categories[i] = itemNew;
      }
      final item = categories[i];
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
    emit(state.copyWith(itemsSelected: categories));
  }

}
