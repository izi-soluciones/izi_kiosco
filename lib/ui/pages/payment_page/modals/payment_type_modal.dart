import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/blocs/symbiotic/symbiotic_bloc.dart';
import 'package:izi_kiosco/domain/models/payment.dart';
import 'package:izi_kiosco/ui/pages/symbiotic_page/symbiotic_page.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class PaymentTypeModal extends StatelessWidget {
  final PaymentState paymentState;
  final Payment payment;
  const PaymentTypeModal({super.key,required this.paymentState,required this.payment});

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.read<AuthBloc>().state;
    final ru = ResponsiveUtils(context);
    return Container(
      color: IziColors.lightGrey30,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left:30.0,right: 30,top: 27,bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IziText.title(text: LocaleKeys.payment_type_modal_title.tr(),color: IziColors.dark),
                InkWell(
                  onTap: (){
                    Navigator.pop(context);
                  },
                  child: const Icon(IziIcons.close,color: IziColors.dark,size: 30,),
                )
              ],
            )
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:30.0),
            child: RowContainer(
              gap: 16,
              children: [
                Flexible(child:
                IziText.titleSmall(color: IziColors.grey, text: LocaleKeys.payment_type_modal_subtitles_amountToPay.tr())),
                Flexible(child:
                IziText.titleSmall(color: IziColors.dark, text: "${paymentState.currentCurrency?.simbolo} ${payment.monto?.toStringAsFixed(2)}"))
              ],
            ),
          ),
          Flexible(
            child: GridView.count(
                crossAxisCount: ru.isXXs()?1:2,
              childAspectRatio: 2.0,
              padding: const EdgeInsets.symmetric(horizontal:30.0,vertical: 20),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              children: [
                _buttonPayment(authState,title: LocaleKeys.payment_type_modal_buttons_qr.tr(), icon: IziIcons.qrCode, context: context,idPayment: AppConstants.idPaymentMethodQR,ru: ru),
                _buttonPayment(authState,title: LocaleKeys.payment_type_modal_buttons_card.tr(), icon: IziIcons.card, context: context,idPayment: AppConstants.idPaymentMethodCard,ru: ru),
                _buttonPayment(authState,title: LocaleKeys.payment_type_modal_buttons_cash.tr(), icon: IziIcons.cash, context: context,idPayment: AppConstants.idPaymentMethodCash,ru: ru),
                _buttonPayment(authState,title: LocaleKeys.payment_type_modal_buttons_transfer.tr(), icon: IziIcons.transfer, context: context,idPayment: AppConstants.idPaymentMethodTransfer,ru: ru),
                _buttonPayment(authState,title: LocaleKeys.payment_type_modal_buttons_giftCard.tr(), icon: IziIcons.category, context: context,idPayment: AppConstants.idPaymentMethodGiftCard,ru: ru),
                if(authState.currentPos?.activo==true && authState.currentContribuyente?.habilitadoTerminal == true)
                  _buttonPayment(authState,title: LocaleKeys.payment_type_modal_buttons_tapOnPhone.tr(), icon: IziIcons.cardBack, context: context,idPayment: AppConstants.idPaymentMethodOthers,ru: ru),
              ],
            ),
          )
        ],
      ),
    );
  }


  Widget _buttonPayment(AuthState authState,{required String title,required IconData icon,required int idPayment,required BuildContext context,required ResponsiveUtils ru}){
    return InkWell(
      onTap: (){
        if(idPayment == AppConstants.idPaymentMethodOthers){
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context)=>BlocProvider(
                create: (context)=>SymbioticBloc(payment.monto??0)..initTerminal(authState),
                child: const SymbioticPage(),
              ))
          ).then((value) {
            if(value==true){
              Navigator.pop(context,AppConstants.idPaymentMethodCard);
            }
          },);
          return;
        }
        Navigator.pop(context,idPayment);
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
