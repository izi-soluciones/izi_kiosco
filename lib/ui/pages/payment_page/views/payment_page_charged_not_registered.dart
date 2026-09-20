import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';

/// Shown when the card was charged but the order could not be registered.
///
/// The customer paid, so this must never look like a failed payment: it says
/// the charge went through, tells them not to pay again, and shows what the
/// staff need to find the charge.
class PaymentPageChargedNotRegistered extends StatelessWidget {
  const PaymentPageChargedNotRegistered({super.key, required this.state});

  final PaymentState state;

  @override
  Widget build(BuildContext context) {
    final proof = state.chargeProof;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IziText.titleBig(
            color: context.iziColors.darkGrey,
            text: LocaleKeys.payment_subtitles_chargedNotRegistered.tr(),
            fontWeight: FontWeight.w600),
        Icon(IziIcons.check, size: 180, color: context.iziColors.primary),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: IziText.titleMedium(
              maxLines: 3,
              textAlign: TextAlign.center,
              color: context.iziColors.darkGrey,
              text: LocaleKeys.payment_subtitles_chargedNotRegisteredDetail.tr(),
              fontWeight: FontWeight.w500),
        ),
        if (proof != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: context.iziColors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IziText.body(
                color: context.iziColors.darkGrey,
                text: proof,
                maxLines: 3,
                fontWeight: FontWeight.w500,
                textAlign: TextAlign.center),
          ),
        ],
        const SizedBox(height: 48),
        IziBtn(
            buttonText: LocaleKeys.payment_buttons_makeAnotherPurchase.tr(),
            buttonType: ButtonType.outline,
            buttonSize: ButtonSize.medium,
            buttonOnPressed: () {
              GoRouter.of(context).goNamed(RoutesKeys.home);
            }),
      ],
    );
  }
}
