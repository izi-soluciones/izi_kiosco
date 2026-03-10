import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';

class PaymentPageDemo extends StatefulWidget {
  final PaymentState state;
  const PaymentPageDemo({super.key, required this.state});

  @override
  State<PaymentPageDemo> createState() => _PaymentPageDemoState();
}

class _PaymentPageDemoState extends State<PaymentPageDemo> {
  bool loading=false;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      color: Colors.white,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IziText.titleBig(
            text: LocaleKeys.demoPayment_title.tr(),
            color: IziColors.dark,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(
            height: 48,
          ),
          IziText.bodyBig(
              text: LocaleKeys.demoPayment_body.tr(),
              color: IziColors.darkGrey,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.normal),
          const SizedBox(
            height: 48,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IziBtn(
                  buttonText: LocaleKeys.payment_buttons_proceedPayment.tr(), // Using existing key for now
                  buttonType: ButtonType.primary,
                  buttonSize: ButtonSize.large,
                  loading: loading,
                  buttonOnPressed: () {
                    setState(() {
                      loading=true;
                    });
                    context.read<PaymentBloc>().confirmDemoPayment();
                  }),
            ],
          )
        ],
      ),
    );
  }
}
