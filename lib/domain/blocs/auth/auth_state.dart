part of 'auth_bloc.dart';

enum AuthStatus{init,noAuth,okAuth,noContribuyente,noEmailCheck,waitingChange,successChange,firstContribuyente}

class AuthState extends Equatable{

  final AuthStatus status;
  final User? currentUser;
  final List<Contribuyente>? contribuyentes;
  final Contribuyente? currentContribuyente;
  final Sucursal? currentSucursal;
  final Device? currentDevice;
  final Pos? currentPos;
  final List<Currency> currencies;
  final List<Device> devices;
  final File? video;

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
    required this.terminalInit,
    this.currentDevice,
    required this.devices,
    required this.video
  });
  factory AuthState.init()=>
      const AuthState(
          status: AuthStatus.init,
        loadingContribuyente: false,
        terminalInit: false,
        currencies: [],
        devices: [],
        video: null
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
    List<Currency>? currencies,
    List<Device>? devices,
    Device? currentDevice,
    File? video
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
      currencies: currencies ?? this.currencies,
      devices: devices ?? this.devices,
      currentDevice: currentDevice ?? this.currentDevice,
      video: video ?? this.video
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
      currencies: [],
      devices: [],
      currentDevice: null,
      video: null
    );
  }
  @override
  List<Object?> get props => [video,currentDevice,devices,terminalInit,currentContribuyente,status,currentUser,contribuyentes,currentSucursal,invoiceSubscription,currentPos,loadingContribuyente,currencies];

}