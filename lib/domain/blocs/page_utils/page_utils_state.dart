part of 'page_utils_bloc.dart';


class PageUtilsState extends Equatable{

  final bool snackBarState;
  final SnackBarInfo snackBar;
  final Timer timer;
  final String currentLocation;
  final bool lock;
  final String? titleLoading;

  //SUBMENU STATUS
  final bool configurationMenuOpen;

  final bool screenActive;


  const PageUtilsState(
      {
        required this.snackBarState,
        required this.snackBar,
        required this.timer,
        required this.currentLocation,
        required this.lock,
        required this.configurationMenuOpen,
        this.titleLoading,
        required this.screenActive
    });

  PageUtilsState.defaultState():
      titleLoading=null,
      timer=Timer(const Duration(seconds: 1), () {}),
        snackBarState=false,
        currentLocation="/",
        lock=false,
  screenActive=true,
  configurationMenuOpen=false,
        snackBar=SnackBarInfo(
            text: "",
            snackBarType: SnackBarType.success,
        );


  PageUtilsState hideSnackBar(){
    return copyWith(
        snackBarState: false,
    );
  }
  PageUtilsState showSnackBar({required SnackBarInfo snackBar,required Timer timer}){
    return copyWith(
        snackBarState: true,
        snackBar: snackBar,
        timer: timer
    );
  }



  PageUtilsState copyWith({
    bool? snackBarState,
    SnackBarInfo? snackBar,
    Timer? timer,
    bool? lock,
    bool? configurationMenuOpen,
    String? Function()? titleLoading,
    bool? screenActive,
    String? currentLocation,}){
    return PageUtilsState(
        snackBarState: snackBarState??this.snackBarState,
        snackBar: snackBar??this.snackBar,
        configurationMenuOpen: configurationMenuOpen?? this.configurationMenuOpen,
        lock: lock??this.lock,
        currentLocation: currentLocation??this.currentLocation,
      timer: timer??this.timer,
      titleLoading: titleLoading !=null?titleLoading(): this.titleLoading,
      screenActive: screenActive ?? this.screenActive
    );
  }

  @override
  List<Object?> get props => [
    snackBar,
    snackBarState,
    lock,
    timer,
    currentLocation,
    configurationMenuOpen,
    titleLoading,
    screenActive
  ];
}
