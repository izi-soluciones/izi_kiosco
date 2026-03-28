import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/data/local/local_storage_credentials.dart';
import 'package:izi_kiosco/data/local/local_storage_first_configuration.dart';
import 'package:izi_kiosco/data/utils/business_utils.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/data/utils/user_utils.dart';
import 'package:izi_kiosco/domain/models/catalog.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/pos.dart';
import 'package:izi_kiosco/domain/models/user.dart';
import 'package:collection/collection.dart';
import 'dart:developer' as developer;

import 'package:izi_kiosco/domain/repositories/auth_repository.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/strategies/taxes/impl/taxes_strategy_default.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy_factory.dart';
import 'package:izi_kiosco/domain/utils/download_utils.dart';
import 'package:izi_kiosco/domain/utils/print_utils.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

part 'auth_state.dart';

class AuthBloc extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final BusinessRepository _businessRepository;
  AuthBloc(this._authRepository, this._businessRepository)
      : super(AuthState.init());

  logout() async {
    emit(state.copyWith(status: AuthStatus.init));
    try{
      if(state.currentDevice!=null){
        await _authRepository.disableDevice(state.currentDevice!.id);
      }
    }
    catch(_){}
    await TokenUtils.deleteToken();
    await BusinessUtils.deleteContribuyenteId();
    await BusinessUtils.deleteSucursalId();
    await Future.delayed(const Duration(seconds: 2));
    if (state.invoiceSubscription != null) {
      state.invoiceSubscription!.cancel();
    }
    emit(state.resetState());
  }

  Future<void> verify() async {
    try {
      PrintUtils().printTest();
      
      String? token = Uri.base.queryParameters["token"] ?? await TokenUtils.getToken();
      String? tokenCard = Uri.base.queryParameters["tokenCard"] ?? await TokenUtils.getTokenCard();
      if (token == null) {
        await TokenUtils.deleteToken();
        await UserUtils.deleteUser();
        await BusinessUtils.deleteContribuyenteId();
        await BusinessUtils.deleteSucursalId();
        await LocalStorageCredentials.deleteCredentials();
        return emit(state.copyWith(status: AuthStatus.noAuth));
      }
      await TokenUtils.saveToken(token);
      if(tokenCard!=null && tokenCard.trim().isNotEmpty){
        await TokenUtils.saveTokenCard(tokenCard);
      }
      emit(state.copyWith(status: AuthStatus.init));
      
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      int? contribuyenteId = decodedToken["contribuyente"] is int?decodedToken["contribuyente"]:int.tryParse(decodedToken["contribuyente"]);
      if (contribuyenteId == null) {
        await TokenUtils.deleteToken();
        await UserUtils.deleteUser();
        await BusinessUtils.deleteContribuyenteId();
        await BusinessUtils.deleteSucursalId();
        await LocalStorageCredentials.deleteCredentials();
        return emit(state.copyWith(status: AuthStatus.noAuth));
      }
      await Future.delayed(const Duration(milliseconds: 2000));

        Device device = await _authRepository.getDevice();

        Contribuyente contribuyente = await _authRepository
            .getCurrentContribuyenteById(contribuyenteId);

        TaxesStrategy taxesStrategy = TaxesStrategyFactory.taxes(contribuyente);
        List<Sucursal> sucursales = await _authRepository.getSucursales(contribuyenteId);
        contribuyente.sucursales = sucursales;
        Sucursal? sucursal;
        int sucursalId = device.sucursal;
        await BusinessUtils.saveSucursalId(sucursalId ?? 0);
        if (contribuyente.sucursales?.isNotEmpty ?? false) {
          int sucIndex = contribuyente.sucursales
                  ?.indexWhere((element) => element.id == sucursalId) ??
              -1;
          if (sucIndex != -1) {
            sucursal = contribuyente.sucursales?.elementAtOrNull(sucIndex);
          } else {
            sucursal = contribuyente.sucursales?.firstOrNull;
          }
        }
        await BusinessUtils.saveContribuyenteId(contribuyente.id ?? 0);
        File? video;

        Catalog? catalog;
          if(sucursal?.catalogo!=null){
            catalog = await _businessRepository.getCatalog(id: sucursal!.catalogo!);
          }

        try{
          if(device.config.video !=null){
            video = await DownloadUtils().downloadFile(device.config.video!);
          }
        }
        catch(e){developer.log(e.toString());}

        device.sucursalName = contribuyente.sucursales
              ?.firstWhereOrNull((element) => element.id == device.sucursal)
              ?.nombre;

        List<Currency> currencies = await _businessRepository.getCurrencies(
            contribuyenteId: contribuyente.id ?? 0);


        emit(state.copyWith(
            status: AuthStatus.okAuth,
            currencies: currencies,
            currentDevice: device,
            taxesStrategy: taxesStrategy,
            catalog: catalog,
            currentSucursal: sucursal,
            video: video,
            currentContribuyente: contribuyente));
        await LocalStorageFirstConfiguration.saveFirstConfiguration(true);
      
    } catch (error) {

      CredentialStorage? credentials;
      try{
        credentials = await LocalStorageCredentials.getCredentials();
      }
      catch(_){}
      if (credentials != null){
        emit(state.copyWith(status: AuthStatus.errorAuth));
      }
      else{
        developer.log(error.toString());
        await TokenUtils.deleteToken();
        await UserUtils.deleteUser();
        await BusinessUtils.deleteContribuyenteId();
        await BusinessUtils.deleteSucursalId();
        await LocalStorageCredentials.deleteCredentials();
        emit(state.copyWith(status: AuthStatus.noAuth));
      }
    }
  }

  updateData({User? user, Contribuyente? contribuyente, Sucursal? sucursal}) {
    try {
      emit(state.copyWith(
          currentUser: user,
          currentContribuyente: contribuyente,
          currentSucursal: sucursal));
    } catch (e) {
      developer.log(e.toString());
      //emit(state.copyWith(status: AuthStatus.noAuth));
    }
  }


  updateSucursal(Sucursal updateSucursal) async {
    await BusinessUtils.saveSucursalId(updateSucursal.id ?? 0);

    if (state.invoiceSubscription != null) {
      state.invoiceSubscription!.cancel();
    }
    emit(state.copyWith(currentSucursal: updateSucursal));
  }

  updateContribuyente(Contribuyente contribuyenteUpdate, int index) async {
    emit(state.copyWith(
        loadingContribuyente: true, status: AuthStatus.waitingChange));
    Contribuyente contribuyente = await _authRepository
        .getCurrentContribuyenteById(contribuyenteUpdate.id ?? 0);
    List<Sucursal> sucursales = await _authRepository.getSucursales(contribuyenteUpdate.id ?? 0);
    contribuyente.sucursales = sucursales;
    List<Device> devices = await _authRepository
        .getDevicesByContribuyente(contribuyenteUpdate.id ?? 0);
    for (var d in devices) {
      d.sucursalName = contribuyente.sucursales
          ?.firstWhereOrNull((element) => element.id == d.sucursal)
          ?.nombre;
    }
    await BusinessUtils.saveContribuyenteId(contribuyente.id ?? 0);

    if (state.invoiceSubscription != null) {
      state.invoiceSubscription!.cancel();
    }


    TaxesStrategy taxesStrategy = TaxesStrategyFactory.taxes(contribuyente);

    emit(state.copyWith(
        loadingContribuyente: false,
        status: AuthStatus.firstContribuyente,
        currentContribuyente: contribuyente));
  }

  updatePos(Pos? pos) {
    emit(state.copyWith(currentPos: pos));
  }

  Future<void> enableDevice(Device device) async {

    emit(state.copyWith(status: AuthStatus.init));
    await _authRepository.enableDevice(device.id);

    if (state.invoiceSubscription != null) {
      state.invoiceSubscription!.cancel();
    }
    Sucursal? updateSucursal = state.currentContribuyente?.sucursales
        ?.firstWhereOrNull((element) => element.id == device.sucursal);
    await BusinessUtils.saveSucursalId(updateSucursal?.id ?? 0);
    await BusinessUtils.saveDeviceId(device.id);
    emit(state.copyWith(
        currentDevice: device,
        currentSucursal: updateSucursal));
    await verify();
  }
}