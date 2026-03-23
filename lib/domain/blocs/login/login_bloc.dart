import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izi_kiosco/data/local/local_storage_credentials.dart';
import 'package:izi_kiosco/data/utils/business_utils.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/data/utils/user_utils.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/login/login_request.dart';
import 'package:izi_kiosco/domain/models/login/login_response.dart';
import 'package:izi_kiosco/domain/repositories/auth_repository.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';

part 'login_state.dart';
part 'login_inputs.dart';

class LoginBloc extends Cubit<LoginState>{
  final AuthRepository _authRepository;
  StreamSubscription? _pollingSubscription;

  LoginBloc(this._authRepository):super(LoginState.init()){
    generateQrSession();
  }

  generateQrSession() async {
    try {
      emit(state.copyWith(status: LoginStatus.waitingLogin));
      String sessionId = await _authRepository.createKioskSession();
      String baseUrl = dotenv.env['ADMIN_URL'] ?? 'https://app.izi.bo'; 
      String url = "$baseUrl/#/kiosco-login?session_id=$sessionId";
      debugPrint("QR URL: $url");
      emit(state.copyWith(qrUrl: url, sessionId: sessionId, status: LoginStatus.init));
      _startPolling(sessionId);
    } catch(e) {
      debugPrint(e.toString());
      emit(state.copyWith(status: LoginStatus.errorLogin));
      emit(state.copyWith(status: LoginStatus.init));
    }
  }

  _startPolling(String sessionId) {
    _pollingSubscription?.cancel();
    _pollingSubscription = Stream.periodic(const Duration(seconds: 3)).listen((_) async {
      try {
        var res = await _authRepository.pollKioskSession(sessionId);
        if (res["status"] == "authorized") {
           _pollingSubscription?.cancel();
           await TokenUtils.saveToken(res["accessToken"]);
           await TokenUtils.saveTokenCard(res["tarjetaToken"]);
           await _authRepository.getDevice();
           emit(state.copyWith(status: LoginStatus.successLogin));
        }
      } catch(e) {
        debugPrint(e.toString());
      }
    });
  }

  @override
  Future<void> close() {
    _pollingSubscription?.cancel();
    return super.close();
  }

  login()async{
    try{
      if(_validateInputs()){
        await TokenUtils.saveToken(state.token.value);
        if(state.tokenCard.value.isNotEmpty){
          await TokenUtils.saveTokenCard(state.tokenCard.value);
        }
        await _authRepository.getDevice();
        emit(state.copyWith(status: LoginStatus.successLogin));
      }
    }
    catch(e){
      debugPrint(e.toString());
      emit(state.copyWith(status: LoginStatus.errorLogin));
      emit(state.copyWith(status: LoginStatus.init));
    }
  }


  changeInputsValues({
    String? token,
    String? tokenCard
}){
    if(token!=null){
      emit(state.copyWith(
        token: state.token.changeValue(token)
      ));
    }
    if(tokenCard!=null){
      emit(state.copyWith(
        tokenCard: state.token.changeValue(tokenCard)
      ));
    }
  }
  validateInput({
    bool token = false,
    bool tokenCard = false
  }){
    if(token){
      emit(state.copyWith(
          token: state.token.validateError()
      ));
    }
    if(tokenCard){
      emit(state.copyWith(
          tokenCard: state.tokenCard.validateError()
      ));
    }
  }

  bool _validateInputs(){
    emit(state.copyWith(
        token: state.token.validateError(),
        tokenCard: state.tokenCard.validateError()
    ));
    if(state.token.inputError !=null){
      return false;
    }
    if(state.tokenCard.inputError !=null){
      return false;
    }

    return true;
  }



}