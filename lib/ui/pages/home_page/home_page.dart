import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_avatar.dart';
import 'package:izi_design_system/organisms/izi_side_nav.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/order_list/order_list_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_app_bar.dart';
import 'package:izi_kiosco/ui/general/title/izi_title_lg.dart';
import 'package:izi_kiosco/ui/pages/home_page/widgets/item_home.dart';
import 'package:izi_kiosco/ui/pages/home_page/widgets/top_bar_home.dart';
import 'package:izi_kiosco/ui/utils/flex_container.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return BlocBuilder<AuthBloc,AuthState>(
      builder: (context,state) {
        final contribuyente = state.currentContribuyente;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ru.gtXs()) const IziAppBar(),
            if (ru.gtXs())
              IziTitleLg(
                title: LocaleKeys.home_title.tr(),
              ),
            if (ru.isXs()) const TopBarHome(),
            if (ru.isXs())
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: RowContainer(
                    gap: 16,
                    children: [
                      IziText.title(
                          color: IziColors.dark,
                          text: LocaleKeys.home_title.tr(),
                          mobile: true),
                      const SizedBox(
                          height: 26,
                          child: VerticalDivider(
                            color: IziColors.grey55,
                            thickness: 1,
                          )),
                      RowContainer(gap: 8, children: [
                        IziAvatar(
                            avatarSize: AvatarType.extraSmall,
                            avatarText: contribuyente?.nombre ?? "Z"),
                        IziText.bodyBig(
                            color: IziColors.dark,
                            text: contribuyente?.nombre ?? "",
                            fontWeight: FontWeight.w500)
                      ])
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Container(
                color: ru.gtXs() ? IziColors.white : null,
                child: SingleChildScrollView(
                  child: FlexContainer(
                    flexDirection: FlexDirection.row,
                    padding: const EdgeInsets.all(24),
                    alignment: WrapAlignment.start,
                    gapH: 16,
                    gapV: 16,
                    children: menu(context,state).map((e) {
                      return SizedBox(
                          height: 156,
                          width: 226,
                          child: ItemHome(
                              icon: e.icon, name: e.name, onPressed: e.onPressed));
                    }).toList(),
                  ),
                ),
              ),
            )
          ],
        );
      }
    );
  }

  List<IziSideNavItem> menu(BuildContext context,AuthState authState) {
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
          onPressed: () {
            GoRouter.of(context).goNamed(RoutesKeys.order);
            context.read<OrderListBloc>().getOrders(authState: context.read<AuthBloc>().state,puntoConsumo: true,first: true);
          }),
      if(authState.currentContribuyente?.habilitadoTerminal == true)
      IziSideNavItem(
          name: LocaleKeys.configurationPos_drawer.tr(),
          icon: IziIcons.settings,
          itemValue: RoutesKeys.configurationPos,
          itemLocation: RoutesKeys.configurationPosLink,
          onPressed: () {
            GoRouter.of(context).goNamed(RoutesKeys.configurationPos);
          }),
    ];
  }


}
