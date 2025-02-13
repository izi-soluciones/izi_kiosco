import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/modals/warning_config_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_confirm.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_detail.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_detail_vertical.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_select.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_type.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_shimmer.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class MakeOrderPage extends StatefulWidget {
  final bool fromTables;
  const MakeOrderPage({super.key,required this.fromTables});

  @override
  State<MakeOrderPage> createState() => _MakeOrderPageState();
}

class _MakeOrderPageState extends State<MakeOrderPage> {
  PageController pageController = PageController();
  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return BlocConsumer<MakeOrderBloc, MakeOrderState>(
      listenWhen: (previous, current) {
        return previous.status!=current.status || previous.step != current.step;
      },
        listener: (context, state) {

          if(pageController.page!=state.step){
            pageController.jumpToPage(state.step);
          }

          if(state.status == MakeOrderStatus.errorCashRegisters){
            CustomAlerts.defaultAlert(context: context,dismissible: true, child: WarningConfigModal(
                title: LocaleKeys.warningCashRegisters_title.tr(),
                description: ""
            )).then((value){
              context.read<PageUtilsBloc>().closeScreenActive();
              GoRouter.of(context).goNamed(RoutesKeys.home);
            });
          }
          if(state.status==MakeOrderStatus.errorEmit){
            context.read<PageUtilsBloc>().showSnackBar(
                snackBar: SnackBarInfo(
                    text: state.errorDescription ??
                        LocaleKeys.makeOrder_messages_errorEmit.tr(),
                    snackBarType: SnackBarType.error)
            );
          }
        },
          builder: (context, state) {
        return PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MakeOrderType(state: state),
            Row(
              children: [
                Expanded(
                  child: Column(
                      children: [
                        Expanded(
                          child: state.status == MakeOrderStatus.waitingGet
                              ? MakeOrderShimmer(state: state,)
                              : MakeOrderSelect(
                              makeOrderState: state,
                              fromTables: widget.fromTables
                          ),
                        ),
                        if(ru.isVertical())
                        SizedBox(
                          height: 280,
                          child: MakeOrderDetail(
                              state: state
                          ),
                        )
                      ]),
                ),
                if(!ru.isVertical())
                SizedBox(
                  width: 400,
                  child: MakeOrderDetailVertical(
                      state: state
                  ),
                ),
              ],
            ),
            MakeOrderConfirm(state: state)
          ],
        );
      });
  }
}
