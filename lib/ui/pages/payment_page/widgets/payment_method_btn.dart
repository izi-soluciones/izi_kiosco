import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class PaymentMethodBtn extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  const PaymentMethodBtn({super.key,required this.onPressed,required this.icon,required this.text});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: IziCard(
        padding: const EdgeInsets.symmetric(vertical: 16.5,horizontal: 20),
        child: RowContainer(
              gap: 20,
              children: [
                Icon(icon,size: 32,color: IziColors.primary,),
                Expanded(child: IziText.titleSmall(color: IziColors.dark, text: text,mobile: true)),
                const Icon(IziIcons.rightB,size: 32,color: IziColors.grey,),
              ],
            )
      ),
    );
  }
}
