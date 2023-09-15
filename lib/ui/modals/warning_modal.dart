import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_img/izi_img.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_btn_link_icon.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
class WarningModal extends StatefulWidget {
  final Future Function() onAccept;
  final String title;
  const WarningModal(
      {Key? key,
        required this.onAccept,
        required this.title})
      : super(key: key);

  @override
  State<WarningModal> createState() => _WarningModalState();
}

class _WarningModalState extends State<WarningModal> {
 bool loading=false;

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
            text: widget.title,
            maxLines: 5,
            mobile: true,
            textAlign: TextAlign.center,
            color: IziColors.dark),
        const SizedBox(
          height: 24,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IziBtn(
              buttonOnPressed: ()async{
                setState(() {
                  loading=true;
                });
                await widget.onAccept().then((value) =>
                    Navigator.pop(context));
                setState(() {
                  loading=false;
                });
              },
              loading: loading,
              buttonSize: ButtonSize.medium,
              buttonText: LocaleKeys.general_buttons_yesSure.tr(),
              buttonType: ButtonType.primary,
            ),
          ],
        ),
        const SizedBox(
          height: 30,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: IziBtnLinkIcon(
            filterText: LocaleKeys.general_buttons_cancel.tr(),
            color: IziColors.grey,
            icon: IziIcons.leftB,
            filterTextOnPress: loading
                ? () {}
                : () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}