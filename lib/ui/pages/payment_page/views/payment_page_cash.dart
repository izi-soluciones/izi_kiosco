import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_header.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class PaymentPageCash extends StatelessWidget {
  final PaymentState state;

  const PaymentPageCash({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Column(
      children: [
        PaymentHeader(
            onPop: () {
              context.read<PaymentBloc>().backReset();
            },
            currency:
                state.currentCurrency?.simbolo ?? AppConstants.defaultCurrency,
            popText: ru.gtXs() ? LocaleKeys.payment_titles_cash.tr() : null,
            amount: (state.order?.monto ?? 0) - state.discountAmount),
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


  List<num> _getAmountsCash(num cash){
    var amounts=[((cash / 10).ceil() * 10)];
    var e20=(amounts[0]/20).ceil()*20;
    var e50=(amounts[0]/50).ceil()*50;
    if(e20!=amounts[0]){
      amounts.add(e20);
    }
    if(e50!=amounts[0]&&e20!=e50){
      amounts.add(e50);
    }
    return amounts;
  }

  Widget _paymentCash(BuildContext context, ResponsiveUtils ru) {
    List<num> amounts = _getAmountsCash((state.order?.monto??0)-state.discountAmount);

    return Column(
      children: [
        IziInput(
          labelInput: LocaleKeys.payment_inputs_amountReceived_label.tr(),
          bigLabel: ru.gtXs(),
          inputHintText:
              LocaleKeys.payment_inputs_amountReceived_placeholder.tr(),
          inputType: InputType.number,
          value: state.cashAmount>0?state.cashAmount.toStringAsFixed(2):"",
          onChanged: (value, valueRaw) {
            context.read<PaymentBloc>().changeCashAmount(num.tryParse(value)??0);
          },
          inputSize: ru.gtXs() ? InputSize.big : InputSize.normal,
          textAlign: TextAlign.center,
          defaultValues: {
            "${state.order?.monto ?? 0}": LocaleKeys.payment_buttons_cashFull
                .tr(args: [
              state.currentCurrency?.simbolo ?? AppConstants.defaultCurrency,
              (state.order?.monto ?? 0).toStringAsFixed(2)
            ]),
            for(var a in (amounts)) a.toString(): "${state.currentCurrency?.simbolo??AppConstants.defaultCurrency} ${a.toStringAsFixed(2)}",
          }
          ),
        const SizedBox(
          height: 85,
        ),
        IziText.bodyBig(
            color: state.cashAmount>=(state.order?.monto??0)?IziColors.darkGrey:IziColors.grey,
            text: LocaleKeys.payment_body_change.tr(),
            fontWeight: FontWeight.w400),
        IziText.titleBig(color: state.cashAmount>=(state.order?.monto??0)?IziColors.darkGrey:IziColors.grey, text: "${state.currentCurrency?.simbolo??AppConstants.defaultCurrency} ${(state.cashAmount>=(state.order?.monto??0)?state.cashAmount-(state.order?.monto??0):0).toStringAsFixed(2)}"),
        const SizedBox(
          height: 61,
        ),
        IziBtn(
            buttonText: LocaleKeys.payment_buttons_payAndGenerate.tr(),
            buttonType: ButtonType.secondary,

            buttonSize: ru.gtXs() ? ButtonSize.large : ButtonSize.medium,
            buttonOnPressed: state.cashAmount>=(state.order?.monto??0)?() {
              context.read<PaymentBloc>().changeStep(3);
            }:null),
        const SizedBox(
          height: 100,
        ),
        IziBtn(
            buttonText: LocaleKeys.payment_buttons_changePaymentMethod.tr(),
            buttonType: ButtonType.outline,
            buttonSize: ru.gtXs() ? ButtonSize.medium : ButtonSize.small,
            buttonOnPressed: () {
              context.read<PaymentBloc>().backReset();
            }),
      ],
    );
  }
}
