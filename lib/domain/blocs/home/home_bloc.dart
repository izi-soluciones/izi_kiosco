import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/utils/crash_report.dart';
part 'home_state.dart';


class HomeBloc extends Cubit<HomeState>{
  final BusinessRepository _businessRepository;

  Stream? futureVerifyPos;
  StreamSubscription? _subscription;

  final IzifyPosClient _izifyPosClient;

  HomeBloc(this._businessRepository, {IzifyPosClient? izifyPosClient})
      : _izifyPosClient = izifyPosClient ?? IzifyPosClient(),
        super(HomeState.init());

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  verifyServerPos(AuthState authState)async{
    final izifyAddress = IzifyPosAddress.tryParse(await TokenUtils.getPosIp()) ??
        IzifyPosAddress.tryParse(authState.currentDevice?.config.ipEcopay);
    if (izifyAddress != null) {
      // EcoPay terminal: this used to report OK without asking it. Ask, so
      // the home screen warns before a customer reaches the card payment.
      await _verifyIzify(izifyAddress);
      _subscription?.cancel();
      _subscription = Stream.periodic(const Duration(seconds: 30))
          .asyncMap((_) => _verifyIzify(izifyAddress))
          .listen((_) {
        if (isClosed) _subscription?.cancel();
      });
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
  Future<void> _verifyIzify(IzifyPosAddress address) async {
    bool ready;
    try {
      final health = await _izifyPosClient.health(address);
      ready = health.notReadyReason == null;
    } catch (_) {
      ready = false;
    }
    if (isClosed) {
      _subscription?.cancel();
      return;
    }
    if (!ready) {
      CrashReport.report("Error connection POS", "Izify POS not ready at $address");
    }
    emit(state.copyWith(statusServer: true, statusServerPos: ready));
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