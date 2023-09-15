import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/data/local/local_storage_credentials.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/data/utils/user_utils.dart';
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
        LoginRequest loginRequest = _buildLoginRequest();
        emit(state.copyWith(status: LoginStatus.waitingLogin));
        LoginResponse loginResponse=await _authRepository.login(loginRequest);
        await TokenUtils.saveToken(loginResponse.token);
        await UserUtils.saveUser(loginResponse.user);
        await LocalStorageCredentials.saveCredentials(state.password.value, state.user.value);
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
    String? user,
    String? password
}){
    if(user!=null){
      emit(state.copyWith(
        user: state.user.changeValue(user)
      ));
    }
    if(password!=null){
      emit(state.copyWith(
          password: state.password.changeValue(password)
      ));
    }
  }
  validateInput({
    bool user = false,
    bool password = false
  }){
    if(user){
      emit(state.copyWith(
          user: state.user.validateError()
      ));
    }
    if(password){
      emit(state.copyWith(
          password: state.password.validateError()
      ));
    }
  }

  bool _validateInputs(){
    emit(state.copyWith(
        user: state.user.validateError(),
        password: state.password.validateError()
    ));
    if(state.user.inputError !=null){
      return false;
    }
    if(state.password.inputError !=null){
      return false;
    }

    return true;
  }

  LoginRequest _buildLoginRequest(){
    LoginRequest loginRequest = LoginRequest.init();
    loginRequest.contrasena=state.password.value;
    loginRequest.correoElectronico=state.user.value;
    return loginRequest;
  }



}