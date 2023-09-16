import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/order_list/order_list_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/organisms/izi_side_nav.dart';

class MainLayout extends StatelessWidget {
  final ScrollController scrollControllerHeader = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Widget child;
  final Widget Function()? titleSmall;
  final Widget Function()? titleBig;
  final Color titleCardColorSm;
  final Color titleCardColorLg;
  final bool hideBottomNav;
  final bool hideDrawer;
  final bool resizeWhenForm;
  final String Function()? onPop;
  final bool brand;
  final String currentLocation;
  MainLayout({Key? key,required this.currentLocation,this.brand=false,this.hideBottomNav=false,this.titleSmall,this.titleBig,this.hideDrawer=false,required this.child, this.onPop, this.resizeWhenForm=true,this.titleCardColorSm=IziColors.white,this.titleCardColorLg=IziColors.white}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ru=ResponsiveUtils(context);
    return BlocBuilder<AuthBloc,AuthState>(
      builder: (context,authState) {
        return BlocBuilder<PageUtilsBloc,PageUtilsState>(
              builder: (context,state) {
              return WillPopScope(
                onWillPop: ()async{
                  if(onPop==null){
                    return false;
                  }
                  state.lock?null: onPop!=null?
                  GoRouter.of(context).goNamed(onPop!()):GoRouter.of(context).canPop()?GoRouter.of(context).pop():GoRouter.of(context).goNamed(RoutesKeys.home);
                  return false;
                },
                child: Stack(
                        children: [
                          Positioned.fill(
                              child: Scaffold(
                                key: _scaffoldKey,
                                      resizeToAvoidBottomInset: resizeWhenForm,
                                      backgroundColor: IziColors.lightGrey30,
                                      body: SafeArea(
                                        child: Stack(
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Expanded(
                                                    child: child
                                                ),

                                                if(ru.isXs())
                                                  AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    height: state.snackBarState?50:0,
                                                    child: AnimatedSwitcher(
                                                      duration: const Duration(milliseconds: 200),
                                                      reverseDuration: const Duration(milliseconds:200),
                                                      transitionBuilder: (child,animation)=>SlideTransition(
                                                        position: Tween<Offset>(
                                                          begin: const Offset(0, 1),
                                                          end: const Offset(0, 0),
                                                        ).animate(animation),
                                                        child: child,
                                                      ),
                                                      child: state.snackBarState?
                                                          IziSnackBar(
                                                            snackBarPosition: SnackBarPosition.bottom,
                                                            snackBarInfo: state.snackBar,
                                                            active:state.snackBarState,
                                                            onClickClose: (){
                                                              context.read<PageUtilsBloc>().hideSnackBar();
                                                            },
                                                          )
                                                          :const SizedBox.shrink(),
                                                    ),
                                                  )


                                              ],
                                            ),
                                            if(ru.gtXs())
                                            Positioned(
                                              top: 0,
                                              left: 0,
                                              right: 0,
                                              child:AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 200),
                                                reverseDuration: const Duration(milliseconds:200),
                                                transitionBuilder: (child,animation)=>SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(0, -1),
                                                    end: const Offset(0, 0),
                                                  ).animate(animation),
                                                  child: child,
                                                ),
                                                child: state.snackBarState?
                                                IziSnackBar(
                                                  snackBarPosition: SnackBarPosition.bottom,
                                                  snackBarInfo: state.snackBar,
                                                  onClickClose: (){
                                                    context.read<PageUtilsBloc>().hideSnackBar();
                                                  },
                                                  active:state.snackBarState,
                                                ):const SizedBox.shrink(),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                          ),
                          if(state.lock || authState.loadingContribuyente)
                            Positioned.fill(child: Container(color: Colors.transparent,))
                        ],
                      )
              );


            }
        );
      }
    );
  }

  List<IziSideNavItem> menu(BuildContext context,PageUtilsState pageUtilsState,AuthState authState){
    return [
      if(authState.currentContribuyente?.habilitadoMesas==true && (authState.currentSucursal?.config?["restaurantPagoAdelantado"] ?? false)==false)
      IziSideNavItem(
          name: LocaleKeys.tables_drawer.tr(),
          icon: IziIcons.restTable,
          itemValue: RoutesKeys.tables,
          itemLocation: RoutesKeys.tablesLink,
          onPressed: () {
            GoRouter.of(context).goNamed(RoutesKeys.tables);
          }),

      IziSideNavItem(
          name: LocaleKeys.makeOrder_drawer.tr(),
          icon: IziIcons.orderNew,
          itemValue: RoutesKeys.makeOrder,
          itemLocation: RoutesKeys.makeOrderLink,
          onPressed: () {
            GoRouter.of(context).goNamed(RoutesKeys.makeOrder);
          }),
      IziSideNavItem(
          name: LocaleKeys.orderList_title.tr(),
          icon: IziIcons.order,
          itemValue: RoutesKeys.order,
          itemLocation: RoutesKeys.orderLink,
          onPressed: (){
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              _scaffoldKey.currentState?.closeDrawer();
            }
            if(currentLocation==RoutesKeys.orderLink){
              context.read<OrderListBloc>().getOrders(authState: context.read<AuthBloc>().state,puntoConsumo: true,first: true);
            }
            GoRouter.of(context).goNamed(RoutesKeys.order);
          }),
      if(authState.currentContribuyente?.habilitadoTerminal==true)
      IziSideNavItem(
          name: LocaleKeys.configuration_title.tr(),
          icon: IziIcons.settings,
          itemValue: "",
          itemLocation: "",
          open: pageUtilsState.configurationMenuOpen,
          onPressed: (){
            context.read<PageUtilsBloc>().changeSubmenuStatus(configuration: !pageUtilsState.configurationMenuOpen);

          },
        submenu: [
          IziSideNavItem(
              name: LocaleKeys.configurationPos_drawer.tr(),
              icon: IziIcons.cardBack,
              itemValue: RoutesKeys.configurationPos,
              itemLocation: RoutesKeys.configurationPosLink,
              onPressed: (){
                if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                  _scaffoldKey.currentState?.closeDrawer();
                }
                GoRouter.of(context).goNamed(RoutesKeys.configurationPos);
              },
          ),
        ]
          ),
    ];
  }
}

