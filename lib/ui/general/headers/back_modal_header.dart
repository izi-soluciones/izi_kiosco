import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';

class BackModalHeader extends StatelessWidget {
  final String title;
  const BackModalHeader({super.key,required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 24,right: 17,top: 18,bottom: 18),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: IziColors.grey35,width: 1)
        )
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: IziText.titleSmall(color: IziColors.dark, text: title),),
          InkWell(
            onTap: (){
              Navigator.pop(context);
            },
            child: const Icon(
              IziIcons.close,
              size: 30,
              color: IziColors.grey,
            ),
          )
        ],
      ),
    );
  }
}
