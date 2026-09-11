import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';

class PaymentChoiceBtn extends StatelessWidget {
  final String text;
  final bool selected;
  final bool big;
  final VoidCallback onPressed;
  const PaymentChoiceBtn(
      {super.key,
      required this.text,
      required this.selected,
      required this.big,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.iziColors;
    final textColor = selected ? colors.primary : colors.darkGrey85;
    // Mismo alto que IziInput: el borde es de 2 y el del input de 1,
    // por eso el padding vertical va 1px por debajo del suyo (23 big, 15 normal).
    return Material(
      color: selected ? colors.primaryLighten60 : colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: selected ? colors.primary : colors.grey35, width: 2)),
          padding: EdgeInsets.symmetric(vertical: big ? 18 : 12, horizontal: 16),
          child: big
              ? IziText.bodyBig(
                  color: textColor,
                  text: text,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.w600)
              : IziText.body(
                  color: textColor,
                  text: text,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
