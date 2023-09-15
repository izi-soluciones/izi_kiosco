import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';

class IziTitleLg extends StatelessWidget {
  final String title;
  const IziTitleLg({super.key,required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 18),
      color: IziColors.lightGrey30,
      child: IziText.titleBig(color: IziColors.darkGrey, text: title),
    );
  }
}
