import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
class IziHeaderKiosk extends StatelessWidget {
  final VoidCallback? onBack;
  const IziHeaderKiosk({super.key,required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          onBack!=null?
          InkWell(
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Icon(IziIcons.leftB, color: IziColors.grey, size: 50),
            ),
          ): const SizedBox.shrink(),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 20,vertical: ru.gtXs()? 16:8),
          //   child: IziBtnIcon(
          //       buttonIcon: IziIcons.help,
          //       buttonType: ButtonType.outline,
          //       buttonSize: ButtonSize.medium,
          //       buttonOnPressed: () {
          //
          //       }),
          // )
          const SizedBox.shrink()
        ],
      );

  }
}
