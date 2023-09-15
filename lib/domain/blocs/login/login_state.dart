part of 'login_bloc.dart';

enum LoginStatus{init,successLogin,errorLogin,waitingLogin}

class LoginState extends Equatable{

  final LoginStatus status;

  final InputObj user;
  final InputObj password;


  const LoginState({
    required this.status,
    required this.user,
    required this.password
  });



  factory LoginState.init()=>LoginState(
    status: LoginStatus.init,
    user: LoginInputs.userInput(),
    password: LoginInputs.passwordInput()
  );


  LoginState copyWith({
    LoginStatus? status,
    InputObj? user,
    InputObj? password
  }){
    return LoginState(
      status: status??this.status,
      user: user?? this.user,
      password: password?? this.password
    );

  }






  @override
  List<Object?> get props => [
    status,
    user,
    password
  ];


}