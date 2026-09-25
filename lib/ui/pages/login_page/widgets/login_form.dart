import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/login/login_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LoginForm extends StatelessWidget {
  final LoginState state;

  const LoginForm({Key? key,required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (state.qrUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IziText.titleBig(text: LocaleKeys.login_subtitles_qrLogin.tr(), color: context.iziColors.dark),
          const SizedBox(height: 25,),
          IziText.body(
            maxLines: 79,
            fontWeight: FontWeight.normal, text: LocaleKeys.login_body_qrInstructions.tr(), color: context.iziColors.darkGrey, textAlign: TextAlign.center),
          const SizedBox(height: 25,),
          Center(
            child: QrImageView(
              data: state.qrUrl!,
              version: QrVersions.auto,
              size: 250.0,
            ),
          ),
          const SizedBox(height: 20,),
          if (state.status == LoginStatus.waitingLogin)
            const CircularProgressIndicator(),
        ],
      );
    }
    
    // Show a loader if the QR is still being fetched from the backend (or we are in an initial waiting state)
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20,),
          IziText.body(fontWeight: FontWeight.normal, text: LocaleKeys.login_messages_generatingQR.tr(), color: context.iziColors.darkGrey, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
