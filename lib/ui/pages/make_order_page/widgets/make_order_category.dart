import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/hoverStates/on_hover.dart';
import 'package:izi_design_system/tokens/colors.dart';

class MakeOrderCategory extends StatelessWidget {
  final String title;
  final int count;
  final bool active;
  final VoidCallback onPressed;
  final bool small;
  const MakeOrderCategory({super.key,this.small=false,required this.onPressed,required this.title,required this.count,required this.active});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: OnHover(
        builder: (isHovered) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 12),
            decoration: BoxDecoration(
              color: active? IziColors.dark:IziColors.grey25,
              borderRadius: BorderRadius.circular(8)
            ),
            constraints: BoxConstraints(
              minWidth: small?150:213
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IziText.bodyBig(color: active?IziColors.white:IziColors.dark, text: title, fontWeight: FontWeight.w600),
                const SizedBox(width: 16,),
                IziText.bodyBig(color: active?IziColors.white:IziColors.dark, text: "($count)", fontWeight: FontWeight.w400),
              ],
            ),
          );
        },
      ),
    );
  }

}
