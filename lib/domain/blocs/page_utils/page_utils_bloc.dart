import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
part 'page_utils_state.dart';


class PageUtilsBloc extends Cubit<PageUtilsState>{

  Timer? timer;


  PageUtilsBloc():super(PageUtilsState.defaultState());


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
    emit(state.copyWith(screenActive: true));
  }
  updateScreenActive(){
    if(timer!=null){
      timer!.cancel();
    }
    emit(state.copyWith(screenActive: true));
    timer = Timer(Duration(seconds: AppConstants.timerTimeSeconds), () {
      emit(state.copyWith(screenActive: false));
    });
  }
  initScreenActive(){
    timer ??= Timer(Duration(seconds: AppConstants.timerTimeSeconds), () {
        emit(state.copyWith(screenActive: false));
      });
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
}