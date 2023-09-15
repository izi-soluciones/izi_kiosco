import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/tables/tables_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_app_bar.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/make_order_discount_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_detail.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_select.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_shimmer.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class MakeOrderPage extends StatelessWidget {
  final bool fromTables;
  const MakeOrderPage({super.key,required this.fromTables});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return BlocConsumer<MakeOrderBloc, MakeOrderState>(
      listener: (context, state) {
        if(state.status==MakeOrderStatus.errorEmit){
          context.read<PageUtilsBloc>().showSnackBar(
              snackBar: SnackBarInfo(
                  text: state.errorDescription ??
                      LocaleKeys.makeOrder_messages_errorEmit.tr(),
                  snackBarType: SnackBarType.error)
          );
        }
        if(state.status==MakeOrderStatus.successEmit || state.status==MakeOrderStatus.successEdit){
          if(fromTables){
            context.read<TablesBloc>().init(context.read<AuthBloc>().state);
            GoRouter.of(context).goNamed(RoutesKeys.tables);
          }
          else{
            context.read<MakeOrderBloc>().resetOrder();
          }
          context.read<PageUtilsBloc>().showSnackBar(
              snackBar: SnackBarInfo(
                  text: state.status==MakeOrderStatus.successEmit?LocaleKeys.makeOrder_messages_successEmit.tr():LocaleKeys.makeOrder_messages_successEdit.tr(),
                  snackBarType: SnackBarType.success)
          );

        }
      },
        builder: (context, state) {
      return Stack(
        children: [
          Positioned.fill(
            child: Row(
                /*initialAreas: [
                  Area(),
                  if (ru.gtSm())
                    Area(
                      minimalSize: 400,
                      size: 400,
                    )
                ],
                dividerBuilder:
                    (axis, index, resizable, dragging, highlighted, themeData) {
                  return Container(
                    color:
                        dragging ? IziColors.lightGrey : IziColors.lightGrey30,
                    child: Icon(
                      Icons.menu,
                      color: highlighted ? Colors.grey[600] : Colors.grey[400],
                    ),
                  );
                },*/
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if (ru.gtXs()) const IziAppBar(),
                        Expanded(
                            child: state.status == MakeOrderStatus.waitingGet
                                ? MakeOrderShimmer(state: state,)
                                : MakeOrderSelect(
                                    makeOrderState: state,
                              fromTables: fromTables
                                  ))
                      ],
                    ),
                  ),
                  if (ru.gtSm())
                    SizedBox(
                      width: 400,
                      child: MakeOrderDetail(
                        state: state
                      ),
                    ),
                ]),
          ),
          if (ru.lwSm() && _getTotalItems(state) > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: InkWell(
                onTap: () {
                  showBottomSheet(
                    context: context,
                    builder: (_) {
                      return BlocProvider.value(
                          value: BlocProvider.of<MakeOrderBloc>(context),
                          child: BlocBuilder<MakeOrderBloc,MakeOrderState>(
                            builder: (context,makeOrderState) {
                              return MakeOrderDetail(state: makeOrderState);
                            }
                          ));
                    },
                  );
                },
                child: IziCard(
                  radiusBottom: false,
                  radiusTop: false,
                  elevationTop: true,
                  child: Column(
                    children: [
                      const Icon(IziIcons.upB,color: IziColors.grey55,size: 20),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16,4,16,16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IziText.bodyBig(
                                color: IziColors.dark,
                                text: LocaleKeys.makeOrder_body_items
                                    .tr(args: [_getTotalItems(state).toString()]),
                                fontWeight: FontWeight.w500),
                            Row(
                              children: [
                                IziText.bodyBig(
                                    color: IziColors.dark,
                                    text: LocaleKeys.makeOrder_labels_total.tr(),
                                    fontWeight: FontWeight.w500),
                                const SizedBox(
                                  width: 4,
                                ),
                                IziText.bodyBig(
                                    color: IziColors.secondary,
                                    text: _getTotal(state).moneyFormat(
                                        currency: state.currentCurrency?.simbolo),
                                    fontWeight: FontWeight.w600),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (state.offsetDiscount != null && ru.gtSm())
            Positioned.fill(
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context.read<MakeOrderBloc>().closeDiscount();
                  },
                  child: const SizedBox.shrink()),
            ),
          if (state.offsetDiscount != null && ru.gtSm())
            Positioned(
                left: state.offsetDiscount!.x - 320 < 0
                    ? state.offsetDiscount!.x
                    : null,
                right: state.offsetDiscount!.x - 320 < 0
                    ? null
                    : ru.width - state.offsetDiscount!.x,
                top: state.offsetDiscount!.y + 360 > ru.height
                    ? null
                    : state.offsetDiscount!.y,
                bottom: state.offsetDiscount!.y + 360 <= ru.height ? null : 10,
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: 320 > state.offsetDiscount!.x
                            ? state.offsetDiscount!.x
                            : 320,
                        maxHeight: 360 > ru.height + 20 ? ru.height - 20 : 360),
                    child: Material(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: IziColors.white,
                        child: MakeOrderDiscountModal(state: state)))),
        ],
      );
    });
  }

  num _getTotalItems(MakeOrderState state) {
    num count = 0;
    for (var c in state.itemsSelected) {
      for (var i in c.items) {
        count += i.cantidad;
      }
    }
    return count;
  }

  num _getTotal(MakeOrderState state) {
    num total = 0;
    for (var e in state.itemsSelected) {
      for (var i in e.items) {
        total += i.cantidad * i.precioUnitario + i.precioModificadores;
      }
    }
    return total;
  }
}
