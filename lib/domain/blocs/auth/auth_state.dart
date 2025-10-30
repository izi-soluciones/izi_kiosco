part of 'auth_bloc.dart';

enum AuthStatus{init,noAuth,okAuth,noContribuyente,noEmailCheck,waitingChange,successChange,firstContribuyente, errorAuth}

class AuthState extends Equatable{

  final AuthStatus status;
  final Contribuyente? currentContribuyente;
  final Sucursal? currentSucursal;
  final Device? currentDevice;
  final Pos? currentPos;
  final List<Currency> currencies;
  final File? video;

  final bool loadingContribuyente;

  final StreamSubscription? invoiceSubscription;
  final bool terminalInit;

  final Catalog? catalog;
  final TaxesStrategy taxesStrategy;

  const AuthState({
    required this.currencies,
    required this.status,
    this.currentContribuyente,
    required this.loadingContribuyente,
    this.invoiceSubscription,
    this.currentSucursal,
    this.currentPos,
    required this.terminalInit,
    this.currentDevice,
    this.catalog,
    required this.video,
    required this.taxesStrategy
  });
  factory AuthState.init()=>
      AuthState(
          status: AuthStatus.init,
        loadingContribuyente: false,
        terminalInit: false,
        currencies: const [],
        video: null,
        taxesStrategy: TaxesStrategyDefault()
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
    Device? currentDevice,
    File? video,
    Catalog? catalog,
    TaxesStrategy? taxesStrategy
  }){
    return AuthState(
        currentContribuyente: currentContribuyente??this.currentContribuyente,
        status: status??this.status,
        invoiceSubscription: invoiceSubscription ?? this.invoiceSubscription,
        currentSucursal: currentSucursal ?? this.currentSucursal,
      currentPos: currentPos ?? this.currentPos,
      loadingContribuyente: loadingContribuyente?? this.loadingContribuyente,
      terminalInit: terminalInit ?? this.terminalInit,
      currencies: currencies ?? this.currencies,
      currentDevice: currentDevice ?? this.currentDevice,
      video: video ?? this.video,
      catalog: catalog ?? this.catalog,
      taxesStrategy: taxesStrategy ?? this.taxesStrategy
    );
  }
  AuthState resetState(){
    return AuthState(
      currentContribuyente: null,
      currentSucursal: null,
      currentPos: null,
      status: AuthStatus.noAuth,
      invoiceSubscription: null,
      loadingContribuyente: false,
      terminalInit: false,
      currencies: const [],
      currentDevice: null,
      video: null,
      catalog: null,
      taxesStrategy: TaxesStrategyDefault()
    );
  }
  @override
  List<Object?> get props => [video,currentDevice,catalog,terminalInit,currentContribuyente,status,currentSucursal,invoiceSubscription,currentPos,loadingContribuyente,currencies];

}