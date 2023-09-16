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
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: onPressed,
        child: OnHover(
          builder: (isHovered) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 12),
              decoration: BoxDecoration(
                color: active? IziColors.dark:IziColors.grey25,
                borderRadius: BorderRadius.circular(8)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IziText.bodySmall(color: active?IziColors.white:IziColors.dark,textAlign: TextAlign.center, text: title, fontWeight: FontWeight.w600,maxLines: 3),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}
