import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
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
import 'package:izi_kiosco/ui/utils/row_container.dart';

class MakeOrderDetail extends StatefulWidget {
  final MakeOrderState state;
  const MakeOrderDetail({super.key, required this.state});

  @override
  State<MakeOrderDetail> createState() => _MakeOrderDetailState();
}

class _MakeOrderDetailState extends State<MakeOrderDetail> {
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
        border: Border(
          top: BorderSide(color: IziColors.grey35, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.state.itemsSelected.isNotEmpty
              ? Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32,16,32,0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IziText.titleSmall(
                          color: IziColors.darkGrey, text: "Mi orden:"),
                      Expanded(
                        child: _listItems(ru),
                      )
                    ],
                ),
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

  _totalOrder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: IziBtn(
                    buttonText: LocaleKeys.makeOrder_buttons_initAgain.tr(),
                    buttonType: ButtonType.outline,
                    buttonSize: ButtonSize.large,
                    buttonOnPressed: () {
                      //context.read<MakeOrderBloc>().printRollo(context.read<AuthBloc>().state);
                      context.read<MakeOrderBloc>().resetItems();
                    }),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                flex: 8,
                child: MakeOrderAmountBtn(
                    onPressed: _getTotal() > 0
                        ? () {
                      _next(context);
                    }
                        : null,
                    text: LocaleKeys.makeOrder_buttons_confirm.tr(),
                    amount: (_getTotal() - widget.state.discountAmount).moneyFormat(
                        currency: widget.state.currentCurrency?.simbolo)
                ),
              )
            ],
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
    return SizedBox(
      width: 150,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 5),
            child: IziCard(
              onPressed: () {
                _editItem(context, item, indexCategory, indexItem);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IziText.body(
                          color: IziColors.dark,
                          text: item.nombre,
                          fontWeight: FontWeight.w600,
                          maxLines: 2),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: IziInput(
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
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              radius: 20,
              onTap: () {
                context
                    .read<MakeOrderBloc>()
                    .removeItem(indexCategory, indexItem);
              },
              child: Container(
                decoration: const BoxDecoration(
                    color: IziColors.red, shape: BoxShape.circle),
                child: const Icon(
                  IziIcons.close,
                  size: 22,
                  color: IziColors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  _listItems(ResponsiveUtils ru) {
    return IziScroll(
      scrollController: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 16),
        child: RowContainer(
          gap: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.state.itemsSelected.asMap().entries.map((e) {
            return RowContainer(
              gap: 16,
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
