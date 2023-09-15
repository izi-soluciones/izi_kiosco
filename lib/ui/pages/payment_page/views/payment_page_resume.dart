import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/general/headers/back_mobile_header.dart';
import 'package:izi_kiosco/ui/pages/payment_page/modals/payment_percentage_amount.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class PaymentPageResume extends StatelessWidget {
  final PaymentState state;
  final AuthState authState;
  const PaymentPageResume({super.key, required this.state,required this.authState});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return IziCard(
      radiusBottom: false,
      radiusTop: false,
      child: Column(
        children: [
          BackMobileHeader(
            background: IziColors.white,
            title: IziText.title(
                color: IziColors.darkGrey,
                text: LocaleKeys.payment_titles_resume.tr()),
            onBack: () {
              if(GoRouter.of(context).canPop()){
                GoRouter.of(context).pop();
              }else{
                GoRouter.of(context).goNamed(RoutesKeys.order);
              }
            },
          ),
          const Divider(
            color: IziColors.grey25,
            height: 1,
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, layout) {
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IziText.titleExtraSmall(
                        color: IziColors.darkGrey85,
                        text: LocaleKeys.payment_body_detail.tr()),
                    const SizedBox(
                      height: 10,
                    ),
                    _detailItems(context),
                    const SizedBox(
                      height: 40,
                    ),
                    _resumeTotal(context)
                  ],
                ),
              );
            }),
          ),
          if (ru.lwSm())
            IziCard(
              radiusTop: false,
              radiusBottom: false,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: IziBtn(
                  buttonText: LocaleKeys.payment_buttons_pay.tr(),
                  buttonType: ButtonType.secondary,
                  buttonSize: ButtonSize.medium,
                  buttonOnPressed: () {
                    context.read<PaymentBloc>().changeStep(1);
                  }),
            )
        ],
      ),
    );
  }

  Widget _resumeTotal(BuildContext context) {
    return ColumnContainer(
      gap: 16,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IziText.body(
                color: IziColors.darkGrey,
                text: LocaleKeys.payment_body_subtotal.tr(),
                fontWeight: FontWeight.w500),
            IziText.body(
                color: IziColors.darkGrey,
                text:
                    (state.order?.monto ?? 0).moneyFormat(currency: state.currentCurrency?.simbolo??AppConstants.defaultCurrency),
                fontWeight: FontWeight.w500),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IziText.body(
                color: IziColors.darkGrey,
                text: LocaleKeys.payment_body_discount.tr(),
                fontWeight: FontWeight.w500),
              InkWell(
                onTapDown: (details) {
                  CustomAlerts.alertWithPositionWidget(
                      details.globalPosition,
                      context,
                      PaymentPercentageAmount(
                          title: LocaleKeys.payment_body_discount.tr(),
                          amount: (state.order?.monto ?? 0),
                          currentValue: state.discountAmount != 0
                              ? state.discountAmount
                              : null,
                          buttonText: LocaleKeys.payment_buttons_addDiscount
                              .tr()), (value) {
                    if (value is num && value != 0) {
                      context
                          .read<PaymentBloc>()
                          .changeDiscountTip(discount: value);
                    }
                  });
                },

                child: state.discountAmount == 0
                    ? const Icon(
                  IziIcons.plusRound,
                  size: 18,
                  color: IziColors.darkGrey,
                )
                    :
                RowContainer(
                  gap: 8,
                  children: [
                    const Icon(
                      IziIcons.edit,
                      color: IziColors.primary,
                      size: 16,
                    ),
                    IziText.body(
                        color: IziColors.darkGrey,
                        text: state.discountAmount.moneyFormat(currency: state.currentCurrency?.simbolo??AppConstants.defaultCurrency),
                        fontWeight: FontWeight.w500)
                  ],
                ),
              )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IziText.body(
                color: IziColors.darkGrey,
                text: LocaleKeys.payment_body_tip.tr(),
                fontWeight: FontWeight.w500),
              InkWell(
                onTapDown: (details) {
                  CustomAlerts.alertWithPositionWidget(
                    details.globalPosition,
                    context,
                    PaymentPercentageAmount(
                      title: LocaleKeys.payment_body_tipShort.tr(),
                      amount:
                          (state.order?.monto ?? 0) - state.discountAmount,
                      currentValue:
                          state.tipAmount != 0 ? state.tipAmount : null,
                      buttonText: LocaleKeys.payment_buttons_addTip.tr(),
                    ),
                    (value) {
                      if (value is num && value != 0) {
                        context
                            .read<PaymentBloc>()
                            .changeDiscountTip(tip: value);
                      }
                    },
                  );
                },
                child: state.tipAmount == 0
                    ? const Icon(
                        IziIcons.plusRound,
                        size: 18,
                        color: IziColors.darkGrey,
                      )
                    : RowContainer(
                        gap: 8,
                        children: [
                          const Icon(
                            IziIcons.edit,
                            color: IziColors.primary,
                            size: 16,
                          ),
                          IziText.body(
                              color: IziColors.darkGrey,
                              text: state.tipAmount.moneyFormat(currency: state.currentCurrency?.simbolo??AppConstants.defaultCurrency),
                              fontWeight: FontWeight.w500)
                        ],
                      ),
              )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IziText.bodyBig(
                color: IziColors.darkGrey,
                text: LocaleKeys.payment_body_total.tr(),
                fontWeight: FontWeight.w600),
            IziText.bodyBig(
                color: IziColors.darkGrey,
                text: ((state.order?.monto ?? 0) - state.discountAmount)
                    .moneyFormat(currency: state.currentCurrency?.simbolo??AppConstants.defaultCurrency),
                fontWeight: FontWeight.w600),
          ],
        ),
      ],
    );
  }



  Widget _detailItems(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: const BoxDecoration(
              color: IziColors.lightGrey,
              border: Border(
                  bottom: BorderSide(color: IziColors.grey25, width: 1))),
          child: RowContainer(
            gap: 6,
            children: [
              Expanded(
                flex: 2,
                child: IziText.bodySmall(
                    color: IziColors.grey,
                    textAlign: TextAlign.center,
                    text: LocaleKeys.payment_labels_amount.tr(),
                    fontWeight: FontWeight.w500),
              ),
              Expanded(
                flex: 7,
                child: IziText.bodySmall(
                    color: IziColors.grey,
                    text: LocaleKeys.payment_labels_item.tr(),
                    fontWeight: FontWeight.w500),
              ),
              Expanded(
                flex: 3,
                child: IziText.bodySmall(
                    color: IziColors.grey,
                    textAlign: TextAlign.center,
                    text: LocaleKeys.payment_labels_price.tr(),
                    fontWeight: FontWeight.w500),
              ),
              Expanded(
                flex: 3,
                child: IziText.bodySmall(
                    color: IziColors.grey,
                    textAlign: TextAlign.right,
                    text: LocaleKeys.payment_labels_total.tr(),
                    fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
        ...(state.order?.listaItems ?? []).map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: IziColors.grey25, width: 1))),
            child: RowContainer(
              gap: 6,
              children: [
                Expanded(
                  flex: 2,
                  child: IziText.body(
                      color: IziColors.darkGrey,
                      textAlign: TextAlign.center,
                      text: "x${e.cantidad ?? 0}",
                      fontWeight: FontWeight.w400),
                ),
                Expanded(
                  flex: 7,
                  child: IziText.body(
                      color: IziColors.dark,
                      text: e.nombre,
                      fontWeight: FontWeight.w500),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                          child: IziText.body(
                              color: IziColors.darkGrey,
                              text: (e.precioUnitario ?? 0).toString(),
                              fontWeight: FontWeight.w400)),
                      if ((e.precioModificadores ?? 0) > 0)
                        Flexible(
                            child: IziText.labelSmall(
                                color: IziColors.darkGrey,
                                text:
                                    " + (${(e.precioModificadores ?? 0).toString()}) ",
                                fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: IziText.body(
                      color: IziColors.dark,
                      textAlign: TextAlign.end,
                      text: (e.precioTotal ?? 0).toString(),
                      fontWeight: FontWeight.w500),
                )
              ],
            ),
          );
        }).toList()
      ],
    );
  }
}
