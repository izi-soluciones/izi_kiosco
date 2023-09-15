import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/blocs/symbiotic/symbiotic_bloc.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_header.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_method_btn.dart';
import 'package:izi_kiosco/ui/pages/symbiotic_page/symbiotic_page.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class PaymentPagePaymentMethod extends StatelessWidget {
  final PaymentState state;

  const PaymentPagePaymentMethod({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.read<AuthBloc>().state;
    final ru = ResponsiveUtils(context);
    return Column(
      children: [
        PaymentHeader(
            onPop: ru.lwSm()
                ? () {
                    context.read<PaymentBloc>().changeStep(0);
                  }
                : null,
            currency: state.currentCurrency?.simbolo??AppConstants.defaultCurrency,
            amount: (state.order?.monto ?? 0) - state.discountAmount),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 444,
                ),
                child: _methods(context,authState)),
          ),
        )
      ],
    );
  }

  Widget _methods(BuildContext context,AuthState authState) {
    return ColumnContainer(
      gap: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IziText.body(
            color: IziColors.darkGrey85,
            text: LocaleKeys.payment_body_selectMethod.tr(),
            fontWeight: FontWeight.w600),
        PaymentMethodBtn(
          icon: IziIcons.cash,
          text: LocaleKeys.payment_buttons_cash.tr(),
          onPressed: () {
            context.read<PaymentBloc>().selectPayment(PaymentType.cash,authState);
          },
        ),
        PaymentMethodBtn(
            icon: IziIcons.qrCode,
            text: LocaleKeys.payment_buttons_qr.tr(),
            onPressed: () {
              context.read<PaymentBloc>().selectPayment(PaymentType.qr,authState);
            }),
        PaymentMethodBtn(
            icon: IziIcons.card,
            text: LocaleKeys.payment_buttons_card.tr(),
            onPressed: () {
              context.read<PaymentBloc>().selectPayment(PaymentType.card,authState);
            }),
        PaymentMethodBtn(
            icon: IziIcons.transfer,
            text: LocaleKeys.payment_buttons_bankTransfer.tr(),
            onPressed: () {
              context.read<PaymentBloc>().selectPayment(PaymentType.bankTransfer,authState);
            }),
        PaymentMethodBtn(
            icon: IziIcons.category,
            text: LocaleKeys.payment_buttons_giftCard.tr(),
            onPressed: () {
              context.read<PaymentBloc>().selectPayment(PaymentType.gitCard,authState);
            }),
        if(authState.currentPos?.activo==true && authState.currentContribuyente?.habilitadoTerminal == true)
        PaymentMethodBtn(
            icon: IziIcons.cardBack,
            text: LocaleKeys.payment_buttons_tapOnPhone.tr(),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context)=>BlocProvider(
                      create: (context)=>SymbioticBloc((state.order?.monto??0)-state.discountAmount)..initTerminal(context.read<AuthBloc>().state),
                    child: const SymbioticPage(),
                  ))
              ).then((value) {
                if(value==true){
                  context.read<PageUtilsBloc>().lockPage();
                  context.read<PaymentBloc>().emitPaymentTotal(AppConstants.idPaymentMethodCard, authState);
                }
              },);

            }),
        const Divider(height: 1, color: IziColors.grey25),
        PaymentMethodBtn(
            icon: IziIcons.split,
            text: LocaleKeys.payment_buttons_splitPayment.tr(),
            onPressed: () {
              context.read<PaymentBloc>().changeStep(4);
            }),
      ],
    );
  }
}
