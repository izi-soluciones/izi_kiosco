import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  LoginBloc(this._authRepository):super(LoginState.init());

  login()async{
    try{
      if(_validateInputs()){
        await TokenUtils.saveToken(state.token.value);
        final deviceId = int.parse(state.deviceId.value);
        await BusinessUtils.saveDeviceId(deviceId);
        await _authRepository.getDevice(deviceId);
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
    String? deviceId
}){
    if(token!=null){
      emit(state.copyWith(
        token: state.token.changeValue(token)
      ));
    }
    if(deviceId!=null){
      emit(state.copyWith(
          deviceId: state.deviceId.changeValue(deviceId)
      ));
    }
  }
  validateInput({
    bool token = false,
    bool deviceId = false
  }){
    if(token){
      emit(state.copyWith(
          token: state.token.validateError()
      ));
    }
    if(deviceId){
      emit(state.copyWith(
          deviceId: state.deviceId.validateError()
      ));
    }
  }

  bool _validateInputs(){
    emit(state.copyWith(
        token: state.token.validateError(),
        deviceId: state.deviceId.validateError()
    ));
    if(state.token.inputError !=null){
      return false;
    }
    if(state.deviceId.inputError !=null){
      return false;
    }

    return true;
  }



}