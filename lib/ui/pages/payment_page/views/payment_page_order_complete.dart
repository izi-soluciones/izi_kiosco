import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:lottie/lottie.dart';

class PaymentPageOrderComplete extends StatelessWidget {
  final PaymentState state;
  const PaymentPageOrderComplete({super.key,required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        context.read<AuthBloc>().state.currentContribuyente?.logo != null
            ? SizedBox(
            height: 150,
            child: CachedNetworkImage(
              imageUrl:
              "${dotenv.env[EnvKeys.apiUrl]}/contribuyentes/${context.read<AuthBloc>().state.currentContribuyente?.id}/logo",
              fit: BoxFit.fitHeight,
              placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: IziColors.dark)),
              errorWidget: (context, url, error) {
                return const SizedBox.shrink();
              },
            ))
            : const SizedBox.shrink(),
        const SizedBox(height: 32,),
        IziText.titleBig(color: IziColors.darkGrey, text: state.paymentType==PaymentType.cashRegister?LocaleKeys.payment_subtitles_successOrder.tr():LocaleKeys.payment_subtitles_successPayment.tr(),fontWeight: FontWeight.w600),
        Lottie.asset(AssetsKeys.okAnimationJson,width: 250,repeat: false,),
        const SizedBox(height: 8,),
        IziText.titleMedium(maxLines: 2,color: IziColors.darkGrey, text: state.paymentType==PaymentType.cashRegister?LocaleKeys.payment_body_goToCashRegisters.tr():LocaleKeys.payment_body_weNotifyWhatsapp.tr(),fontWeight: FontWeight.w500),
        const SizedBox(height: 24,),
        if(state.paymentType!=PaymentType.cashRegister)IziText.titleSmall(color: IziColors.darkGrey, text: LocaleKeys.payment_body_waitingTime.tr(),fontWeight: FontWeight.w400),
        const SizedBox(height: 54,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IziBtn(
                buttonText: LocaleKeys.payment_buttons_makeAnother.tr(),
                buttonType: ButtonType.outline,
                buttonSize: ButtonSize.medium,
                buttonOnPressed: (){
                  GoRouter.of(context).goNamed(RoutesKeys.home);
                }
            ),
          ],
        )
      ],
    );
  }
}
