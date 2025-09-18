part of 'login_bloc.dart';

enum LoginStatus{init,successLogin,errorLogin,waitingLogin}

class LoginState extends Equatable{

  final LoginStatus status;

  final InputObj token;
  final InputObj deviceId;


  const LoginState({
    required this.status,
    required this.token,
    required this.deviceId
  });



  factory LoginState.init()=>LoginState(
    status: LoginStatus.init,
    token: LoginInputs.userInput(),
    deviceId: LoginInputs.passwordInput()
  );


  LoginState copyWith({
    LoginStatus? status,
    InputObj? token,
    InputObj? deviceId
  }){
    return LoginState(
      status: status??this.status,
      token: token?? this.token,
      deviceId: deviceId?? this.deviceId
    );

  }






  @override
  List<Object?> get props => [
    status,
    token,
    deviceId
  ];


}