import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class PaymentMethodBtn extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  final Color color;
  const PaymentMethodBtn({super.key,required this.color,required this.onPressed,required this.icon,required this.text});

  @override
  Widget build(BuildContext context) {
    final ru= ResponsiveUtils(context);
    return ConstrainedBox(
      constraints:  const BoxConstraints(
        maxWidth: 292,
      ),
      child: InkWell(
        onTap: onPressed,
        child: IziCard(
          padding:  EdgeInsets.symmetric(vertical: ru.gtSm()?40:16,horizontal: 20),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,size: ru.gtSm()?150:75,color: color,),
                  const SizedBox(height: 8,),
                  IziText.titleMedium(textAlign: TextAlign.center,maxLines: 2,color: IziColors.dark, text: text,mobile: true)
                ],
              )
        ),
      ),
    );
  }
}
