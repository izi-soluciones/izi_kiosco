import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';

class MakeOrderHeaderLg extends StatelessWidget {
  final VoidCallback? onPop;
  final Widget? icon;
  const MakeOrderHeaderLg({super.key,this.onPop,this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          if(onPop!=null)
          Positioned(
            left: 0,
            child: InkWell(
              onTap: onPop,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Icon(IziIcons.leftB, color: IziColors.grey, size: 50),
              ),
            ),
          ),

          Positioned(
            right: 0,
            left: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon??SizedBox(
                    height: 100,
                    width: 150,
                    child: Image.asset(
                      AssetsKeys.texasLogoColor,
                      fit: BoxFit.fitWidth,
                    )
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
