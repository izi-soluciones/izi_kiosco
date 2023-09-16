import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (){
        GoRouter.of(context).goNamed(RoutesKeys.makeOrder);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FractionallySizedBox(
            widthFactor: 0.3,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500
              ),
              child: const Icon(IziIcons.izi,color: IziColors.primary,size: 150,),
            ),
          ),
          const SizedBox(height: 16,),
          IziText.title(color: IziColors.dark, text: LocaleKeys.home_subtitles_iziKiosk.tr()),
          const SizedBox(height: 8,),
          IziText.bodyBig(color: IziColors.darkGrey, text: LocaleKeys.home_body_description.tr(),fontWeight: FontWeight.w400),
        ],
      ),
    );
  }


}
