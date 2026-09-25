import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

class CardTypeIzifyModal extends StatefulWidget {
  final num amount;
  const CardTypeIzifyModal({super.key, required this.amount});

  @override
  State<CardTypeIzifyModal> createState() => _CardTypeIzifyModalState();
}

class _CardTypeIzifyModalState extends State<CardTypeIzifyModal> {
  late final int digitsTaxes;
  @override
  void initState() {
    digitsTaxes = context.read<AuthBloc>().state.taxesStrategy.decimals;
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
            color: context.iziColors.dark, text: LocaleKeys.payment_subtitles_chooseCardType.tr()),
        const SizedBox(height: 16,),
        Row(
          children: [
            IziText.titleSmall(color: context.iziColors.grey, text: LocaleKeys.payment_body_amountToPay.tr()),
            const SizedBox(width: 8,),
            IziText.titleSmall(
                color: context.iziColors.dark, text: widget.amount.moneyFormat(digitsTaxes: digitsTaxes)),
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
              _buttonPayment(context,title: LocaleKeys.payment_buttons_debit.tr(), icon: Icons.credit_card_outlined, ru: ru,type: "DEBITO"),
              _buttonPayment(context,title: LocaleKeys.payment_buttons_credit.tr(), icon: Icons.credit_score_outlined, ru: ru,type: "CREDITO"),
            ],
          ),
        ),
        const SizedBox(height: 16,),
        IziBtn(
            buttonText: LocaleKeys.general_buttons_cancel.tr(),
            buttonType: ButtonType.terciary,
            buttonSize: ButtonSize.large,
            buttonOnPressed: (){
              context.read<PageUtilsBloc>().updateScreenActive();
              Navigator.pop(context);
            })
      ],
    );
  }

  Widget _buttonPayment(BuildContext context,{required String title,required IconData icon,required String type,required ResponsiveUtils ru}){
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
              child: FittedBox(fit: BoxFit.fitHeight,child: Icon(icon,color: context.iziColors.darkGrey,)),
            ),
            const SizedBox(height: 4,),
            IziText.titleSmall(color: context.iziColors.dark, text: title,mobile: ru.isXs())
          ],
        ),
      ),
    );
  }
}
