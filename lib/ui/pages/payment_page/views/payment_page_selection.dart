import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/modals/warning_modal.dart';
import 'package:izi_kiosco/ui/pages/payment_page/modals/card_type_atc_modal.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_method_btn.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/flex_container.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';

class PaymentPageSelection extends StatelessWidget {
  final PaymentState state;

  const PaymentPageSelection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.read<AuthBloc>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IziHeaderKiosk(onPop: (){
          _cancelOrder(context);
        },hideLogo: true,),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1000,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IziText.titleBig(
                      color: IziColors.darkGrey,
                      text: LocaleKeys.payment_titles_paymentMethods.tr(),
                      maxLines: 10,
                      fontWeight: FontWeight.w600),
                  const SizedBox(height: 16,),
                  IziText.titleSmall(
                      color: IziColors.darkGrey85,
                      text: LocaleKeys.payment_subtitles_selectPaymentMethod.tr(),
                      maxLines: 10,
                      fontWeight: FontWeight.w600),
                  const SizedBox(height: 16,),
                  _methods(context, authState),
                  const SizedBox(height: 32,),
                  IziText.titleBig(textAlign: TextAlign.center,fontWeight: FontWeight.w600,color: IziColors.darkGrey85, text: "${LocaleKeys.payment_body_total.tr()}: ${state.paymentObj?.amount.moneyFormat(currency: state.currentCurrency?.simbolo, digitsTaxes: authState.taxesStrategy.decimals)}")
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  _cancelOrder(BuildContext context){

    CustomAlerts.defaultAlert(
        context: context,
        dismissible: true,
        child: WarningModal(
            onAccept: ()async{
              GoRouter.of(context).goNamed(RoutesKeys.home);
              context.read<PageUtilsBloc>().closeScreenActive();
            },
            title: LocaleKeys.makeOrderRetail_scan_areYouSureBack.tr()
        )
    );
    return;
  }

  Widget _methods(BuildContext context,AuthState authState) {
    return FlexContainer(
      flexDirection: FlexDirection.row,
      gapV: 16,
      gapH: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      children: [
        if(authState.taxesStrategy.showBreB)
        PaymentMethodBtn(
            onPressed: (){
              _selectPayment(PaymentType.breb,context,authState);
              },
            icon: IziIcons.cash,
            color: IziColors.primaryDarken,
            text: LocaleKeys.payment_buttons_breB.tr(),
        ),
        if(authState.taxesStrategy.showQR)
        PaymentMethodBtn(
            onPressed: (){
              _selectPayment(PaymentType.qr,context,authState);
              },
            icon: IziIcons.qrCode,
            color: IziColors.primaryDarken,
            text: LocaleKeys.payment_buttons_qr.tr(),
        ),
        if(authState.currentDevice?.config.ipAtc!=null||authState.currentDevice?.config.ipLinkser!=null )
          PaymentMethodBtn(
            onPressed: (){
              _selectPayment(PaymentType.card,context,authState);
            },
            color: IziColors.secondaryDarken,
            icon: IziIcons.card,
            text: LocaleKeys.payment_buttons_card.tr(),
          ),
        if(state.paymentObj?.isComanda==true && authState.currentDevice?.config.ocultarCash != true)
        PaymentMethodBtn(
            onPressed: (){
              _selectPayment(PaymentType.cashRegister,context,authState);
              },
            icon: IziIcons.registerMachine,
            color: IziColors.darkGrey,
            text: LocaleKeys.payment_buttons_checkout.tr(),
        )
      ],
    );
  }


  _selectPayment(PaymentType paymentType,BuildContext context, AuthState authState){
    if(authState.currentContribuyente?.habilitadoFacturacion==true || (authState.currentDevice?.config.isRetail!=true && authState.currentDevice?.config.isRetailBarcode!=true)){
      context.read<PaymentBloc>().selectPayment(paymentType,authState);
    }
    else{
      switch(paymentType){
        case PaymentType.card:
          _paymentCard(context, authState);
          break;
        case PaymentType.qr:
          context.read<PaymentBloc>().generateQR(authState);
          break;
        case PaymentType.breb:
          context.read<PaymentBloc>().generateBREB(authState);
          break;
        default:
          break;
      }
    }
  }

  _paymentCard(BuildContext context, AuthState authState) {
    if (authState.currentDevice?.config.ipLinkser !=
        null) {
      _paymentCardLinkser(context, authState);
    } else if (authState.currentDevice?.config.ipAtc !=
        null) {
      _paymentCardATC(context, authState);
    }
  }

  _paymentCardLinkser(BuildContext context, AuthState authState) async {
    context.read<PageUtilsBloc>().closeScreenActive();
    context
        .read<PaymentBloc>()
        .makeCardPayment(authState, linkser: true).then((status){
      if (!status) {
        context.read<PageUtilsBloc>().initScreenActiveInvoiced(authState);
      }
    });
  }

  _paymentCardATC(BuildContext context, AuthState authState) async {
    CustomAlerts.defaultAlert(
        context: context,
        dismissible: true,
        defaultScroll: false,
        child: CardTypeAtcModal(
            amount: (state.paymentObj?.amount ?? 0)))
        .then((value) async {
      if (value is int) {
        context.read<PageUtilsBloc>().closeScreenActive();
        context.read<PaymentBloc>().makeCardPayment(
            authState,
            atc: true,
            contactless: value == 1 ? false : true).then((status){

          if (!status) {
            context.read<PageUtilsBloc>().initScreenActiveInvoiced(authState);
          }
        });
      }
    });
  }
}
