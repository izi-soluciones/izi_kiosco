import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/izi_screen_inactive.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/item_options_modal.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_design_system/organisms/izi_side_nav.dart';

class MainLayout extends StatelessWidget {
  final ScrollController scrollControllerHeader = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Widget child;
  final Widget Function()? titleSmall;
  final Widget Function()? titleBig;
  final bool hideBottomNav;
  final bool hideDrawer;
  final bool resizeWhenForm;
  final String Function()? onPop;
  final bool brand;
  final String currentLocation;
  MainLayout({Key? key,required this.currentLocation,this.brand=false,this.hideBottomNav=false,this.titleSmall,this.titleBig,this.hideDrawer=false,required this.child, this.onPop, this.resizeWhenForm=true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        Item? item = context.read<MakeOrderBloc>().state.itemModal;
        if(item != null){
        _openAlertItem(item,context);
        }
        context.read<PageUtilsBloc>().updateScreenActive();
      },
      child: BlocBuilder<AuthBloc,AuthState>(
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
                                        backgroundColor: context.iziColors.lightGrey30,
                                        body: SafeArea(
                                          child: child
                                        ),
                                      ),
                            ),
                            if(state.lock || authState.loadingContribuyente)
                              Positioned.fill(child: Container(color: Colors.transparent,)),
                            if(!state.screenActive)
                              const Positioned.fill(child: IziScreenInactive())
                          ],
                        )
                );


              }
          );
        }
      ),
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

  _openAlertItem(Item item,BuildContext context){

    context.read<MakeOrderBloc>().resetItemModal();
    CustomAlerts.defaultAlert(
        defaultScroll: false,
        padding: EdgeInsets.zero,
        context: context,
        dismissible: false,
        child: ItemOptionsModal(
            item: item, state: context.read<MakeOrderBloc>().state))
        .then((result) {
      if (result is Item) {
        var itemNew = result;
        itemNew.cantidad = 1;
        context.read<MakeOrderBloc>().addItem(item: itemNew);
      }
    });
  }
}

