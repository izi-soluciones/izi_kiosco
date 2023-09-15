import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_header.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

import 'package:izi_kiosco/ui/utils/web_image.dart';

class PaymentPageQr extends StatelessWidget {
  final PaymentState state;
  const PaymentPageQr({super.key,required this.state});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Column(
      children: [
        PaymentHeader(
            onPop: () {
              context.read<PaymentBloc>().backReset();
            },
            currency:
            state.currentCurrency?.simbolo ?? AppConstants.defaultCurrency,
            popText: ru.gtXs() ? LocaleKeys.payment_titles_card.tr() : null,
            amount: (state.qrAmount ??0),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    state.qrCharge!=null?
                        kIsWeb?
                            AspectRatio(
                              aspectRatio: 1,
                                child: WebImage(imageUrl: state.qrCharge?.qrUrl??"")
                            ):
                    Image.network(state.qrCharge?.qrUrl??"",fit: BoxFit.fitWidth,):
                        const SizedBox(
                          height: 40,
                          width: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        ),
                    const SizedBox(height: 50,),
                    _form(context,ru)
                  ],
                )
            ),
          ),
        )
      ],
    );
  }


  _form(BuildContext context,ResponsiveUtils ru){
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IziBtn(
            buttonText: LocaleKeys.payment_buttons_markAsPaid.tr(),
            buttonType: ButtonType.secondary,
            buttonSize: ru.isXs()?ButtonSize.medium:ButtonSize.large,
            buttonOnPressed:(){
              if(state.qrPaymentKey!=null){
                context.read<PaymentBloc>().changeStep(4);
                context.read<PageUtilsBloc>().lockPage();
                context
                    .read<PaymentBloc>()
                    .emitPayment(
                    state.qrPaymentKey!,
                    AppConstants.idPaymentMethodQR,
                    context
                        .read<AuthBloc>()
                        .state);
              }
              else{
                context.read<PaymentBloc>().markPaidQr();
              }

            }
        ),
        const SizedBox(height: 100,),
        IziBtn(
            buttonText: LocaleKeys.payment_buttons_changePaymentMethod.tr(),
            buttonType: ButtonType.outline,
            buttonSize: ButtonSize.medium,
            buttonOnPressed: (){
              context.read<PaymentBloc>().backReset();
            }
        )
      ],
    );
  }

}
