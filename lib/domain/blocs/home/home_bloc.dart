import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/utils/crash_report.dart';
part 'home_state.dart';


class HomeBloc extends Cubit<HomeState>{
  final BusinessRepository _businessRepository;

  Stream? futureVerifyPos;
  StreamSubscription? _subscription;

  HomeBloc(this._businessRepository):super(HomeState.init());

  verifyServerPos(AuthState authState)async{
    final savedIzifyPosIp = await TokenUtils.getPosIp();
    if (savedIzifyPosIp != null && savedIzifyPosIp.isNotEmpty) {
      emit(state.copyWith(statusServer: true, statusServerPos: true));
      return;
    }

    if(authState.currentDevice?.config.ipLinkser!=null || authState.currentDevice?.config.ipAtc!=null){


      await _verify();
      futureVerifyPos = Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
        await _verify();
      });

      _subscription = futureVerifyPos!.listen((_) {
        if(isClosed){
          _subscription?.cancel();
        }
      });


    }

  }
  _verify()async{
    try {
      final isConnected = await _businessRepository.verifyConnectionPos();
      if(isClosed){
        _subscription?.cancel();
        return;
      }
      if(!isConnected){
        CrashReport.report("Error connection POS", "POS not connected");
      }
      emit(state.copyWith(statusServer: true,statusServerPos: isConnected));
    } catch (e) {
      if(isClosed){
        _subscription?.cancel();
        return;
      }
      CrashReport.report("Error connection Server POS", "Server POS is not init");
      emit(state.copyWith(statusServer: false,statusServerPos: true));
    }
  }
}