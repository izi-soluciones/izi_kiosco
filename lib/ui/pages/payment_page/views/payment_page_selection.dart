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
        IziHeaderKiosk(onBack: (){
          _cancelOrder(context);
        }),
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
                      fontWeight: FontWeight.w600),
                  const SizedBox(height: 16,),
                  IziText.titleSmall(
                      color: IziColors.darkGrey85,
                      text: LocaleKeys.payment_subtitles_selectPaymentMethod.tr(),
                      fontWeight: FontWeight.w600),
                  const SizedBox(height: 16,),
                  _methods(context, authState),
                  const SizedBox(height: 32,),
                  IziText.titleBig(textAlign: TextAlign.center,fontWeight: FontWeight.w600,color: IziColors.darkGrey85, text: "${LocaleKeys.payment_body_total.tr()}: ${state.paymentObj?.amount.moneyFormat(currency: state.currentCurrency?.simbolo)}")
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
        PaymentMethodBtn(
            onPressed: (){
              context.read<PaymentBloc>().selectPayment(PaymentType.qr,authState);
              },
            icon: IziIcons.qrCode,
            color: IziColors.primary,
            text: LocaleKeys.payment_buttons_qr.tr(),
        ),
        if(authState.currentDevice?.config.ipAtc!=null||authState.currentDevice?.config.ipLinkser!=null )
          PaymentMethodBtn(
            onPressed: (){
              context.read<PaymentBloc>().selectPayment(PaymentType.card,authState);
            },
            color: IziColors.primary,
            icon: IziIcons.card,
            text: LocaleKeys.payment_buttons_card.tr(),
          ),
        if(state.paymentObj?.isComanda==true)
        PaymentMethodBtn(
            onPressed: (){
              context.read<PaymentBloc>().selectPayment(PaymentType.cashRegister,authState);
              },
            icon: IziIcons.registerMachine,
            color: IziColors.primary,
            text: LocaleKeys.payment_buttons_checkout.tr(),
        )
      ],
    );
  }
}
