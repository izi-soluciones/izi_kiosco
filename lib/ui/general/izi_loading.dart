import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';

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
                Image.asset(AssetsKeys.texasLogoColor,width: 100,),
                const SizedBox(height: 16,),
                IziText.title(color: IziColors.darkGrey, text: title,fontWeight: FontWeight.w400),
                const SizedBox(height: 8,),
                const SizedBox(
                  width: 15,
                  height: 15,
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
