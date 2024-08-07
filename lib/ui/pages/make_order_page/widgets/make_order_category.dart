import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';

class MakeOrderCategory extends StatelessWidget {
  final String title;
  final int count;
  final bool active;
  final VoidCallback onPressed;
  final bool small;
  final IconData icon;
  const MakeOrderCategory({super.key,this.small=false,required this.onPressed,required this.title,required this.count,required this.active,required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(32,10,32,5),
        decoration: BoxDecoration(
          color: active? IziColors.dark:IziColors.grey25,
          borderRadius: BorderRadius.circular(8)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,color: active?IziColors.white:IziColors.dark,size: 40,weight: 1),
            IziText.body(color: active?IziColors.white:IziColors.dark,textAlign: TextAlign.center, text: title, fontWeight: FontWeight.w600,maxLines: 3),
          ],
        ),
      ),
    );
  }

}
