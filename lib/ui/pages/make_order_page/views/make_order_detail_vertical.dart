import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_btn_icon.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/item_options_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_amount_btn.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class MakeOrderDetailVertical extends StatefulWidget {
  final MakeOrderState state;
  const MakeOrderDetailVertical({super.key, required this.state});

  @override
  State<MakeOrderDetailVertical> createState() => _MakeOrderDetailStateVertical();
}

class _MakeOrderDetailStateVertical extends State<MakeOrderDetailVertical> {
  ScrollController scrollController = ScrollController();
  bool loadingEmit = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Container(
      decoration: const BoxDecoration(
        color: IziColors.white,
        border: Border(
          left: BorderSide(color: IziColors.grey35, width: 1),
        ),
      ),
      child: Column(
        children: [
          widget.state.itemsSelected.isNotEmpty
              ? Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IziText.title(
                          color: IziColors.dark, text: "Mi orden",fontWeight: FontWeight.w600),
                    ),
                    const Divider(color: IziColors.grey35,height: 1,thickness: 1),
                    _headerItems(ru),
                    const Divider(color: IziColors.grey35,height: 1,thickness: 1),
                    Expanded(
                      child: _listItems(ru),
                    )
                  ],
                                  ))
              : Expanded(
                  child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: IziText.body(
                        color: IziColors.grey,
                        text:
                            LocaleKeys.makeOrder_body_addDishesOrDrinks.tr(),
                        fontWeight: FontWeight.w400),
                  ),
                )),
          _totalOrder()
        ],
      ),
    );
  }
  _headerItems(ResponsiveUtils ru) {
    return Padding(
      padding: const EdgeInsets.only(top: 11, bottom: 11, left: 16,right: 16),
      child: Row(
        children: [
            Expanded(
              flex: 2,
              child: IziText.bodySmall(
                  color: IziColors.darkGrey85,
                  text: LocaleKeys.makeOrder_labels_count.tr(),
                  fontWeight: FontWeight.w500),
            ),
          const SizedBox(width: 16,),
          Expanded(
            flex:4,
            child: IziText.bodySmall(
                color: IziColors.darkGrey85,
                text: LocaleKeys.makeOrder_labels_item.tr(),
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            width: 40,
          )
        ],
      ),
    );
  }

  _totalOrder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IziBtn(
              buttonText: LocaleKeys.makeOrder_buttons_initAgain.tr(),
              buttonType: ButtonType.outline,
              buttonSize: ButtonSize.medium,
              buttonOnPressed: () {
                //context.read<MakeOrderBloc>().printRollo(context.read<AuthBloc>().state);
                context.read<MakeOrderBloc>().resetItems();
              }),
          const SizedBox(
            height: 8,
          ),
          MakeOrderAmountBtn(
              onPressed: _getTotal() > 0
                  ? () {
                _next(context);
              }
                  : null,
              text: LocaleKeys.makeOrder_buttons_confirm.tr(),
              amount: (_getTotal() - widget.state.discountAmount).moneyFormat(
                  currency: widget.state.currentCurrency?.simbolo)
          ),
          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }

  _next(BuildContext context) {
    context.read<MakeOrderBloc>().changeStepStatus(2);
  }

  _item(BuildContext context,Item item, int indexCategory,
      int indexItem) {
    return InkWell(
      onTap: () {
        _editItem(context, item, indexCategory, indexItem);
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: IziColors.grey35, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 65,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IziInput(
                    autoSelect: true,
                    textAlign: TextAlign.center,
                    controller: TextEditingController(text: item.cantidad.toString())..selection=TextSelection.fromPosition(TextPosition(offset: item.cantidad.toString().length)),
                    inputHintText: "0",
                    inputType: InputType.incremental,
                    minValue: 1,
                    readOnly: true,
                    maxValue: 999999999,
                    inputSize: InputSize.extraSmall,
                    value: item.cantidad.toString(),
                    onChanged: (value, valueRaw) {
                      item.cantidad = num.tryParse(value) ?? 1;
                      context.read<MakeOrderBloc>().reloadItems();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16,),
            Expanded(
              flex:4,
              child: IziText.body(
                  color: IziColors.dark,
                  text: item.nombre,
                  fontWeight: FontWeight.w600,
                  maxLines: 2),
            ),
            const SizedBox(width: 16,),
            IziBtnIcon(
              buttonIcon: IziIcons.close,
              color: IziColors.red,
              buttonType: ButtonType.primary,
              buttonSize: ButtonSize.small,
              buttonOnPressed: (){
                context
                    .read<MakeOrderBloc>()
                    .removeItem(indexCategory, indexItem);
                },
            ),
          ],
        ),
      ),
    );
  }

  _listItems(ResponsiveUtils ru) {
    return IziScroll(
      scrollController: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.state.itemsSelected.asMap().entries.map((e) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...e.value.items.asMap().entries.map(
                  (i) {
                    return _item(
                      context,
                        i.value,
                        e.key,
                        i.key);
                  },
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  _editItem(BuildContext context, Item item, int indexC, int indexI) {

    CustomAlerts.defaultAlert(
        defaultScroll: false,
        padding: EdgeInsets.zero,
        context: context,
        dismissible: true,
        child: ItemOptionsModal(
          item: item,
          state: widget.state,
        )).then((result) {
      if (result is Item) {
        var itemNew = result;
        context
            .read<MakeOrderBloc>()
            .updateItemSelected(itemNew, indexC, indexI);
      }
    });
    return;
  }


  num _getTotal() {
    num total = 0;
    for (var e in widget.state.itemsSelected) {
      for (var i in e.items) {
        total += i.cantidad * i.precioUnitario + i.precioModificadores;
      }
    }
    return total;
  }
}
