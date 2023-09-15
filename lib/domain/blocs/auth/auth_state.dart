part of 'auth_bloc.dart';

enum AuthStatus{init,noAuth,okAuth,noContribuyente,noEmailCheck,waitingChange,successChange}

class AuthState extends Equatable{

  final AuthStatus status;
  final User? currentUser;
  final List<Contribuyente>? contribuyentes;
  final Contribuyente? currentContribuyente;
  final Sucursal? currentSucursal;
  final Pos? currentPos;
  final List<Currency> currencies;

  final bool loadingContribuyente;

  final StreamSubscription? invoiceSubscription;
  final bool terminalInit;
  const AuthState({
    required this.currencies,
    required this.status,
    this.currentUser,
    this.currentContribuyente,
    this.contribuyentes,
    required this.loadingContribuyente,
    this.invoiceSubscription,
    this.currentSucursal,
    this.currentPos,
    required this.terminalInit
  });
  factory AuthState.init()=>
      const AuthState(
          status: AuthStatus.init,
        loadingContribuyente: false,
        terminalInit: false,
        currencies: []
      );

  AuthState copyWith({
    AuthStatus? status,
    User? currentUser,
    List<Contribuyente>? contribuyentes,
    Contribuyente? currentContribuyente,
    Sucursal? currentSucursal,
    StreamSubscription? invoiceSubscription,
    Pos? currentPos,
    bool? loadingContribuyente,
    bool? terminalInit,
    List<Currency>? currencies
  }){
    return AuthState(
        currentContribuyente: currentContribuyente??this.currentContribuyente,
        contribuyentes: contribuyentes??this.contribuyentes,
        status: status??this.status,
        currentUser: currentUser??this.currentUser,
        invoiceSubscription: invoiceSubscription ?? this.invoiceSubscription,
        currentSucursal: currentSucursal ?? this.currentSucursal,
      currentPos: currentPos ?? this.currentPos,
      loadingContribuyente: loadingContribuyente?? this.loadingContribuyente,
      terminalInit: terminalInit ?? this.terminalInit,
      currencies: currencies ?? this.currencies
    );
  }
  AuthState resetState(){
    return const AuthState(
      currentContribuyente: null,
      currentSucursal: null,
      contribuyentes:null,
      currentUser: null,
      currentPos: null,
      status: AuthStatus.noAuth,
      invoiceSubscription: null,
      loadingContribuyente: false,
      terminalInit: false,
      currencies: []
    );
  }
  @override
  List<Object?> get props => [terminalInit,currentContribuyente,status,currentUser,contribuyentes,currentSucursal,invoiceSubscription,currentPos,loadingContribuyente,currencies];

}