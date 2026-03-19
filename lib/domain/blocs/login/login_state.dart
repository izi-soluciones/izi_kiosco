part of 'login_bloc.dart';

enum LoginStatus{init,successLogin,errorLogin,waitingLogin}

class LoginState extends Equatable{

  final LoginStatus status;

  final InputObj token;
  final InputObj tokenCard;
  final InputObj deviceId;

  final String? sessionId;
  final String? qrUrl;

  const LoginState({
    required this.status,
    required this.token,
    required this.tokenCard,
    required this.deviceId,
    this.sessionId,
    this.qrUrl
  });



  factory LoginState.init()=>LoginState(
    status: LoginStatus.init,
    token: LoginInputs.tokenInput(),
    tokenCard: LoginInputs.tokenCardInput(),
    deviceId: LoginInputs.deviceInput(),
    sessionId: null,
    qrUrl: null
  );


  LoginState copyWith({
    LoginStatus? status,
    InputObj? token,
    InputObj? tokenCard,
    InputObj? deviceId,
    String? sessionId,
    String? qrUrl
  }){
    return LoginState(
      status: status??this.status,
      token: token?? this.token,
      deviceId: deviceId?? this.deviceId,
      tokenCard: tokenCard?? this.tokenCard,
      sessionId: sessionId?? this.sessionId,
      qrUrl: qrUrl?? this.qrUrl
    );

  }






  @override
  List<Object?> get props => [
    status,
    token,
    deviceId,
    tokenCard,
    sessionId,
    qrUrl
  ];


}