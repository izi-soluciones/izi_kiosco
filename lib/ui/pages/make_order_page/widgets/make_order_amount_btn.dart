import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';

class MakeOrderAmountBtn extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String amount;

  const MakeOrderAmountBtn({super.key,required this.onPressed,
  required this.text,required this.amount});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: onPressed==null?IziColors.lightGrey:IziColors.orangeTexas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IziText.buttonBig(color: onPressed==null?IziColors.grey55:IziColors.white, text: amount, fontWeight: FontWeight.w600),
              const SizedBox(width: 40,),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IziText.buttonBig(color: onPressed==null?IziColors.grey55:IziColors.white, text: text.toUpperCase(), fontWeight: FontWeight.w600),
                  const SizedBox(width: 8,),
                  Icon(IziIcons.rightB,color: onPressed==null?IziColors.grey55:IziColors.white,size: 20,)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
