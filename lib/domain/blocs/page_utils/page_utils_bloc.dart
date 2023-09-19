import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
part 'page_utils_state.dart';


class PageUtilsBloc extends Cubit<PageUtilsState>{


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