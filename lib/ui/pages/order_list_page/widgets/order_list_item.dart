import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_list_item_status.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/order_list/order_list_bloc.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/domain/utils/download_utils.dart';
import 'package:izi_kiosco/ui/modals/order_details.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/domain/utils/date_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class OrderListItem extends StatelessWidget {
  final Comanda order;
  final OrderListState state;
  const OrderListItem({super.key,required this.order,required this.state});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return InkWell(
      onTap: (){
        CustomAlerts.alertRight(content: OrderDetails(order: order), context: context);
      },
      child: IziCard(
        padding: EdgeInsets.symmetric(horizontal: ru.isXs()?16:30,vertical: 20),
          child: Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            direction: ru.isXs()?Axis.vertical:Axis.horizontal,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: ru.isXs()?FlexFit.loose:FlexFit.tight,
                child: ColumnContainer(
                  gap:5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RowContainer(
                      gap: 8,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: IziText.titleSmall(color: IziColors.dark, text: LocaleKeys.orderList_body_orderNumber.tr(args: [(order.numero ?? 0).toString()] ))),
                        IziListItemStatus(
                            listItemType:
                            order.anulada == 1?ListItemType.anulled:
                                order.consumoInterno?ListItemType.primary:
                            order.facturada == 1?ListItemType.secondary:
                            ListItemType.warning,
                            listItemText: "",
                            listItemSize: ListItemSize.small
                        )
                      ],
                    ),
                    RowContainer(
                        gap: 10,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IziText.bodySmall(color: IziColors.grey, text: LocaleKeys.orderList_body_orderHour.tr(), fontWeight: FontWeight.w500),
                                const SizedBox(height: 1,),
                                IziText.body(color: IziColors.darkGrey, text: order.fecha.dateFormat(DateFormatterType.dateHour), fontWeight: FontWeight.w400),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IziText.bodySmall(color: IziColors.grey, text: LocaleKeys.orderList_body_orderType.tr(), fontWeight: FontWeight.w500),
                                const SizedBox(height: 1,),
                                IziText.body(color: IziColors.darkGrey, text: _getOrderType(state.consumptionPoints, order), fontWeight: FontWeight.w400),
                              ],
                            ),
                          ),
                          if(ru.gtSm())
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IziText.bodySmall(color: IziColors.grey, text: LocaleKeys.orderList_body_orderDetail.tr(), fontWeight: FontWeight.w500),
                                const SizedBox(height: 1,),
                                IziText.body(color: IziColors.darkGrey, text: order.listaItems.fold("", (previousValue, element) => previousValue==""?element.nombre:"$previousValue, ${element.nombre}"), fontWeight: FontWeight.w400),
                              ],
                            ),
                          )
                        ]
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: ru.gtXs()?0:20,left: ru.isXs()?0:20),
                child: IziBtn(
                    buttonText: LocaleKeys.orderList_buttons_print.tr(),
                    buttonType: ButtonType.outline,
                    buttonSize: ButtonSize.medium,
                    dropDown: true,
                    selectOptions: {
                      for (var v in (order.comandasPdf).asMap().entries) v.key : LocaleKeys.orderList_buttons_orderNumberDetail.tr(args: [(v.key+1).toString()]),
                      if(order.facturada==1)
                        "detail": LocaleKeys.orderList_buttons_detail.tr()
                    },
                    onSelected: (value){
                      if(value=="detail"){
                        String? pdf = order.detallePdf;
                        if(pdf!=null){
                          DownloadUtils().downloadFilePdf(pdf);
                        }
                        return;
                      }
                      String? pdf = order.comandasPdf[value].pdf;
                      if(pdf!=null){
                        DownloadUtils().downloadFilePdf(pdf);
                      }
                    },
                    buttonOnPressed: (){
                      if(order.facturada!=1){
                        String? pdf = order.detallePdf;
                        if(pdf!=null){
                          DownloadUtils().downloadFilePdf(pdf);
                          return;
                        }
                      }
                      if(order.facturada==1){
                        String? pdf = order.pdfRollo;
                        if(pdf!=null){
                          DownloadUtils().downloadFilePdf(pdf);
                          return;
                        }
                      }
                    }
                ),
              )
            ],
          )
      ),
    );
  }

  _getOrderType(List<ConsumptionPoint> list,Comanda comanda){
    String name=LocaleKeys.orderList_body_prePayment.tr();
    for(ConsumptionPoint pc in list){
      if(pc.id == comanda.mesa){
        name = pc.nombre;
      }
    }
    return name;
  }
}
