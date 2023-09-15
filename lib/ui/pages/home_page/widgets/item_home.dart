import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';

class ItemHome extends StatelessWidget {

  final VoidCallback onPressed;
  final IconData icon;
  final String name;
  const ItemHome({super.key,required this.icon,
  required this.name,
  required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: IziCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.fitHeight,
                child: Icon(
                  icon,
                  color: IziColors.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top:8.0),
              child: IziText.titleSmall(
                  color: IziColors.dark,
                  textAlign: TextAlign.center,
                  text: name,
            )
            )
          ],
        ),
      ),
    );
  }
}
