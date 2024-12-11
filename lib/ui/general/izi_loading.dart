import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';

class IziLoading extends StatelessWidget {
  final String title;
  const IziLoading({super.key,required this.title});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: IziColors.white.withOpacity(0.6),
              ),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IziText.title(color: IziColors.darkGrey, text: title,fontWeight: FontWeight.w400),
                const SizedBox(height: 8,),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(color: IziColors.primary,strokeWidth: 2),
                ),
              ],
            ),
          )

        ],
      ),
    );
  }
}
