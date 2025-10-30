import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/modals/warning_modal.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

class PaymentPageCard extends StatefulWidget {
  final PaymentState state;
  const PaymentPageCard({super.key, required this.state});

  @override
  State<PaymentPageCard> createState() => _PaymentPageCardState();
}

class _PaymentPageCardState extends State<PaymentPageCard> {
  late final int digitsTaxes;
  bool showCancel= false;
  verifyCancel()async {
    await Future.delayed(const Duration(seconds: 60));
    if(mounted){
      setState(() {
        showCancel =true;
      });
    }
  }
  @override
  void initState() {
    digitsTaxes = context.read<AuthBloc>().state.taxesStrategy.decimals;
    verifyCancel();
    super.initState();
  }

  _cancelPayment(){
    CustomAlerts.defaultAlert(
        context: context,
        dismissible: true,
        child: WarningModal(
            onAccept: ()async{
              context.read<PaymentBloc>().cancelPaymentCard();
            },
            title: "Esta seguro de parar la transaccion"
        )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const IziHeaderKiosk(onPop: null,hideLogo: true,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IziText.titleMedium(
                      color: IziColors.dark,
                      text: LocaleKeys.payment_titles_cardPayment.tr()),
                  const SizedBox(
                    height: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
        Expanded(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(widget.state.status == PaymentStatus.cardProcessing)
            IziText.titleSmall(
                textAlign: TextAlign.center,
                color: IziColors.dark,
                text: LocaleKeys.payment_subtitles_enterYourCard.tr(),
                fontWeight: FontWeight.w500),
            const SizedBox(
              height: 32,
            ),
            Flexible(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: widget.state.status == PaymentStatus.cardProcessing?SvgPicture.asset(
                        AssetsKeys.cardPOSSvg,
                        fit: BoxFit.contain,
                      ):const Padding(
                        padding: EdgeInsets.only(bottom: 30),
                        child: Center(
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                    ))),
            const SizedBox(
              height: 32,
            ),
            IziText.titleBig(
                color: IziColors.darkGrey,
                textAlign: TextAlign.center,
                text:
                    "${LocaleKeys.payment_body_total.tr()}: ${(widget.state.paymentObj?.amount ?? 0).moneyFormat(currency: widget.state.currentCurrency?.simbolo, digitsTaxes: digitsTaxes)}",
                fontWeight: FontWeight.w600),
            if(showCancel)
            const SizedBox(
              height: 32,
            ),
            if(showCancel)
            IziText.titleBig(
                color: IziColors.primary,
                textAlign: TextAlign.center,
                text:"Esta teniendo algun problema?",
                fontWeight: FontWeight.w400),
            if(showCancel)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: InkWell(
                onTap: () {
                  _cancelPayment();
                },
                child: Text(
                  'Parar la transaccion',
                  style: const TextStyle(
                    fontSize: 18,
                    color: IziColors.red,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.red,
                    decorationThickness: 1.5,
                  ),
                ),
              ),
              )
          ],
        ))
      ],
    );
  }
}
