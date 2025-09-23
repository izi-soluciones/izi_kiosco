part of 'login_bloc.dart';

enum LoginStatus{init,successLogin,errorLogin,waitingLogin}

class LoginState extends Equatable{

  final LoginStatus status;

  final InputObj token;
  final InputObj tokenCard;
  final InputObj deviceId;


  const LoginState({
    required this.status,
    required this.token,
    required this.tokenCard,
    required this.deviceId
  });



  factory LoginState.init()=>LoginState(
    status: LoginStatus.init,
    token: LoginInputs.tokenInput(),
    tokenCard: LoginInputs.tokenCardInput(),
    deviceId: LoginInputs.deviceInput()
  );


  LoginState copyWith({
    LoginStatus? status,
    InputObj? token,
    InputObj? tokenCard,
    InputObj? deviceId
  }){
    return LoginState(
      status: status??this.status,
      token: token?? this.token,
      deviceId: deviceId?? this.deviceId,
      tokenCard: tokenCard?? this.tokenCard
    );

  }






  @override
  List<Object?> get props => [
    status,
    token,
    deviceId,
    tokenCard
  ];


}