import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_select.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_type.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_shimmer.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class MakeOrderPage extends StatefulWidget {
  final bool fromTables;
  final bool isRetail;
  const MakeOrderPage({super.key,required this.fromTables, this.isRetail=false});

  @override
  State<MakeOrderPage> createState() => _MakeOrderPageState();
}

class _MakeOrderPageState extends State<MakeOrderPage> {
  late PageController pageController;
  FocusNode focusNodeKeyboard = FocusNode();
  String barCode = "";
  @override
  void initState() {
    pageController= PageController(initialPage: widget.isRetail?1:0);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return KeyboardListener(
      focusNode: focusNodeKeyboard,
      autofocus: true,
      onKeyEvent: (value) {
        _verifyKeyboard(value);
      },
      child: BlocConsumer<MakeOrderBloc, MakeOrderState>(
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
                          height: ru.isXs()?210:280,
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
      }),
    );
  }

  _verifyKeyboard(
    value,
  ) {
    if (value is KeyDownEvent) {
      if (value.logicalKey.keyLabel == 'Enter' ||
          value.logicalKey.keyId == 4294967309) {
        _verifyBarCode(context, null);
      }
      if (value.character != null) {
        RegExp regex = RegExp(r'^[a-zA-Z0-9 ]+$');
        if (regex.hasMatch(value.character!)) {
          barCode += value.character ?? "";
        }
      }
    }
  }

  _verifyBarCode(BuildContext context, String? value) {
    if (barCode.isEmpty) return;
    final state = context.read<MakeOrderBloc>().state;
    Item? foundItem;
    for (var cat in state.categories) {
      try {
        foundItem = cat.items.firstWhere((element) =>
            element.codigoBarras?.toLowerCase() == barCode.toLowerCase());
        break;
      } catch (e) {}
    }

    if (foundItem != null) {
      var itemAdd = foundItem.copyWith();
      itemAdd.cantidad = 1;
      context.read<MakeOrderBloc>().addItem(item: itemAdd);
    }
    focusNodeKeyboard.requestFocus();
    barCode = "";
  }
}
