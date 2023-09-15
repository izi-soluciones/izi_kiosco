import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_img/izi_img.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn_link_icon.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';

class WarningConfigModal extends StatelessWidget {
  final String title;
  final String description;
  const WarningConfigModal({super.key,required this.title,required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IziImg.alertWarning(width: 72.3),
        const SizedBox(
          height: 24,
        ),

        IziText.titleSmall(
            text: title,
            maxLines: 5,
            mobile: true,
            textAlign: TextAlign.center,
            color: IziColors.dark),
        const SizedBox(
          height: 8,
        ),
        IziText.body(
            text: description,
            maxLines: 10,
            fontWeight: FontWeight.w400,
            textAlign: TextAlign.center,
            color: IziColors.darkGrey),
        const SizedBox(
          height: 24,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: IziBtnLinkIcon(
            filterText: LocaleKeys.general_buttons_accept.tr(),
            color: IziColors.grey,
            icon: IziIcons.leftB,
            filterTextOnPress: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}