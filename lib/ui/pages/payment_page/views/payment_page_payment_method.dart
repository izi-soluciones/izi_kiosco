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
import 'package:izi_kiosco/ui/utils/column_container.dart';

class PaymentPagePaymentMethod extends StatelessWidget {
  final PaymentState state;

  const PaymentPagePaymentMethod({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.read<AuthBloc>().state;
    return Column(
      children: [
        PaymentHeader(
            onPop: null,
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
            icon: IziIcons.qrCode,
            text: LocaleKeys.payment_buttons_qr.tr(),
            onPressed: () {
              context.read<PaymentBloc>().selectPayment(PaymentType.qr,authState);
            }),
      ],
    );
  }
}
