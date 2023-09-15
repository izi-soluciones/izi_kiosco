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
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_header.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class PaymentPageCard extends StatelessWidget {
  final PaymentState state;
  const PaymentPageCard({super.key,required this.state});

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
            popText: ru.gtXs() ? LocaleKeys.payment_titles_card.tr() : null,
            amount: (state.order?.monto ?? 0) - state.discountAmount),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: ru.gtXs()?20:0),
                      child:_card(ru),
                    ),
                    const SizedBox(height: 20,),
                    _form(context,ru)
                  ],
                )
            ),
          ),
        )
      ],
    );
  }

  _card(ResponsiveUtils ru){
    return IziCard(
      padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            IziText.titleSmall(color: IziColors.darkGrey, text: LocaleKeys.payment_labels_cardDetails.tr()),
            const Icon(IziIcons.cardBack,color: IziColors.yellow,size: 50,),
            Row(
              children: [
                Flexible(child: Text(state.firstDigits.value.isNotEmpty?state.firstDigits.value.padRight(4,"_"):"____",style: TextStyle(color: IziColors.dark,fontSize: ru.isXXs()?15:28,fontWeight: FontWeight.w400))),
                Text(" XXXX XXX ",style: TextStyle(color: IziColors.darkGrey85,fontSize: ru.isXXs()?15:28,fontWeight: FontWeight.w400)),
                Flexible(child: Text(state.lastDigits.value.isNotEmpty?state.lastDigits.value.padRight(4,"_"):"____",style: TextStyle(color: IziColors.dark,fontSize: ru.isXXs()?15:28,fontWeight: FontWeight.w400))),
              ],
            ),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IziText.body(color: IziColors.grey, text: "MM/YY",fontWeight: FontWeight.w500),
              ],
            )
          ],
        )
    );
  }

  _form(BuildContext context,ResponsiveUtils ru){
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IziText.label(
            color: IziColors.darkGrey,
            text: LocaleKeys.payment_labels_firstAndLast.tr(),
            fontWeight: FontWeight.w500
        ),
        const SizedBox(height: 4,),
        RowContainer(
          gap: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: IziInput(
                  inputHintText: "XXXX",
                  inputType: InputType.normal,
                inputMaxLength: 4,
                value: state.firstDigits.value,
                onEditingComplete: (){
                    context.read<PaymentBloc>().validateInput(firstDigits: true);
                },
                error: _firstDigitsError(state.firstDigits.inputError),
                onChanged: (value,valueRaw){
                  context.read<PaymentBloc>().changeInputs(firstDigits: value);
                },
              ),
            ),
            if(ru.gtXxs())
            Flexible(
              child: IziInput(
                inputHintText: "XXXX",
                inputType: InputType.normal,
                inputMaxLength: 4,
                value: state.lastDigits.value,
                onEditingComplete: (){
                  context.read<PaymentBloc>().validateInput(lastDigits: true);
                },
                error: _lastDigitsError(state.lastDigits.inputError),
                onChanged: (value,valueRaw){
                  context.read<PaymentBloc>().changeInputs(lastDigits: value);
                },
              ),
            )
          ],
        ),
        if(ru.isXXs())
        const SizedBox(height: 8,),
        if(ru.isXXs())
        IziInput(
          inputHintText: "XXXX",
          inputType: InputType.normal,
          value: state.lastDigits.value,
          onChanged: (value,valueRaw){
            context.read<PaymentBloc>().changeInputs(lastDigits: value);
          },
          error: _lastDigitsError(state.lastDigits.inputError),
          inputMaxLength: 4,
        ),
        const SizedBox(height: 50,),
        IziBtn(
            buttonText: LocaleKeys.payment_buttons_payAndGenerate.tr(),
            buttonType: ButtonType.secondary,
            buttonSize: ru.isXs()?ButtonSize.medium:ButtonSize.large,
            buttonOnPressed:(){
              context.read<PaymentBloc>().submitCard();
            }
        ),
        const SizedBox(height: 100,),
        IziBtn(
            buttonText: LocaleKeys.payment_buttons_changePaymentMethod.tr(),
            buttonType: ButtonType.outline,
            buttonSize: ButtonSize.medium,
            buttonOnPressed: (){
              context.read<PaymentBloc>().backReset();
            }
        )
      ],
    );
  }

  String? _firstDigitsError(InputError? error){
    switch(error){
      case InputError.required:
        return LocaleKeys.payment_inputs_firstDigits_errors_required.tr();
      case InputError.invalid:
        return LocaleKeys.payment_inputs_firstDigits_errors_invalid.tr();
      default:
        return null;
    }
  }

  String? _lastDigitsError(InputError? error){
    switch(error){
      case InputError.required:
        return LocaleKeys.payment_inputs_lastDigits_errors_required.tr();
      case InputError.invalid:
        return LocaleKeys.payment_inputs_lastDigits_errors_invalid.tr();
      default:
        return null;
    }
  }
}
