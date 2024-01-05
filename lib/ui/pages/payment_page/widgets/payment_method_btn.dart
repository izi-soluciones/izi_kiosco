import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';

class PaymentMethodBtn extends StatelessWidget {
  final IconData icon;
  final String text;
  final String description;
  final VoidCallback onPressed;
  final Color color;
  const PaymentMethodBtn({super.key,required this.description,required this.color,required this.onPressed,required this.icon,required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400
      ),
      child: InkWell(
        onTap: onPressed,
        child: IziCard(
          padding: const EdgeInsets.symmetric(vertical: 40,horizontal: 20),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,size: 80,color: color,),
                  const SizedBox(height: 8,),
                  IziText.titleMedium(textAlign: TextAlign.center,maxLines: 2,color: IziColors.dark, text: text,mobile: true),
                  IziText.body(textAlign: TextAlign.center,maxLines: 2,color: IziColors.grey, text: description, fontWeight: FontWeight.w500)
                ],
              )
        ),
      ),
    );
  }
}
