import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:lottie/lottie.dart';

class PaymentPageOrderComplete extends StatelessWidget {
  const PaymentPageOrderComplete({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(AssetsKeys.okAnimationJson,width: 250,repeat: false,),
        IziText.titleBig(color: IziColors.secondaryDarken, text: LocaleKeys.payment_body_orderCompleted.tr()),
        IziText.titleSmall(color: IziColors.darkGrey, text: LocaleKeys.payment_body_orderCompletedDescription.tr()),
      ],
    );
  }
}
