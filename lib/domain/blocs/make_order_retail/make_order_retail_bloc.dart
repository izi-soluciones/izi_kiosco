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
import 'package:izi_kiosco/domain/models/modulos.dart';
import 'package:izi_kiosco/domain/models/sale_link.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/domain/models/campos_extra.dart';
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
        catalog: authState.currentSucursal?.catalogo ?? "", sortByPriority: false
      );

      String? priceList = authState.catalog?.listaPrecio;
      if (priceList != null) {
        for (var item in list) {
          PrecioVenta? aux = item.preciosVenta.firstWhereOrNull((element) {
            return element.listaPrecio == priceList;
          });
          if (aux != null) {
            item.precioUnitario = aux.precio;
          }
        }
      }


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

      if (authState.currentDevice?.config.actividadEconomica ==null && authState.currentContribuyente?.tieneModulo(Modulo.facturacion)==true) {
        emit(state.copyWith(status: MakeOrderRetailStatus.errorActivity));
        emit(state.copyWith(status: MakeOrderRetailStatus.waitingGet));
        return;
      }
      if (!isClosed) {
        List<CamposExtra> camposExtra = authState.camposExtraDispositivos
            .map((e) => e.copyWith())
            .toList();
        emit(state.copyWith(
            status: MakeOrderRetailStatus.successGet,
            items: list,
            currentCurrency: currentCurrency,
            camposExtra: camposExtra));
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

  Item? addItem({required String barCode}) {
    final cleaned = barCode.trim().toLowerCase();
    if (cleaned.isEmpty) return null;
    var item = state.items.firstWhereOrNull((element) =>
        ((element.codigoBarras?.trim().toLowerCase() == cleaned)));
    if (item != null) {
      List<Item> list = List.of(state.itemsSelected);
      int? itemSaved =
          list.indexWhere((element) => element.id == item.id);
      if (itemSaved == -1) {
        var itemAdd = item.copyWith();
        itemAdd.cantidad = 1;
        list.insert(0, itemAdd);
      } else {
        var itemAdd = list[itemSaved].copyWith();
        itemAdd.cantidad = itemAdd.cantidad + 1;
        list[itemSaved] = itemAdd;
      }
      emit(state.copyWith(itemsSelected: list));
      return item;
    }
    return null;
  }

  resetItems() {
    emit(state.copyWith(itemsSelected: []));
  }

  Future<SaleLink?> emitOrder(AuthState authState) async {
    try {
      var newSaleLinkDto = NewSaleLinkDto(
          listaItems: state.itemsSelected,
          dispositivo: authState.currentDevice?.id ?? 0,
          camposExtra: state.camposExtra,
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

  removeItem(Item item){
    List<Item> list = List.of(state.itemsSelected);
    list.removeWhere((element) => element.id == item.id);
    emit(state.copyWith(itemsSelected: list));
  }

  void updateCampoExtra(int id, String? value) {
    final updated = state.camposExtra.map((c) {
      if (c.id == id) {
        return c.copyWith(valor: () => value);
      }
      return c;
    }).toList();
    emit(state.copyWith(camposExtra: updated));
  }

  String? validateCamposExtra() {
    for (var c in state.camposExtra) {
      if (c.tipoCampo == 'fijo') continue;
      final val = c.valor?.trim() ?? "";
      if (c.isObligatorio && val.isEmpty) {
        return 'El campo "${c.nombre}" es obligatorio';
      }
      if (val.isNotEmpty && c.tipoCampo == 'number') {
        final numVal = num.tryParse(val);
        if (numVal == null) {
          return 'El campo "${c.nombre}" debe ser un número válido';
        }
      }
      if (val.isNotEmpty && c.tipoCampo == 'select' && c.values != null && c.values!.isNotEmpty) {
        if (!c.values!.contains(val)) {
          return 'Seleccione una opción válida para "${c.nombre}"';
        }
      }
    }
    return null;
  }

  bool hasMissingRequiredCamposExtra() {
    for (var c in state.camposExtra) {
      if (c.tipoCampo == 'fijo') continue;
      final val = c.valor?.trim() ?? "";
      if (c.isObligatorio && val.isEmpty) {
        return true;
      }
    }
    return false;
  }
}
