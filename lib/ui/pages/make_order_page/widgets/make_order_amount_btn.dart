import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';

class MakeOrderAmountBtn extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String amount;
  final bool medium;
  final bool noAmount;

  const MakeOrderAmountBtn({super.key,required this.onPressed,
  required this.text,required this.amount,this.medium=false,this.noAmount=false});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: onPressed==null?context.iziColors.lightGrey:context.iziColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: medium?12:18, horizontal: 30),
          child: Row(
            mainAxisAlignment: noAmount?MainAxisAlignment.center:MainAxisAlignment.spaceBetween,
            children: [
              if(!noAmount)
              IziText.buttonBig(color: onPressed==null?context.iziColors.grey55:context.iziColors.white, text: amount, fontWeight: FontWeight.w600),
              if(!noAmount)
                const SizedBox(width: 40,),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IziText.buttonBig(color: onPressed==null?context.iziColors.grey55:context.iziColors.white, text: text.toUpperCase(), fontWeight: FontWeight.w600),
                  const SizedBox(width: 8,),
                  Icon(IziIcons.rightB,color: onPressed==null?context.iziColors.grey55:context.iziColors.white,size: 20,)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
