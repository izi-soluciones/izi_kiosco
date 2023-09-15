import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';

class MakeOrderChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool dense;
  final VoidCallback onPressed;
  const MakeOrderChip({super.key,required this.onPressed,required this.icon,required this.text,this.dense = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: IziColors.grey35,
          borderRadius: BorderRadius.circular(6)
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: dense?MainAxisSize.min:MainAxisSize.max,
          children: [
            Icon(icon,color: IziColors.primary,size: 16,),
            const SizedBox(width: 12,),
            IziText.buttonSmall(color: IziColors.darkGrey, text: text, fontWeight: FontWeight.w600)
          ],
        ),
      ),
    );
  }
}
