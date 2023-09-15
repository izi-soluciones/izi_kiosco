import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_list_item_status.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';

class CashRegisterComponent extends StatelessWidget {
  final CashRegister cashRegister;

  const CashRegisterComponent({super.key, required this.cashRegister});

  @override
  Widget build(BuildContext context) {
    return IziCard(
      elevation: cashRegister.abierta,
      background: cashRegister.abierta ? null : IziColors.lightGrey,
      border: !cashRegister.abierta,
      child: Column(
        children: [
          const SizedBox(height: 12,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                Icon(IziIcons.registerMachine, size: 28, color: cashRegister.abierta?IziColors.darkGrey:IziColors.grey,),
                IziText.titleSmall(color: cashRegister.abierta?IziColors.dark:IziColors.grey, text: cashRegister.nombre),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IziListItemStatus(
                        listItemType: cashRegister.abierta?ListItemType.active:ListItemType.error,
                        listItemText: "",
                        listItemSize: ListItemSize.small
                    ),
                    const SizedBox(width: 4,),
                    IziText.body(color: cashRegister.abierta?IziColors.darkGrey:IziColors.darkGrey85, text: cashRegister.abierta?LocaleKeys.tables_labels_active.tr():LocaleKeys.tables_labels_close.tr(), fontWeight: cashRegister.abierta?FontWeight.w500:FontWeight.w400)
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 8,),
          if(cashRegister.abierta )
          const Divider(color: IziColors.grey25,height: 1),
          if(cashRegister.abierta )
          Padding(
            padding: const EdgeInsets.all(14),
            child: IziBtn(
                buttonText: LocaleKeys.tables_buttons_orderToGo.tr(),
                buttonType: ButtonType.secondary,
                buttonSize: ButtonSize.small,
                buttonOnPressed: (){

                }
            ),
          )
        ],
      ),
    );
  }
}
