import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/new_order_dto.dart';
import 'package:izi_kiosco/domain/dto/new_sale_link_dto.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/catalog.dart';
import 'package:izi_kiosco/domain/models/category_order.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/models/sale_link.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy.dart';
import 'package:izi_kiosco/domain/utils/crash_report.dart';
part 'make_order_state.dart';

class MakeOrderBloc extends Cubit<MakeOrderState> {
  final ComandaRepository _comandaRepository;
  final BusinessRepository _businessRepository;
  MakeOrderBloc(this._comandaRepository,this._businessRepository, {String? tableId, int? numberDiners})
      : super(MakeOrderState.init(tableId, numberDiners));

  TaxesStrategy? taxesStrategy;
  init(AuthState authState, bool takeAway) async {
    try {
      taxesStrategy = authState.taxesStrategy;
      int indexCurrency = authState.currencies.indexWhere((element) =>
          element.id ==
          authState.currentContribuyente?.config["monedaInventario"]);
      Currency? currentCurrency;
      if (indexCurrency != -1) {
        currentCurrency = authState.currencies.elementAtOrNull(indexCurrency);
      }
      List<CategoryOrder> list =[];
      List<Item> itemsFeatured=[];
      Catalog? catalog = authState.catalog;
      if(authState.currentDevice?.catalogo!=null){
        catalog = await _businessRepository.getCatalog(id: authState.currentDevice!.catalogo!);
        Set<String> itemsIdsSet = {};
        for(var c in catalog.categories){
          itemsIdsSet.addAll(c.items);
        }
        List<String> itemsIds = itemsIdsSet.toList();
        int size=100;
        int lastIndex=0;
        List<Item> listItems =[];
        while(true){
          var end =lastIndex+size;
          if(end>itemsIds.length){
            end = itemsIds.length;
          }
          var idsSplit = itemsIds.sublist(lastIndex,end);
          lastIndex = end;
          if(idsSplit.isEmpty){
            break;
          }
          var items = await _comandaRepository.getSaleItems(items: idsSplit,sortByPriority: false);
          listItems.addAll(items);
        }
        for(var c in catalog.categories){
          List<Item> items = listItems
              .where((obj) => c.items.contains(obj.id))
              .toList();
          items.sort((a, b) => c.items.indexOf(a.id).compareTo(c.items.indexOf(b.id)));
          list.add(CategoryOrder(nombre: c.category?.nombre ?? "",items: items));
        }


      }
      else{
        
        list = await _comandaRepository.getCategories(
        sucursal: 0,
          contribuyente: authState.currentContribuyente?.id ?? 0);
      list.sort(
            (a, b) => a.nombre.compareTo(b.nombre),
      );

      List<Item> listItems = await _comandaRepository.getSaleItems(catalog: authState.currentSucursal?.catalogo??"",sortByPriority: authState.currentDevice?.config.sortByPriority==true);

      listItems.removeWhere((element) {
        return (takeAway && element.kioscoOcultarLlevar) || (!takeAway && element.kioscoOcultarAqui);
      });
      Map<String, CategoryOrder> categoryMap = {};
      for (var item in listItems) {
        item.cantidad = 1;
        _setItemPrice(item, 0);

        String targetCategoryId;
        String targetCategoryName;

        if (item.subCategoria != null && item.subCategoria!.isNotEmpty) {
          targetCategoryId = item.subCategoria!;
          targetCategoryName = item.subCategoria!;
        } else if (item.categoriaId != null) {
          targetCategoryId = item.categoriaId!;
          targetCategoryName = item.categoria ?? "";
        } else {
          continue;
        }

        if (!categoryMap.containsKey(targetCategoryId)) {
          categoryMap[targetCategoryId] = CategoryOrder(
            id: targetCategoryId,
            nombre: targetCategoryName,
            items: [],
          );
        }
        item.categoria = targetCategoryName;
        item.categoriaId = targetCategoryId;
        categoryMap[targetCategoryId]!.items.add(item);
      }

      list = categoryMap.values.toList();
      list.removeWhere((element) => element.items.isEmpty);
      list.sort(
            (a, b) => a.nombre.compareTo(b.nombre),
      );

      itemsFeatured=listItems.where((element) => element.customItem is Map && element.customItem?["kiosco"]?["destacado"]==true).toList();
      list.sort(
            (a, b) {
          return a.nombre.toLowerCase().compareTo(b .nombre.toLowerCase());
        },
      );
      if(itemsFeatured.isNotEmpty){
        list.insert(0, CategoryOrder(nombre: "", items: itemsFeatured));
      }
      }
      String? priceList = catalog?.listaPrecio;
      if (priceList != null) {
        for(var c in list){
          for(var item in c.items){
            PrecioVenta? aux = item.preciosVenta.firstWhereOrNull((element) {
              return
                element.listaPrecio == priceList;
            });
            if (aux != null) {
              item.precioUnitario = aux.precio;
            }
          }
        }
      }
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
            takeAway: takeAway,
            itemsFeatured: itemsFeatured,
            cashRegisters: cashRegisters,
            currentCurrency: currentCurrency));
      }
    } catch (e) {

      CrashReport.report("Error make order init", e.toString());
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
    num modPriceUnit = 0;
    for (var m in item.modificadores) {
      for (var c in m.caracteristicas) {
        if (c.check) {
          modPriceUnit += c.modPrecio;
        }
      }
    }
    item.precioModificadores = modPriceUnit*item.cantidad;
    item.precioModUnitario = modPriceUnit;
    _setItemPrice(item, modPriceUnit);
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
        item.precioModificadores = modPriceUnit*item.cantidad;
        item.precioModUnitario = modPriceUnit;
        
        _setItemPrice(item, modPriceUnit);
        categories[indexCat].items[indexItem] = item;
      } else {
        categories[indexCat].items.add(item);
      }
    }
    emit(state.copyWith(itemsSelected: categories));
  }


  _setItemPrice(Item item, num modPrice){
      item.taxPrice = item.cantidad*(item.precioUnitario+modPrice);
      if(item.parametrosFacturacion!=null){
        item.taxPrice = taxesStrategy?.getTotalItem(item.parametrosFacturacion!, item.cantidad, item.precioUnitario+modPrice) ?? item.taxPrice;
      }
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
        num modPriceUnit = 0;
        for (var m in item.modificadores) {
          for (var c in m.caracteristicas) {
            if (c.check) {
              modPriceUnit += c.modPrecio;
            }
          }
        }
        item.precioModificadores = modPriceUnit*item.cantidad;
        item.precioModUnitario = modPriceUnit;
        _setItemPrice(item,modPriceUnit);
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

  Future<PaymentObj?> emitOrder(AuthState authState)async{
    if(authState.currentDevice?.config.isRetail==true){
      return await _emitSale(authState);
    }
    else{
      return await _emitOrder(authState);
    }
  }

  Future<PaymentObj?> _emitOrder(AuthState authState)async{
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
      var paymentObj = PaymentObj(
              id: comanda.id,
              uuid: comanda.uuid,
              custom: comanda.custom is Map? comanda.custom : {},
              amount: comanda.montoTotal??0,
              isComanda: true,
              items: comanda.listaItems.map((e) => ItemPaymentObj(
                  quantity: e.cantidad ?? 0,
                  custom: e.modificadores,
                  name: e.nombre)
              ).toList()
          );
      return paymentObj;
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
  // printRollo(AuthState authState)async{
  //   var invoice = await _comandaRepository.getInvoice(1842665);
  //   var tmp = await PrintTemplate.invoice80(invoice, authState.currentContribuyente!, authState.currentSucursal!);
  //   var printUtils = PrintUtils();
  //   await printUtils.print(tmp);
  // }


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
        num modPriceUnit = 0;
        for (var m in item.modificadores) {
          for (var c in m.caracteristicas) {
            if (c.check) {
              modPriceUnit += c.modPrecio;
            }
          }
        }
        item.precioModificadores = modPriceUnit*item.cantidad;
        item.precioModUnitario= modPriceUnit;
        _setItemPrice(item,modPriceUnit);
      }
    }
    emit(state.copyWith(itemsSelected: categories));
  }

  Future<PaymentObj?> _emitSale(AuthState authState) async {
    try{
      List<Item> itemsSelected = [];
      for(var cat in state.itemsSelected){
        itemsSelected.addAll(cat.items);
      }
      var newSaleLinkDto = NewSaleLinkDto(
          listaItems: itemsSelected,
          dispositivo: authState.currentDevice?.id ?? 0
      );
      SaleLink saleLink = await _comandaRepository.createSaleLink(newSaleLinkDto);
      var paymentObj = PaymentObj(
              id: saleLink.id,
              uuid: saleLink.uuid,
              custom: {},
              amount: saleLink.monto,
              isComanda: false,
              items: itemsSelected.map((e) => ItemPaymentObj(
                  quantity: e.cantidad,
                  custom: {},
                  name: e.nombre)
              ).toList()
          );
      
      return paymentObj;
    }
    catch(err){
      log(err.toString());
      emit(state.copyWith(status: MakeOrderStatus.errorEmit,errorDescription: err.toString()));
      emit(state.copyWith(status: MakeOrderStatus.successGet));
      return null;
    }
  }

}
