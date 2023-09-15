import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/utils/download_utils.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/modals/number_diners_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/make_order_discount_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/make_order_edit_table_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_chip.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_header_sm.dart';
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
  List<TextEditingController> controllers = [];
  ScrollController scrollController = ScrollController();
  bool loadingEmit=false;
  @override
  void initState() {
    for (var c in widget.state.itemsSelected) {
      List.generate(c.items.length, (index) {
        controllers.add(TextEditingController());
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return BlocListener<MakeOrderBloc, MakeOrderState>(
      listener: (context, state) {
        int cIndex = 0;
        for (var c in state.itemsSelected) {
          for (var i in c.items) {
            if (cIndex >= controllers.length - 1) {
              controllers.add(TextEditingController());
            }
            if (controllers[cIndex].text == i.cantidad.toString()) {
              cIndex++;
              continue;
            }
            controllers[cIndex].text =
                i.cantidad > 0 ? i.cantidad.toString() : "0";
            cIndex++;
          }
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: IziColors.grey35, width: 1),
                ),
              ),
              child: Column(
                children: [
                  if (ru.gtSm()) _header(),
                  if(ru.lwSm()) MakeOrderHeaderSm(state: widget.state,onPop:(){
                    Navigator.pop(context);
                  }),
                  const Divider(
                    color: IziColors.grey35,
                    height: 1,
                  ),
                  if (widget.state.itemsSelected.isNotEmpty) _headerItems(ru),
                  widget.state.itemsSelected.isNotEmpty
                      ? Expanded(child: _listItems(ru))
                      : Expanded(
                          child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: IziText.body(
                                color: IziColors.grey,
                                text: LocaleKeys
                                    .makeOrder_body_addDishesOrDrinks
                                    .tr(),
                                fontWeight: FontWeight.w400),
                          ),
                        )),
                  const Divider(
                    color: IziColors.grey35,
                    height: 1,
                  ),
                  _totalOrder()
                ],
              ),
            ),
          ),
          if (widget.state.offsetDiscount != null && ru.lwSm())
            Positioned.fill(
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context.read<MakeOrderBloc>().closeDiscount();
                  },
                  child: const SizedBox.shrink()),
            ),
          if (widget.state.offsetDiscount != null && ru.lwSm())
            Positioned(
                left: widget.state.offsetDiscount!.x,
                right: widget.state.offsetDiscount!.x+320>ru.width?4:ru.width - 320 - widget.state.offsetDiscount!.x,
                top: widget.state.offsetDiscount!.y + 360 > ru.height
                    ? null
                    : widget.state.offsetDiscount!.y,
                bottom: widget.state.offsetDiscount!.y + 360 <= ru.height
                    ? null
                    : 10,
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: 320 > widget.state.offsetDiscount!.x
                            ? widget.state.offsetDiscount!.x
                            : 320,
                        maxHeight: 360 > ru.height + 20 ? ru.height - 20 : 360),
                    child: Material(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: IziColors.white,
                        child: MakeOrderDiscountModal(state: widget.state)))),
        ],
      ),
    );
  }

  _totalOrder() {
    return Container(
      color: IziColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_getTotal() > 0)
            InkWell(
              onTapDown: (TapDownDetails details) {
                context.read<MakeOrderBloc>().openDiscount(
                    MakeOrderDiscountOffset(
                        details.globalPosition.dx, details.globalPosition.dy));
              },
              child: Container(
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: IziColors.grey35, width: 0.5))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.state.discountAmount > 0)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            IziIcons.edit,
                            color: IziColors.grey,
                            size: 15,
                          ),
                        ),
                      IziText.body(
                          color: IziColors.grey,
                          text: widget.state.discountAmount > 0
                              ? LocaleKeys.makeOrder_buttons_editDiscount.tr()
                              : "+ ${LocaleKeys.makeOrder_buttons_discount.tr()}",
                          fontWeight: FontWeight.w500),
                    ],
                  )),
            ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IziText.body(
                  color: IziColors.grey,
                  text: LocaleKeys.makeOrder_labels_subtotal.tr(),
                  fontWeight: FontWeight.w400),
              IziText.body(
                  color: IziColors.darkGrey,
                  text: _getTotal().moneyFormat(
                      currency: widget.state.currentCurrency?.simbolo),
                  fontWeight: FontWeight.w400),
            ],
          ),
          if (widget.state.discountAmount > 0)
            const SizedBox(
              height: 8,
            ),
          if (widget.state.discountAmount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IziText.body(
                    color: IziColors.grey,
                    text: LocaleKeys.makeOrder_labels_discount.tr(),
                    fontWeight: FontWeight.w500),
                IziText.body(
                    color: IziColors.darkGrey,
                    text: widget.state.discountAmount.moneyFormat(
                        currency: widget.state.currentCurrency?.simbolo ??
                            AppConstants.defaultCurrency),
                    fontWeight: FontWeight.w400),
              ],
            ),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IziText.bodyBig(
                  color: IziColors.grey,
                  text: LocaleKeys.makeOrder_labels_total.tr(),
                  fontWeight: FontWeight.w600),
              IziText.bodyBig(
                  color: IziColors.darkGrey,
                  text: (_getTotal() - widget.state.discountAmount).moneyFormat(
                      currency: widget.state.currentCurrency?.simbolo),
                  fontWeight: FontWeight.w600),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          IziBtn(
              buttonText: LocaleKeys.makeOrder_buttons_confirm.tr(),
              buttonType: ButtonType.secondary,
              buttonSize: ButtonSize.medium,
              loading: loadingEmit,
              buttonOnPressed: _getTotal() > 0 ? () async{
                setState(() {
                  loadingEmit=true;
                });
                context.read<PageUtilsBloc>().lockPage();
                var value= await context.read<MakeOrderBloc>().emitOrder(context.read<AuthBloc>().state).then((value) {
                  context.read<PageUtilsBloc>().unlockPage();
                  return value;
                },);
                if(value is Comanda){
                  for (var cPdf in value.comandasPdf) {
                    if(cPdf.pdf!=null){
                      await DownloadUtils().downloadFile(cPdf.pdf!);
                    }
                  }
                }
                setState(() {
                  loadingEmit=false;
                });
              } : null),
          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }

  _headerItems(ResponsiveUtils ru) {
    return Padding(
      padding: const EdgeInsets.only(top: 11, bottom: 11, left: 20),
      child: RowContainer(
        gap: 4,
        children: [
          if (ru.gtXs())
            Expanded(
              flex: ru.isSm() ? 3 : 2,
              child: IziText.bodySmall(
                  color: IziColors.darkGrey85,
                  text: LocaleKeys.makeOrder_labels_count.tr(),
                  fontWeight: FontWeight.w500),
            ),
          Expanded(
            flex: 6,
            child: IziText.bodySmall(
                color: IziColors.darkGrey85,
                text: LocaleKeys.makeOrder_labels_item.tr(),
                fontWeight: FontWeight.w500),
          ),
          /*Expanded(
            flex: 2,
            child: IziText.bodySmall(
                textAlign: TextAlign.center,
                color: IziColors.darkGrey85,
                text: LocaleKeys.makeOrder_labels_discount.tr(),
                fontWeight: FontWeight.w500),
          ),*/
          if (ru.isXs())
            Expanded(
              flex: 6,
              child: IziText.bodySmall(
                  color: IziColors.darkGrey85,
                  text: LocaleKeys.makeOrder_labels_count.tr(),
                  fontWeight: FontWeight.w500),
            ),
          if (ru.gtXs())
            Expanded(
              flex: 3,
              child: IziText.bodySmall(
                  color: IziColors.darkGrey85,
                  textAlign: TextAlign.center,
                  text: LocaleKeys.makeOrder_labels_price.tr(),
                  fontWeight: FontWeight.w500),
            ),
          const SizedBox(
            width: 28,
          )
        ],
      ),
    );
  }

  _itemSm(Item item, TextEditingController? controller, int indexCategory,
      int indexItem) {
    return Container(
      color: IziColors.white,
      padding: const EdgeInsets.only(top: 20, bottom: 20, left: 20),
      child: RowContainer(
        gap: 4,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IziText.body(
                      color: IziColors.dark,
                      text: item.nombre,
                      maxLines: 10,
                      fontWeight: FontWeight.w600),
                  ...item.modificadores.map(
                    (e) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: e.caracteristicas
                            .where((element) => element.check)
                            .map((c) {
                          return IziText.bodySmall(
                              color: IziColors.darkGrey,
                              text:
                                  "${c.nombre}${c.modPrecio > 0 ? " (+${c.modPrecio})" : ""}",
                              fontWeight: FontWeight.w400);
                        }).toList(),
                      );
                    },
                  ).toList()
                ],
              )),
          /*Expanded(
              flex: 2,
              child: InkWell(
                radius: 10,
                onTap: () {
                },
                child: const Icon(IziIcons.plusRound,
                    size: 22, color: IziColors.darkGrey),
              )),*/
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IziInput(
                  autoSelect: true,
                  textAlign: TextAlign.center,
                  controller: controller,
                  inputHintText: "0",
                  inputType: InputType.incremental,
                  minValue: 1,
                  maxValue: 999999999,
                  inputSize: InputSize.small,
                  value: item.cantidad.toString(),
                  onChanged: (value, valueRaw) {
                    item.cantidad = num.tryParse(value) ?? 1;
                    context.read<MakeOrderBloc>().reloadItems();
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IziText.bodyBig(
                        color: IziColors.grey,
                        text: LocaleKeys.makeOrder_labels_price.tr(),
                        fontWeight: FontWeight.w400),
                    const SizedBox(width: 5),
                    IziText.body(
                        textAlign: TextAlign.center,
                        color: IziColors.darkGrey,
                        text: (item.precioModificadores +
                                item.cantidad * item.precioUnitario)
                            .moneyFormat(),
                        fontWeight: FontWeight.w500),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            radius: 20,
            onTap: () {
              context
                  .read<MakeOrderBloc>()
                  .removeItem(indexCategory, indexItem);
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Icon(
                IziIcons.close,
                size: 20,
                color: IziColors.grey,
              ),
            ),
          ),
          const SizedBox(
            width: 8,
          )
        ],
      ),
    );
  }

  _item(Item item, TextEditingController? controller, int indexCategory,
      int indexItem, ResponsiveUtils ru) {
    return Container(
      color: IziColors.white,
      padding: const EdgeInsets.only(top: 11, bottom: 11, left: 20),
      child: RowContainer(
        gap: 4,
        children: [
          Expanded(
            flex: ru.isSm() ? 3 : 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: IziInput(
                autoSelect: true,
                textAlign: TextAlign.center,
                controller: controller,
                inputHintText: "0",
                minValue: 1,
                maxValue: 999999999,
                inputType: ru.isSm() ? InputType.incremental : InputType.number,
                inputSize: ru.isSm() ? InputSize.small : InputSize.extraSmall,
                value: item.cantidad.toString(),
                onChanged: (value, valueRaw) {
                  var valueNum = num.tryParse(value) ?? 1;
                  item.cantidad = valueNum > 0 ? valueNum : 1;
                  context.read<MakeOrderBloc>().reloadItems();
                },
              ),
            ),
          ),
          Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IziText.body(
                      color: IziColors.dark,
                      text: item.nombre,
                      maxLines: 10,
                      fontWeight: FontWeight.w600),
                  ...item.modificadores.map(
                    (e) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: e.caracteristicas
                            .where((element) => element.check)
                            .map((c) {
                          return IziText.bodySmall(
                              color: IziColors.darkGrey,
                              text:
                                  "${c.nombre}${c.modPrecio > 0 ? " (+${c.modPrecio})" : ""}",
                              fontWeight: FontWeight.w400);
                        }).toList(),
                      );
                    },
                  ).toList()
                ],
              )),
          /*Expanded(
              flex: 2,
              child: InkWell(
                radius: 10,
                onTap: () {
                },
                child: const Icon(IziIcons.plusRound,
                    size: 22, color: IziColors.darkGrey),
              )),*/
          Expanded(
            flex: 3,
            child: IziText.body(
                textAlign: TextAlign.center,
                color: IziColors.darkGrey,
                text: (item.precioModificadores +
                        item.cantidad * item.precioUnitario)
                    .toStringAsFixed(2),
                fontWeight: FontWeight.w500),
          ),
          InkWell(
            radius: 20,
            onTap: () {
              context
                  .read<MakeOrderBloc>()
                  .removeItem(indexCategory, indexItem);
            },
            child: const Icon(
              IziIcons.close,
              size: 20,
              color: IziColors.grey,
            ),
          ),
          const SizedBox(
            width: 8,
          )
        ],
      ),
    );
  }

  _listItems(ResponsiveUtils ru) {
    var cIndex = -1;
    return IziScroll(
      scrollController: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.state.itemsSelected.asMap().entries.map((e) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: IziColors.grey25,
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
                  child: e.value.nombre.isEmpty || e.value.id == null
                      ? null
                      : IziText.bodySmall(
                          color: IziColors.darkGrey85,
                          text: e.value.nombre,
                          fontWeight: FontWeight.w500),
                ),
                ...e.value.items.asMap().entries.map(
                  (i) {
                    cIndex++;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ru.isXs()
                            ? _itemSm(
                                i.value,
                                cIndex < controllers.length - 1
                                    ? controllers[cIndex]
                                    : null,
                                e.key,
                                i.key)
                            : _item(
                                i.value,
                                cIndex < controllers.length - 1
                                    ? controllers[cIndex]
                                    : null,
                                e.key,
                                i.key,
                                ru),
                        if (i.key < e.value.items.length)
                          const Divider(
                            color: IziColors.grey25,
                            height: 1,
                          ),
                      ],
                    );
                  },
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getTableName() {
    String name = "-";
    for (var table in widget.state.tables) {
      if (table.id == widget.state.tableId) {
        name = table.nombre;
      }
    }
    return name;
  }

  _header() {
    return Container(
      color: IziColors.white,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IziText.title(
              color: IziColors.darkGrey, text: widget.state.order?.id!=null?LocaleKeys.makeOrder_subtitles_orderNumber.tr(args: [widget.state.order!.numero.toString()]):LocaleKeys.makeOrder_title.tr()),
          Row(
            children: [
              MakeOrderChip(
                  icon: IziIcons.restTable,
                  text: _getTableName(),
                  onPressed: () {
                    CustomAlerts.defaultAlert(
                            padding: EdgeInsets.zero,
                            dismissible: true,
                            context: context,
                            child: MakeOrderEditTableModal(
                                tables: widget.state.tables,
                                tableSelect: widget.state.tableId))
                        .then((value) {
                      if (value is String) {
                        context.read<MakeOrderBloc>().changeTableId(value);
                      }
                    });
                  }),
              const SizedBox(
                width: 8,
              ),
              MakeOrderChip(
                  icon: IziIcons.user,
                  text: widget.state.numberDiners != null
                      ? widget.state.numberDiners.toString()
                      : "-",
                  onPressed: () {
                    CustomAlerts.defaultAlert(
                            padding: EdgeInsets.zero,
                            dismissible: true,
                            context: context,
                            child: NumberDinersModal(diners: widget.state.numberDiners,))
                        .then((value) {
                      if (value is int) {
                        context.read<MakeOrderBloc>().changeNumberDiners(value);
                      }
                    });
                  }),
            ],
          )
        ],
      ),
    );
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
