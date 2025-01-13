import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/dto/new_sale_link_dto.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/models/sale_link.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
part 'make_order_retail_state.dart';

class MakeOrderRetailBloc extends Cubit<MakeOrderRetailState> {
  final ComandaRepository _comandaRepository;
  final BusinessRepository _businessRepository;
  MakeOrderRetailBloc(this._comandaRepository, this._businessRepository)
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

      List<Item> list = await _comandaRepository.getSaleItems(
        catalog: authState.currentSucursal?.catalogo ?? ""
      );


      List<CashRegister> cashRegisters =
          await _businessRepository.getCashRegisters(
              contribuyenteId: authState.currentContribuyente?.id ?? 0,
              sucursalId: authState.currentSucursal?.id ?? 0);
      var indexCashRegisters =
          cashRegisters.indexWhere((element) => element.abierta == true);
      if (indexCashRegisters == -1) {
        emit(state.copyWith(status: MakeOrderRetailStatus.errorCashRegisters));
        emit(state.copyWith(status: MakeOrderRetailStatus.waitingGet));
        return;
      }

      if (authState.currentDevice?.config.almacen ==null) {
        emit(state.copyWith(status: MakeOrderRetailStatus.errorStore));
        emit(state.copyWith(status: MakeOrderRetailStatus.waitingGet));
        return;
      }

      if (authState.currentDevice?.config.actividadEconomica ==null && authState.currentContribuyente?.habilitadoFacturacion==true) {
        emit(state.copyWith(status: MakeOrderRetailStatus.errorActivity));
        emit(state.copyWith(status: MakeOrderRetailStatus.waitingGet));
        return;
      }
      if (!isClosed) {
        emit(state.copyWith(
            status: MakeOrderRetailStatus.successGet,
            items: list,
            currentCurrency: currentCurrency));
      }
    } catch (e) {
      log(e.toString());

      emit(state.copyWith(status: MakeOrderRetailStatus.errorGet));
      emit(state.copyWith(status: MakeOrderRetailStatus.waitingGet));
    }
  }

  changeStepStatus(int step) {
    emit(state.copyWith(step: step));
  }

  addItem({required String barCode}) {
    var item = state.items.firstWhereOrNull((element) =>
        ((element.codigoBarras?.toLowerCase() == (barCode).toLowerCase())));
    if (item != null) {
      List<Item> list = List.of(state.itemsSelected);
      int? itemSaved =
          list.indexWhere((element) => element.id == item.id);
      if (itemSaved == -1) {
        var itemAdd = item.copyWith();
        itemAdd.cantidad = 1;
        list.add(itemAdd);
      } else {
        var itemAdd =list[itemSaved].copyWith();
        itemAdd.cantidad = itemAdd.cantidad + 1;
        list[itemSaved] = itemAdd;
      }
      emit(state.copyWith(itemsSelected: list));
    }
  }

  resetItems() {
    emit(state.copyWith(itemsSelected: []));
  }

  Future<SaleLink?> emitOrder(AuthState authState) async {
    try {
      var newSaleLinkDto = NewSaleLinkDto(
          monedaId: state.currentCurrency?.id ?? AppConstants.defaultCurrencyId,
          contribuyente: authState.currentContribuyente!.id!,
          sucursal: authState.currentSucursal!.id!,
          actividadEconomica: authState.currentDevice?.config.actividadEconomica,
          almacen: authState.currentDevice!.config.almacen!,
          prefactura: authState.currentContribuyente!.habilitadoFacturacion!=true,
          listaItems: state.itemsSelected,
          moneda: state.currentCurrency?.simbolo == "Bs"? "BOB": state.currentCurrency?.simbolo ?? "",
      );
      SaleLink saleLink = await _comandaRepository.createSaleLink(newSaleLinkDto);
      return saleLink;
    } catch (err) {
      log(err.toString());
      emit(state.copyWith(status: MakeOrderRetailStatus.errorEmit));
      emit(state.copyWith(status: MakeOrderRetailStatus.successGet));
      return null;
    }
  }
}
