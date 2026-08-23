import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/sizes.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:lottie/lottie.dart';

class PaymentPageOrderComplete extends StatelessWidget {
  final PaymentState state;
  const PaymentPageOrderComplete({super.key,required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IziText.titleBig(color: IziColors.darkGrey, text: state.paymentType==PaymentType.cashRegister?LocaleKeys.payment_subtitles_successOrder.tr():LocaleKeys.payment_subtitles_successPayment.tr(),fontWeight: FontWeight.w600),
        Lottie.asset(AssetsKeys.okAnimationJson,width: 250,repeat: false,),
        const SizedBox(height: 8,),
        IziText.titleMedium(maxLines: 2,color: IziColors.darkGrey, text: state.paymentType==PaymentType.cashRegister?LocaleKeys.payment_body_goToCashRegisters.tr():state.paymentObj?.isComanda == true?LocaleKeys.payment_body_weNotifyWhatsapp.tr():LocaleKeys.payment_body_canRetirePurchase.tr(),fontWeight: FontWeight.w500),
        const SizedBox(height: 24,),
        if(state.orderNumber != null) _orderNumber(),
        if(state.printFailed) _printErrorNotice(),
        if(state.paymentType!=PaymentType.cashRegister && state.paymentObj?.isComanda == true) IziText.titleSmall(color: IziColors.darkGrey, text: LocaleKeys.payment_body_waitingTime.tr(),fontWeight: FontWeight.w400),
        const SizedBox(height: 54,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IziBtn(
                buttonText: LocaleKeys.payment_buttons_makeAnotherPurchase.tr(),
                buttonType: ButtonType.outline,
                buttonSize: ButtonSize.medium,
                buttonOnPressed: (){
                  GoRouter.of(context).goNamed(RoutesKeys.home);
                }
            ),
          ],
        )
      ],
    );
  }

  // El número va siempre, no solo cuando detectamos fallo: en web no hay forma de saber si
  // salió papel, así que la pantalla es la única garantía de que el cliente se lo lleve.
  Widget _orderNumber() {
    return Column(
      children: [
        IziText.titleSmall(
            color: IziColors.darkGrey,
            text: LocaleKeys.payment_body_orderNumber.tr(),
            fontWeight: FontWeight.w400),
        const SizedBox(height: 4,),
        Text(
          "${state.orderNumber}",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: IziColors.primary,
            fontSize: FontSize.getFlutterSize(72.0),
            height: 1.1,
            leadingDistribution: TextLeadingDistribution.even,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24,),
      ],
    );
  }

  Widget _printErrorNotice() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: IziColors.redLighten50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IziText.titleSmall(
            maxLines: 3,
            color: IziColors.red,
            textAlign: TextAlign.center,
            text: LocaleKeys.payment_body_printError.tr(),
            fontWeight: FontWeight.w500),
      ),
    );
  }
}
