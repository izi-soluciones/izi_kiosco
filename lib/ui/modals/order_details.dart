import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_list_item_status.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/order_list/order_list_bloc.dart';
import 'package:izi_kiosco/domain/blocs/tables/tables_bloc.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/domain/utils/download_utils.dart';
import 'package:izi_kiosco/ui/modals/warning_modal.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/domain/utils/date_formatter.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class OrderDetails extends StatefulWidget {
  final Comanda order;
  final ConsumptionPoint? consumptionPoint;
  final bool fromTables;
  const OrderDetails(
      {super.key,
      this.fromTables = false,
      required this.order,
      this.consumptionPoint});

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  bool waitDownload = false;
  bool waitMore = false;
  String? currency;
  @override
  void initState() {
    AuthState authState=context.read<AuthBloc>().state;
    var indexCurrency = authState.currencies.indexWhere((element) => element.id==authState.currentContribuyente?.config?["monedaInventario"]);
    if(indexCurrency!=-1){
      currency=authState.currencies[indexCurrency].simbolo;
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(context),
        const Divider(
          color: IziColors.grey25,
          height: 1,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _content(context),
                _detail(context),
                _totals(),
                _buttons(context)
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buttons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: ColumnContainer(
        gap: 16,
        children: [
          if (widget.order.facturada != 1 &&
              widget.order.anulada != 1 &&
              !widget.order.consumoInterno)
            IziBtn(
                buttonText: LocaleKeys.orderDetails_buttons_pay.tr(),
                buttonType: ButtonType.secondary,
                buttonSize: ButtonSize.medium,
                buttonOnPressed: () {
                  Navigator.pop(context);
                  GoRouter.of(context).pushNamed(RoutesKeys.payment,
                      extra: widget.order,
                      pathParameters: {"id": widget.order.id.toString()});
                }),
          IziBtn(
              buttonText: LocaleKeys.orderDetails_buttons_print.tr(),
              buttonType: ButtonType.primary,
              buttonSize: ButtonSize.medium,
              dropDown: true,
              loading: waitDownload,
              selectOptions: {
                for (var v in (widget.order.comandasPdf).asMap().entries)
                  v.key: LocaleKeys.orderList_buttons_orderNumberDetail
                      .tr(args: [(v.key + 1).toString()]),
                if (widget.order.facturada == 1)
                  "detail": LocaleKeys.orderList_buttons_detail.tr()
              },
              onSelected: (value) async {
                if (value == "detail") {
                  String? pdf = widget.order.detallePdf;
                  if (pdf != null) {
                    setState(() {
                      waitDownload = true;
                    });
                    await DownloadUtils().downloadFilePdf(pdf);
                    setState(() {
                      waitDownload = false;
                    });
                  }
                  return;
                }
                String? pdf = widget.order.comandasPdf[value].pdf;
                if (pdf != null) {
                  setState(() {
                    waitDownload = true;
                  });
                  await DownloadUtils().downloadFilePdf(pdf);
                  setState(() {
                    waitDownload = false;
                  });
                }
              },
              buttonOnPressed: () async {
                if (widget.order.facturada != 1) {
                  String? pdf = widget.order.detallePdf;
                  if (pdf != null) {
                    setState(() {
                      waitDownload = true;
                    });
                    await DownloadUtils().downloadFilePdf(pdf);
                    setState(() {
                      waitDownload = false;
                    });
                    return;
                  }
                }
                if (widget.order.facturada == 1) {
                  String? pdf = widget.order.pdfRollo;
                  if (pdf != null) {
                    setState(() {
                      waitDownload = true;
                    });
                    await DownloadUtils().downloadFilePdf(pdf);
                    setState(() {
                      waitDownload = false;
                    });
                    return;
                  }
                }
              }),
          if (widget.order.facturada != 1 &&
              widget.order.anulada != 1 &&
              !widget.order.consumoInterno)
            IziBtn(
                buttonText: LocaleKeys.orderDetails_buttons_more.tr(),
                buttonType: ButtonType.terciary,
                buttonSize: ButtonSize.medium,
                dropDown: true,
                dropComplete: true,
                loading: waitMore,
                selectOptions: {
                  1: LocaleKeys.orderDetails_buttons_modifyOrder.tr(),
                  2: LocaleKeys.orderDetails_buttons_markAsInternal.tr(),
                  3: LocaleKeys.orderDetails_buttons_cancel.tr()
                },
                onSelected: (value) async {
                  switch (value) {
                    case 1:
                      Navigator.pop(context);
                      _modifyOrder(context);
                      break;
                    case 2:
                      CustomAlerts.defaultAlert(
                          context: context,
                          child: WarningModal(

                            onAccept: () async {
                              if(widget.fromTables){
                                await context
                                    .read<TablesBloc>()
                                    .markInternal(widget.order,widget.consumptionPoint?.id)
                                    .then((value) => Navigator.pop(context));
                              }
                              else{

                                await context
                                    .read<OrderListBloc>()
                                    .markInternal(widget.order)
                                    .then((value) => Navigator.pop(context));
                              }
                            },
                            title: LocaleKeys
                                .orderDetails_subtitles_areYouSureCancel
                                .tr(),
                          ),
                          dismissible: false);
                      break;
                    case 3:
                      CustomAlerts.defaultAlert(
                          context: context,
                          child: WarningModal(

                            onAccept: () async {
                              if(widget.fromTables){

                                await context
                                    .read<TablesBloc>()
                                    .cancelOrder(widget.order.id,
                                    widget.consumptionPoint?.id)
                                    .then((value) => Navigator.pop(context));
                              }
                              else{

                                await context
                                    .read<OrderListBloc>()
                                    .cancelOrder(widget.order.id)
                                    .then((value) => Navigator.pop(context));
                              }
                            },
                            title: LocaleKeys
                                .orderDetails_subtitles_areYouSureCancel
                                .tr(),
                          ),
                          dismissible: false);
                      break;
                  }
                },
                buttonOnPressed: () {})
        ],
      ),
    );
  }
  _modifyOrder(
      BuildContext context) {
        GoRouter.of(context).goNamed(RoutesKeys.makeOrder, extra: {
          "fromTables": true,
          "order": widget.order
        });
  }

  Widget _detail(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IziText.titleSmall(
              color: IziColors.dark,
              text: LocaleKeys.orderDetails_subtitles_detail.tr()),
          const SizedBox(
            height: 16,
          ),
          Container(
            color: IziColors.lightGrey,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: IziText.bodySmall(
                      color: IziColors.grey,
                      text: LocaleKeys.orderDetails_labels_quantity.tr(),
                      fontWeight: FontWeight.w500),
                ),
                Expanded(
                  flex: 2,
                  child: IziText.bodySmall(
                      color: IziColors.grey,
                      text: LocaleKeys.orderDetails_labels_item.tr(),
                      fontWeight: FontWeight.w500),
                ),
                Expanded(
                  flex: 1,
                  child: IziText.bodySmall(
                      color: IziColors.grey,
                      textAlign: TextAlign.center,
                      text: LocaleKeys.orderDetails_labels_price.tr(),
                      fontWeight: FontWeight.w500),
                ),
                Expanded(
                  flex: 1,
                  child: IziText.bodySmall(
                      color: IziColors.grey,
                      textAlign: TextAlign.right,
                      text: LocaleKeys.orderDetails_labels_total.tr(),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          ...widget.order.listaItems.asMap().entries.map((entry) {
            final e = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: entry.key == widget.order.listaItems.length - 1
                  ? null
                  : const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: IziColors.grey25))),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: IziText.body(
                        color: IziColors.darkGrey,
                        text: (e.cantidad ?? 0).toString(),
                        fontWeight: FontWeight.w400),
                  ),
                  Expanded(
                    flex: 2,
                    child: IziText.body(
                        color: IziColors.dark,
                        text: e.nombre,
                        fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    flex: 1,
                    child: IziText.body(
                        color: IziColors.darkGrey,
                        textAlign: TextAlign.center,
                        text: (e.precioUnitario ?? 0).toString(),
                        fontWeight: FontWeight.w400),
                  ),
                  Expanded(
                    flex: 1,
                    child: IziText.body(
                        color: IziColors.dark,
                        textAlign: TextAlign.right,
                        text: (e.precioTotal ?? 0).toString(),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }).toList()
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: ColumnContainer(
        gap: 12,
        children: [
          _detailsItem(context, LocaleKeys.orderDetails_body_orderNumber.tr(),
              (widget.order.numero ?? 0).toString()),
          _detailsItem(context, LocaleKeys.orderDetails_body_orderDate.tr(),
              widget.order.fecha.dateFormat(DateFormatterType.visual)),
          _detailsItem(context, LocaleKeys.orderDetails_body_orderHour.tr(),
              widget.order.fecha.dateFormat(DateFormatterType.hour)),
          _detailsItem(
              context,
              LocaleKeys.orderDetails_body_additionalNotes.tr(),
              widget.order.notaInterna ?? "---"),
        ],
      ),
    );
  }



  Widget _totals(){
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 4, 32, 32),
      child: ColumnContainer(
        gap: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IziText.body(color: IziColors.grey, text: LocaleKeys.orderDetails_body_subtotal.tr(), fontWeight: FontWeight.w400),
              IziText.body(color: IziColors.darkGrey, text: widget.order.monto.moneyFormat(currency: currency), fontWeight: FontWeight.w400)
            ],
          ),
          if(widget.order.descuentos>0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IziText.body(color: IziColors.grey, text: LocaleKeys.orderDetails_body_discounts.tr(), fontWeight: FontWeight.w400),
              IziText.body(color: IziColors.darkGrey, text: widget.order.descuentos.moneyFormat(currency: currency), fontWeight: FontWeight.w400)
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IziText.bodyBig(color: IziColors.dark, text: LocaleKeys.orderDetails_body_total.tr(), fontWeight: FontWeight.w600),
              IziText.bodyBig(color: IziColors.darkGrey, text: (widget.order.monto-widget.order.descuentos).moneyFormat(currency: currency), fontWeight: FontWeight.w600)
            ],
          )
        ],
      ),
    );
  }

  Widget _detailsItem(BuildContext context, String label, String text) {
    return Row(
      children: [
        Expanded(
          child: IziText.body(
              color: IziColors.grey, text: label, fontWeight: FontWeight.w400),
        ),
        IziText.body(
            color: IziColors.darkGrey, text: text, fontWeight: FontWeight.w400),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 25, top: 16, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IziText.title(
                    color: IziColors.darkGrey,
                    text: LocaleKeys.orderDetails_subtitles_orderNumber
                        .tr(args: [(widget.order.numero ?? 0).toString()])),
                Row(
                  children: [
                    if (!ru.isXXs())
                      IziText.body(
                          color: IziColors.grey,
                          text: widget.consumptionPoint?.nombre ??
                              LocaleKeys.orderDetails_subtitles_prePayment.tr(),
                          fontWeight: FontWeight.w600),
                    if (!ru.isXXs())
                      const SizedBox(
                          height: 15,
                          child: VerticalDivider(
                              width: 16, color: IziColors.grey25)),
                    IziListItemStatus(
                        adaptable: true,
                        listItemType: widget.order.anulada == 1
                            ? ListItemType.anulled
                            : widget.order.consumoInterno
                                ? ListItemType.primary
                                : widget.order.facturada == 1
                                    ? ListItemType.secondary
                                    : ListItemType.warning,
                        listItemText: widget.order.anulada == 1
                            ? LocaleKeys.orderDetails_body_annulled.tr()
                            : widget.order.consumoInterno
                                ? LocaleKeys.orderDetails_body_internal.tr()
                                : widget.order.facturada == 1
                                    ? LocaleKeys.orderDetails_body_invoiced.tr()
                                    : LocaleKeys.orderDetails_body_noInvoiced
                                        .tr(),
                        listItemSize: ListItemSize.big)
                  ],
                )
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(
              IziIcons.close,
              size: 31,
            ),
          )
        ],
      ),
    );
  }
}
