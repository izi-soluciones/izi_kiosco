import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';

class PaymentPageOrderError extends StatelessWidget {
  const PaymentPageOrderError({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
            height: 150,
            width: 150,
            child: Image.asset(
              AssetsKeys.texasLogoColor,
              fit: BoxFit.fitWidth,
            )
        ),
        const SizedBox(height: 32,),
        IziText.titleBig(color: IziColors.darkGrey, text: LocaleKeys.payment_messages_errorPayment.tr(),fontWeight: FontWeight.w600),
        const Icon(IziIcons.close,size: 250,color: Colors.red),
        const SizedBox(height: 8,),
        IziText.titleMedium(maxLines: 2,color: IziColors.darkGrey, text: LocaleKeys.payment_messages_errorPaymentDescription.tr(),fontWeight: FontWeight.w500),
        const SizedBox(height: 54,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IziBtn(
                buttonText: LocaleKeys.payment_buttons_makeAnother.tr(),
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
}
