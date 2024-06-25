import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_header.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_method_btn.dart';
import 'package:izi_kiosco/ui/utils/flex_container.dart';

class PaymentPageSelection extends StatelessWidget {
  final PaymentState state;

  const PaymentPageSelection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.read<AuthBloc>().state;
    return Column(
      children: [
        PaymentHeader(
            currency: state.currentCurrency?.simbolo??AppConstants.defaultCurrency,
            amount: (state.order?.monto ?? 0) - state.discountAmount),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                IziText.title(
                    color: IziColors.darkGrey85,
                    text: LocaleKeys.payment_body_selectMethod.tr(),
                    fontWeight: FontWeight.w600),
                const SizedBox(height: 16,),
                _methods(context, authState)
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _methods(BuildContext context,AuthState authState) {
    return FlexContainer(
      flexDirection: FlexDirection.row,
      gapV: 16,
      gapH: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if(authState.currentDevice?.config.ipAtc!=null||authState.currentDevice?.config.ipLinkser!=null )
        PaymentMethodBtn(
            onPressed: (){
              context.read<PaymentBloc>().selectPayment(PaymentType.card,authState);
            },
            color: IziColors.secondaryDarken,
            icon: IziIcons.card,
            text: LocaleKeys.payment_buttons_card.tr(),
          description: LocaleKeys.payment_body_paymentCardDescription.tr(),
        ),
        PaymentMethodBtn(
            onPressed: (){
              context.read<PaymentBloc>().selectPayment(PaymentType.qr,authState);
              },
            icon: IziIcons.qrCode,
            color: IziColors.primaryDarken,
            text: LocaleKeys.payment_buttons_qr.tr(),
          description: LocaleKeys.payment_body_paymentQrDescription.tr(),
        ),
        PaymentMethodBtn(
            onPressed: (){
              context.read<PaymentBloc>().selectPayment(PaymentType.cashRegister,authState);
              },
            icon: IziIcons.registerMachine,
            color: IziColors.darkGrey,
            text: LocaleKeys.payment_buttons_paymentCashRegister.tr(),
          description: LocaleKeys.payment_body_paymentCashRegisterDescription.tr(),
        )
      ],
    );
  }
}
