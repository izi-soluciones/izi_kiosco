import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
class UserButton extends StatelessWidget {
  final String user;
  final Function(TapDownDetails) onPressed;
  final Widget? icon;
  const UserButton({Key? key,required this.user,required this.onPressed,this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IziText.body(text: user, color: IziColors.dark, fontWeight: FontWeight.w500),
            SizedBox(width: icon!=null?8:4),
            icon??
            const Icon(IziIcons.downB,color: IziColors.darkGrey,size: 18,)
          ],
        ),
      ),
    );
  }
}
