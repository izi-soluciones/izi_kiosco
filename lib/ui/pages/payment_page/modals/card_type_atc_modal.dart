import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class CardTypeAtcModal extends StatefulWidget {
  final num amount;
  const CardTypeAtcModal({super.key, required this.amount});

  @override
  State<CardTypeAtcModal> createState() => _CardTypeAtcModalState();
}

class _CardTypeAtcModalState extends State<CardTypeAtcModal> {
  @override
  void initState() {
    _verifyTime();
    super.initState();
  }
  _verifyTime(){
    Timer(Duration(seconds: AppConstants.timerTimeSecondsInvoiced-1), () {
      if(mounted){
        Navigator.pop(context);}
    });
  }
  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IziText.title(
            color: IziColors.dark, text: "Elige un tipo de pago con tarjeta"),
        const SizedBox(height: 16,),
        Row(
          children: [
            IziText.titleSmall(color: IziColors.grey, text: "Monto a pagar"),
            const SizedBox(width: 8,),
            IziText.titleSmall(
                color: IziColors.dark, text: widget.amount.moneyFormat()),
          ],
        ),
        Flexible(
          child: GridView.count(
            crossAxisCount: ru.isXXs()?1:2,
            childAspectRatio: 1.2,
            padding: const EdgeInsets.only(top: 20),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            children: [
              _buttonPayment(context,title: "Chip", icon: Icons.sim_card_outlined, ru: ru,type: 1),
              _buttonPayment(context,title: "Contactless", icon: Icons.contactless_outlined, ru: ru,type: 2),
            ],
          ),
        ),
        const SizedBox(height: 16,),
        IziBtn(
            buttonText: "Cancelar",
            buttonType: ButtonType.terciary,
            buttonSize: ButtonSize.large,
            buttonOnPressed: (){
              context.read<PageUtilsBloc>().updateScreenActive();
              Navigator.pop(context);
            })
      ],
    );
  }

  Widget _buttonPayment(BuildContext context,{required String title,required IconData icon,required int type,required ResponsiveUtils ru}){
    return InkWell(
      onTap: (){
        context.read<PageUtilsBloc>().updateScreenActive();
        Navigator.pop(context,type);
      },
      child: IziCard(
        padding: EdgeInsets.symmetric(vertical: ru.isXs()?10:20,horizontal: ru.isXs()?10:20),
        child: Column(
          children: [
            Expanded(
              child: FittedBox(fit: BoxFit.fitHeight,child: Icon(icon,color: IziColors.darkGrey,)),
            ),
            const SizedBox(height: 4,),
            IziText.titleSmall(color: IziColors.dark, text: title,mobile: ru.isXs())
          ],
        ),
      ),
    );
  }
}
