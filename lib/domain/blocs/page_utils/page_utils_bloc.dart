import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
part 'page_utils_state.dart';


class PageUtilsBloc extends Cubit<PageUtilsState>{

  Timer? timer;


  Timer? timerHelp;
  final BusinessRepository _businessRepository;


  PageUtilsBloc(this._businessRepository):super(PageUtilsState.defaultState());


  void showSnackBar({required SnackBarInfo snackBar}){
    state.timer.cancel();
    emit(
        state.showSnackBar(
            snackBar: snackBar,
            timer: Timer(const Duration(seconds:10), (){
              emit(state.hideSnackBar());
            }
            )
        )
    );
  }
  closeScreenActive(){
    if(timer!=null){
      timer!.cancel();

    }
    timer=null;
    emit(state.copyWith(screenActive: true));
  }

  var seconds = AppConstants.timerTimeSeconds;
  updateScreenActive(){
    if(timer!=null) {
      timer!.cancel();
      emit(state.copyWith(screenActive: true));
      timer = Timer(Duration(seconds: seconds), () {
        emit(state.copyWith(screenActive: false));
      });
    }
  }
  initScreenActiveInvoiced(AuthState authState){
    if(timer!=null){
      timer!.cancel();
    }
    emit(state.copyWith(screenActive: true));
    seconds = authState.currentDevice?.config.timePayment?? AppConstants.timerTimeSecondsInvoiced;
    timer = Timer(Duration(seconds: seconds), () {
      emit(state.copyWith(screenActive: false));
    });
  }
  initScreenActive(AuthState authState){
    try{

      if(timer!=null){
        timer!.cancel();
      }
      seconds = authState.currentDevice?.config.timeOrder??AppConstants.timerTimeSeconds;
      emit(state.copyWith(screenActive: true));
      timer = Timer(Duration(seconds: AppConstants.timerTimeSeconds), () {
        emit(state.copyWith(screenActive: false));
      });
    }
    catch(err){
      log(err.toString());
    }
  }

  void hideSnackBar()async{
    state.timer.cancel();
    emit(state.hideSnackBar());
  }
  changeLocation({required String? location}){
    emit(state.copyWith(currentLocation: location));
  }
  lockPage(){
    emit(state.copyWith(lock: true));
  }
  unlockPage(){
    emit(state.copyWith(lock: false));
  }

  showLoading(String title){
    emit(state.copyWith(titleLoading: ()=>title));
  }
  closeLoading(){
    emit(state.copyWith(titleLoading: ()=>null));
  }

  void changeSubmenuStatus({
    bool? configuration
}){
    emit(state.copyWith(configurationMenuOpen: configuration));
  }
  askHelp(AuthState authState){
    try{
      _businessRepository.askHelp(authState.currentSucursal?.id??0,authState.currentDevice?.nombre??"");
      if(timerHelp!=null){
        timerHelp!.cancel();
      }
      emit(state.copyWith(helpActive: false,dateHelp: ()=>DateTime.now()));
      timerHelp = Timer(Duration(seconds: AppConstants.timerHelp), () {
        emit(state.copyWith(helpActive: true,dateHelp: ()=>null));
      });
    }
    catch(_){}
  }
}