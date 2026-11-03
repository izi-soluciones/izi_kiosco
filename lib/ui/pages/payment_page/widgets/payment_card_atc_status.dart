import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_img/izi_img.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';

/// Pago con tarjeta ATC cuyo resultado no se pudo confirmar: la pregunta del
/// voucher y, si el cliente lo tiene, el aviso de no volver a pagar.
class PaymentCardAtcStatus extends StatelessWidget {
  final PaymentState state;
  const PaymentCardAtcStatus({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final blocked = state.status == PaymentStatus.cardBlocked;
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const IziHeaderKiosk(onPop: null,hideLogo: true,),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IziImg.alertWarning(width: 120),
                  const SizedBox(height: 32,),
                  IziText.titleBig(
                      color: context.iziColors.darkGrey,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      text: blocked
                          ? LocaleKeys.payment_subtitles_cardPaymentBlocked.tr()
                          : LocaleKeys.payment_subtitles_cardPaymentUncertain.tr(),
                      fontWeight: FontWeight.w600),
                  if(blocked && state.atcCode != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: IziText.titleBig(
                          color: context.iziColors.dark,
                          textAlign: TextAlign.center,
                          text: LocaleKeys.payment_body_cardPaymentCode.tr(args: [state.atcCode!]),
                          fontWeight: FontWeight.w700),
                    ),
                  const SizedBox(height: 54,),
                  if(blocked)
                    IziBtn(
                        buttonText: LocaleKeys.payment_buttons_makeAnotherPurchase.tr(),
                        buttonType: ButtonType.outline,
                        buttonSize: ButtonSize.medium,
                        buttonOnPressed: (){
                          GoRouter.of(context).goNamed(RoutesKeys.home);
                        }
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IziBtn(
                            buttonText: LocaleKeys.payment_buttons_hasVoucherYes.tr(),
                            buttonType: ButtonType.primary,
                            buttonSize: ButtonSize.medium,
                            buttonOnPressed: (){
                              context.read<PaymentBloc>().answerAtcVoucher(context.read<AuthBloc>().state, true);
                            }
                        ),
                        const SizedBox(width: 16,),
                        IziBtn(
                            buttonText: LocaleKeys.payment_buttons_hasVoucherNo.tr(),
                            buttonType: ButtonType.outline,
                            buttonSize: ButtonSize.medium,
                            buttonOnPressed: (){
                              context.read<PaymentBloc>().answerAtcVoucher(context.read<AuthBloc>().state, false);
                            }
                        ),
                      ],
                    )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
