import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class PaymentHeader extends StatelessWidget {
  final num? amount;
  final VoidCallback? onPop;
  final String? popText;
  final Widget? widget;
  final String currency;
  const PaymentHeader({super.key, this.popText,this.amount, this.onPop,this.widget,required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            border:
                Border(bottom: BorderSide(color: IziColors.grey25, width: 1))),
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Stack(
          children: [
            if(widget == null && amount!=null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                IziText.titleSmall(
                    color: IziColors.grey,
                    textAlign: TextAlign.center,
                    text: LocaleKeys.payment_subtitles_mustCharge.tr()),
                IziText.titleBig(
                    color: IziColors.dark,
                    textAlign: TextAlign.center,
                    text: amount!.moneyFormat(currency: currency))
              ],
            ),
            if(widget!=null)
              widget!,

            if(onPop !=null)
              Positioned(
                bottom: 0,
                top: 0,
                child: InkWell(
                  onTap: onPop,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RowContainer(
                      gap: 8,
                      children: [
                        const Icon(IziIcons.leftB,size: 24,color: IziColors.darkGrey,),
                        if(popText!=null)
                        IziText.titleSmall(color: IziColors.darkGrey85, text: popText!)

                      ]
                    ),
                  ),
                ),
              ),
          ],
        ));
  }
}
