import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/data/local/local_storage_credentials.dart';
import 'package:izi_kiosco/data/local/local_storage_first_configuration.dart';
import 'package:izi_kiosco/data/utils/business_utils.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/data/utils/user_utils.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/currency.dart';
import 'package:izi_kiosco/domain/models/login/login_request.dart';
import 'package:izi_kiosco/domain/models/login/login_response.dart';
import 'package:izi_kiosco/domain/models/pos.dart';
import 'package:izi_kiosco/domain/models/user.dart';
import 'dart:developer' as developer;

import 'package:izi_kiosco/domain/repositories/auth_repository.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';

part 'auth_state.dart';

class AuthBloc extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final BusinessRepository _businessRepository;
  AuthBloc(this._authRepository,this._businessRepository) : super(AuthState.init());



  logout() async {
    emit(state.copyWith(status: AuthStatus.init));
    await TokenUtils.deleteToken();
    await Future.delayed(const Duration(seconds: 2));
    if(state.invoiceSubscription!=null){
      state.invoiceSubscription!.cancel();
    }
    emit(state.resetState());
  }

  verify() async {
    try {
      emit(state.copyWith(status: AuthStatus.init));
      await Future.delayed(const Duration(milliseconds: 2000));
      CredentialStorage? credentials = await LocalStorageCredentials.getCredentials();
      User? storageUser = await UserUtils.getUser();
      String? token;
      if(credentials!=null){
        LoginRequest loginRequest = LoginRequest.init();
        loginRequest.correoElectronico=credentials.email;
        loginRequest.contrasena=credentials.password;
        LoginResponse loginResponse=await _authRepository.login(loginRequest);
        token=loginResponse.token;
        await TokenUtils.saveToken(token);
      }
      if (token != null && storageUser != null) {
        User user = await _authRepository.getCurrentUserById(storageUser.id);
          List<Contribuyente> contribuyentes;
          contribuyentes = await _authRepository.getContribuyentes();
          if (contribuyentes.isNotEmpty) {
            int contribuyenteId= (await BusinessUtils.getContribuyenteId())??contribuyentes.first.id??0;
            Contribuyente contribuyente = await _authRepository
                .getCurrentContribuyenteById(contribuyenteId);
            Sucursal? sucursal;
            int? sucursalId= await BusinessUtils.getSucursalId();
            if(sucursalId!=null){
              if(contribuyente.sucursales?.isNotEmpty ?? false){
                int sucIndex = contribuyente.sucursales?.indexWhere((element) => element.id == sucursalId) ?? -1;
                if(sucIndex!=-1){
                  sucursal = contribuyente.sucursales?.elementAtOrNull(sucIndex);
                }
                else{
                  sucursal = contribuyente.sucursales?.firstOrNull;
                }
              }
            }
            else{
                sucursal = contribuyente.sucursales?.firstOrNull;
            }
            if(sucursal!=null){
              await BusinessUtils.saveSucursalId(sucursal.id ?? 0);
            }
            await BusinessUtils.saveContribuyenteId(contribuyente.id ?? 0);

            List<Currency> currencies = await _businessRepository.getCurrencies(
                contribuyenteId:contribuyente.id ?? 0);

            bool firstConfiguration=await LocalStorageFirstConfiguration.getFirstConfiguration() ?? false;
            emit(state.copyWith(
                status: !firstConfiguration? AuthStatus.firstContribuyente:AuthStatus.okAuth,
                contribuyentes: contribuyentes,
                currentUser: user,
                currencies: currencies,
                currentSucursal: sucursal,
                currentContribuyente: contribuyente));
            await LocalStorageFirstConfiguration.saveFirstConfiguration(true);
          } else {
            emit(state.copyWith(
                status: AuthStatus.noAuth, currentUser: user));
          }
      } else {
        await TokenUtils.deleteToken();
        await UserUtils.deleteUser();
        await LocalStorageCredentials.deleteCredentials();
        emit(state.copyWith(status: AuthStatus.noAuth));
      }
    } catch (error) {
      developer.log(error.toString());
      await TokenUtils.deleteToken();
      await UserUtils.deleteUser();
      await LocalStorageCredentials.deleteCredentials();
      emit(state.copyWith(status: AuthStatus.noAuth));
    }
  }

  updateData({User? user, Contribuyente? contribuyente,Sucursal? sucursal}) {
    try {
      emit(state.copyWith(
          currentUser: user, currentContribuyente: contribuyente,currentSucursal: sucursal));
    } catch (e) {
      developer.log(e.toString());
      //emit(state.copyWith(status: AuthStatus.noAuth));
    }
  }
  updateSucursal(Sucursal updateSucursal)async{
    await BusinessUtils.saveSucursalId(updateSucursal.id ?? 0);

    if(state.invoiceSubscription!=null){
      state.invoiceSubscription!.cancel();
    }
    emit(state.copyWith(
        currentSucursal: updateSucursal));
  }
  updateContribuyente(Contribuyente contribuyenteUpdate,int index)async{
    emit(state.copyWith(loadingContribuyente: true,status: AuthStatus.waitingChange));
    Contribuyente contribuyente = await _authRepository
        .getCurrentContribuyenteById(contribuyenteUpdate.id??0);
    var sucursal = contribuyente.sucursales?.firstOrNull;
    if(sucursal!=null){
      await BusinessUtils.saveSucursalId(sucursal.id ?? 0);
    }
    await BusinessUtils.saveContribuyenteId(contribuyente.id ?? 0);

    if(state.invoiceSubscription!=null){
      state.invoiceSubscription!.cancel();
    }

    emit(state.copyWith(
      loadingContribuyente: false,
      status: AuthStatus.firstContribuyente,
        currentSucursal: sucursal,
        currentContribuyente: contribuyente));
  }

  updatePos(Pos? pos){
    emit(state.copyWith(currentPos: pos));
  }
}
