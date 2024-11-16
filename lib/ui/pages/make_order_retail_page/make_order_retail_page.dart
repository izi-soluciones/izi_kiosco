import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/make_order_retail/make_order_retail_bloc.dart';
import 'package:izi_kiosco/ui/modals/warning_config_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_retail_page/views/make_order_retail_init.dart';
import 'package:izi_kiosco/ui/pages/make_order_retail_page/views/make_order_retail_scan.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';

class MakeOrderRetailPage extends StatefulWidget {
  const MakeOrderRetailPage({super.key});

  @override
  State<MakeOrderRetailPage> createState() => _MakeOrderRetailPageState();
}

class _MakeOrderRetailPageState extends State<MakeOrderRetailPage> {
  PageController pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MakeOrderRetailBloc, MakeOrderRetailState>(
        listenWhen: (previous, current) {
          return previous.status!=current.status || previous.step != current.step;
        },
        listener: (context, state) {

          if(pageController.page!=state.step){
            pageController.jumpToPage(state.step);
          }

          if(state.status == MakeOrderRetailStatus.errorCashRegisters){
            CustomAlerts.defaultAlert(context: context,dismissible: true, child: WarningConfigModal(
                title: LocaleKeys.warningCashRegisters_title.tr(),
                description: ""
            )).then((value){
              GoRouter.of(context).goNamed(RoutesKeys.home);
            });
          }
          if(state.status == MakeOrderRetailStatus.errorActivity){
            CustomAlerts.defaultAlert(context: context,dismissible: true, child: WarningConfigModal(
                title: LocaleKeys.warningActivity_title.tr(),
                description: LocaleKeys.warningActivity_description.tr()
            )).then((value){
              GoRouter.of(context).goNamed(RoutesKeys.home);
            });
          }
          if(state.status == MakeOrderRetailStatus.errorStore){
            CustomAlerts.defaultAlert(context: context,dismissible: true, child: WarningConfigModal(
                title: LocaleKeys.warningStore_title.tr(),
                description: LocaleKeys.warningStore_description.tr()
            )).then((value){
              GoRouter.of(context).goNamed(RoutesKeys.home);
            });
          }
        },
        builder: (context, state) {
          return PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              MakeOrderRetailInit(state: state),
              MakeOrderRetailScan(state: state)
            ],
          );
        });
  }
}
