import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/pages/payment_page/modals/payment_type_modal.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_header.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class PaymentPageSplitPayment extends StatefulWidget {
  final PaymentState state;

  const PaymentPageSplitPayment({super.key, required this.state});

  @override
  State<PaymentPageSplitPayment> createState() =>
      _PaymentPageSplitPaymentState();
}

class _PaymentPageSplitPaymentState extends State<PaymentPageSplitPayment> {
  List<TextEditingController> listControllersText = [];
  @override
  void initState() {
    for (var p in widget.state.payments) {
      listControllersText.add(TextEditingController(text: p.monto?.toString()));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Column(
      children: [
        PaymentHeader(
            onPop: () {
              if (widget.state.payments.fold(
                      0,
                      (previousValue, element) =>
                          previousValue + (element.id != null ? 1 : 0)) >
                  0) {
                if(GoRouter.of(context).canPop()){
                  GoRouter.of(context).pop();
                }else{
                  GoRouter.of(context).goNamed(RoutesKeys.order);
                }
                return;
              }
              context.read<PaymentBloc>().backReset();
            },
            currency: widget.state.currentCurrency?.simbolo ??
                AppConstants.defaultCurrency,
            popText: ru.gtXs() ? LocaleKeys.payment_titles_split.tr() : null,
            amount:
                (widget.state.order?.monto ?? 0) - widget.state.discountAmount),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 444,
                ),
                child: _paymentCash(context, ru)),
          ),
        )
      ],
    );
  }

  Widget _paymentCash(BuildContext context, ResponsiveUtils ru) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IziText.titleSmall(
            color: IziColors.darkGrey,
            text: LocaleKeys.payment_subtitles_howDoPayment.tr(),
            mobile: ru.isXs()),
        const SizedBox(
          height: 16,
        ),
        ...widget.state.payments.asMap().entries.map((e) {
          return Column(
            children: [
              RowContainer(
                gap: 16,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: IziInput(
                      labelInput: LocaleKeys.payment_inputs_payment_label
                              .tr(args: [(e.key + 1).toString()]) +
                          (e.value.metodoPago != null
                              ? " (${_getPaymentName(e.value.metodoPago!)})"
                              : ""),
                      bigLabel: ru.gtXs(),
                      controller: listControllersText[e.key],
                      readOnly: e.value.id != null,
                      onChanged: (value, valueRaw) {
                        context
                            .read<PaymentBloc>()
                            .changePaymentAmount(e.key, num.tryParse(value));
                      },
                      inputHintText:
                          LocaleKeys.payment_inputs_payment_placeholder.tr(),
                      inputType: InputType.number,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (e.value.id != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                    color: IziColors.secondary,
                                    borderRadius: BorderRadius.circular(100)),
                                padding:
                                    EdgeInsets.all(e.value.loading ? 8 : 3),
                                child: e.value.loading
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 2, color: IziColors.white)
                                    : const FittedBox(
                                        fit: BoxFit.fill,
                                        child: Icon(
                                          IziIcons.check,
                                          color: IziColors.white,
                                        ),
                                      ),
                              ),
                              if(!e.value.fromCharge)
                              const SizedBox(
                                width: 8,
                              ),
                              if(!e.value.fromCharge)
                              PopupMenuButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                position: PopupMenuPosition.under,
                                itemBuilder: (BuildContext context) {
                                  return [
                                    PopupMenuItem(
                                        value: 1,
                                        height: 30,
                                        child: IziText.body(
                                            color: IziColors.darkGrey,
                                            text: LocaleKeys
                                                .payment_buttons_deletePayment
                                                .tr(),
                                            fontWeight: FontWeight.w500))
                                  ];
                                },
                                child: const Icon(IziIcons.more,
                                    color: IziColors.darkGrey, size: 30),
                                onSelected: (value) async {
                                  var ver = await context
                                      .read<PaymentBloc>()
                                      .removePaymentRemote(e.key);
                                  if (ver) {
                                    listControllersText.removeAt(e.key);
                                    while (listControllersText.length < 2) {
                                      listControllersText
                                          .add(TextEditingController());
                                    }
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                      if (e.key > 1 && e.value.id == null)
                        InkWell(
                          onTap: () {
                            context.read<PaymentBloc>().removePayment(e.key);
                            listControllersText.removeAt(e.key);
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(bottom: 24.0, left: 24),
                            child: Icon(
                              IziIcons.close,
                              size: 25,
                              color: IziColors.darkGrey,
                            ),
                          ),
                        ),
                      if (e.value.id == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: IziBtn(
                              buttonText:
                                  LocaleKeys.payment_buttons_paymentType.tr(),
                              buttonType: ButtonType.secondary,
                              loading: e.value.loading,
                              buttonSize: ButtonSize.small,
                              iconSuffix: IziIcons.rightB,
                              buttonOnPressed: e.value.monto == null ||
                                      e.value.monto == 0 ||
                                      (e.value.monto ?? 0) ==
                                          (widget.state.order?.monto ?? 0) -
                                              widget.state.discountAmount ||
                                      (e.value.monto ?? 0) > _getRemaining()
                                  ? null
                                  : () async {
                                      _alertPayments(e);
                                    }),
                        )
                    ],
                  )
                ],
              ),
              if (e.key < widget.state.payments.length - 1)
                const Divider(
                  color: IziColors.grey35,
                  height: 40,
                ),
            ],
          );
        }).toList(),
        const SizedBox(
          height: 10,
        ),
        if (num.parse(_getRemaining().toStringAsFixed(2)) != 0)
          Row(
            children: [
              IziBtn(
                  buttonText: LocaleKeys.payment_buttons_remaining.tr(args: [
                    widget.state.currentCurrency?.simbolo ?? "Bs",
                    _getRemaining().toStringAsFixed(2)
                  ]),
                  buttonType: ButtonType.outline,
                  buttonSize: ButtonSize.small,
                  expandText: true,
                  buttonOnPressed: () {
                    if (widget.state.payments.last.id == null) {
                      listControllersText[widget.state.payments.length - 1]
                          .text = _getRemaining().toStringAsFixed(2);
                      context.read<PaymentBloc>().changePaymentAmount(
                          listControllersText.length - 1, _getRemaining());
                    }
                  }),
            ],
          ),
        if (num.parse(_getRemaining().toStringAsFixed(2)) != 0)
          const SizedBox(
            height: 40,
          ),
        if (num.parse(_getRemaining().toStringAsFixed(2)) != 0)
          Row(
            children: [
              IziBtn(
                  buttonText: LocaleKeys.payment_buttons_morePayments.tr(),
                  buttonType: ButtonType.primary,
                  icon: IziIcons.plusB,
                  buttonSize: ButtonSize.small,
                  buttonOnPressed: () {
                    context.read<PaymentBloc>().addPayment();
                    listControllersText.add(TextEditingController());
                  }),
            ],
          ),
        const Divider(
          color: IziColors.grey35,
          height: 20,
        ),
        if (num.parse(_getRemaining().toStringAsFixed(2)) != 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IziText.body(
                  color: IziColors.darkGrey85,
                  text: LocaleKeys.payment_body_remaining.tr(),
                  fontWeight: FontWeight.w500),
              IziText.body(
                  color: IziColors.grey,
                  text:
                      "${widget.state.currentCurrency?.simbolo} -${_getRemaining().toStringAsFixed(2)}",
                  fontWeight: FontWeight.w500),
            ],
          ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IziText.body(
                color: IziColors.dark,
                text: LocaleKeys.payment_body_totalSplit.tr(),
                fontWeight: FontWeight.w500),
            IziText.body(
                color: IziColors.dark,
                text:
                    "${widget.state.currentCurrency?.simbolo} ${(widget.state.order?.monto ?? 0).toStringAsFixed(2)}",
                fontWeight: FontWeight.w500),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IziText.title(
                color: IziColors.darkGrey,
                text: LocaleKeys.payment_body_totalPaymentSplit.tr()),
            IziText.title(
                color: IziColors.darkGrey,
                text:
                    "${widget.state.currentCurrency?.simbolo} ${_getTotalPayments().toStringAsFixed(2)}"),
          ],
        ),
        const SizedBox(
          height: 40,
        ),
        IziBtn(
            buttonText: LocaleKeys.payment_buttons_generateInvoice.tr(),
            buttonType: ButtonType.secondary,
            buttonSize: ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
            buttonOnPressed:
                (num.parse(_getRemaining().toStringAsFixed(2)) != 0)
                    ? null
                    : () {
                        if (widget.state.payments.indexWhere((element) =>
                                element.metodoPago ==
                                AppConstants.idPaymentMethodCard) !=
                            -1) {
                          context.read<PaymentBloc>().changeStep(6);
                        } else {
                          context.read<PaymentBloc>().changeStep(3);
                        }
                      }),
        const SizedBox(
          height: 100,
        ),
        if (widget.state.payments.fold(
                0,
                (previousValue, element) =>
                    previousValue + (element.id != null ? 1 : 0)) <=
            0)
          IziBtn(
              buttonText: LocaleKeys.payment_buttons_changePaymentMethod.tr(),
              buttonType: ButtonType.outline,
              buttonSize: ButtonSize.medium,
              buttonOnPressed: () {
                context.read<PaymentBloc>().backReset();
              }),
      ],
    );
  }

  _alertPayments(MapEntry e) {
    CustomAlerts.alertExpanded(
            content:
                PaymentTypeModal(paymentState: widget.state, payment: e.value),
            context: context)
        .then((result) {
      if (result is int) {
        if (result == AppConstants.idPaymentMethodQR &&
            context
                    .read<AuthBloc>()
                    .state
                    .currentContribuyente
                    ?.configCobros?["QHANTUY"]?["appKey"] !=
                null) {
          context.read<PaymentBloc>().generateQrPartial(
              e.value.monto ?? 0, e.key, context.read<AuthBloc>().state);
          return;
        }
        context.read<PageUtilsBloc>().lockPage();
        context
            .read<PaymentBloc>()
            .emitPayment(e.key, result, context.read<AuthBloc>().state);
      }
    });
  }

  num _getTotalPayments() {
    return widget.state.payments.fold(
        0,
        (previousValue, element) =>
            previousValue + (element.id != null ? element.monto ?? 0 : 0));
  }

  String _getPaymentName(int paymentMethod) {
    switch (paymentMethod) {
      case AppConstants.idPaymentMethodCash:
        return LocaleKeys.payment_type_modal_buttons_cash.tr();
      case AppConstants.idPaymentMethodCard:
        return LocaleKeys.payment_type_modal_buttons_card.tr();
      case AppConstants.idPaymentMethodQR:
        return LocaleKeys.payment_type_modal_buttons_qr.tr();
      case AppConstants.idPaymentMethodTransfer:
        return LocaleKeys.payment_type_modal_buttons_transfer.tr();
      case AppConstants.idPaymentMethodGiftCard:
        return LocaleKeys.payment_type_modal_buttons_giftCard.tr();
      default:
        return "";
    }
  }

  num _getRemaining() {
    return (widget.state.order?.monto ?? 0) -
        widget.state.discountAmount -
        widget.state.payments.fold(
            0,
            (previousValue, element) =>
                previousValue + (element.id != null ? element.monto ?? 0 : 0));
  }
}
