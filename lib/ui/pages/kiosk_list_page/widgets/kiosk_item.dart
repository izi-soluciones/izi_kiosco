import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_list_item_status.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/models/device.dart';
class KioskItem extends StatelessWidget {
  final Device device;
  final VoidCallback onPressed;
  const KioskItem({super.key,required this.device,required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IziCard(
      padding: const EdgeInsets.all(20),
      background: device.activo && !device.enUso?IziColors.white:IziColors.lightGrey30,
      onPressed: device.activo && !device.enUso?onPressed:null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IziText.titleMedium(color: device.activo && !device.enUso?IziColors.dark:IziColors.grey, text: device.nombre),
                    const SizedBox(width: 8,),
                    IziListItemStatus(
                        listItemType: !device.activo?ListItemType.inactive:device.enUso?ListItemType.warning:ListItemType.active,
                        listItemText: "",
                        listItemSize: ListItemSize.small
                    )
                  ],
                ),
                Row(
                  children: [
                    IziText.body(
                        color: device.activo && !device.enUso?IziColors.darkGrey:IziColors.grey55, text: "${LocaleKeys.kioskList_body_branchOffice.tr()}: ",fontWeight: FontWeight.w400),
                    IziText.body(color: device.activo && !device.enUso?IziColors.darkGrey:IziColors.grey55, text: device.sucursalName ?? "-",fontWeight: FontWeight.w500)
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 8,),
          const Icon(
            IziIcons.rightB,
            color: IziColors.grey,
            size: 32,
          )
        ],
      ),
    );
  }
}
