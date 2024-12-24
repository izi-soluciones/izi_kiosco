import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_img/izi_img.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
class HelpModal extends StatefulWidget {
  const HelpModal({super.key});

  @override
  State<HelpModal> createState() => _HelpModalState();
}

class _HelpModalState extends State<HelpModal> {
  Timer? timer;
  int seconds = 60;
  @override
  void initState() {
    if(!context.read<PageUtilsBloc>().state.helpActive && context.read<PageUtilsBloc>().state.dateHelp!=null){
      seconds = AppConstants.timerHelp-DateTime.now().difference(context.read<PageUtilsBloc>().state.dateHelp!).inSeconds;

      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if(mounted){
          seconds--;
          setState(() {});
          if(seconds==0){
            timer.cancel();
          }
        }
      });
    }
    super.initState();
  }
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PageUtilsBloc,PageUtilsState>(
      builder: (context,state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: (){
                      Navigator.pop(context);
                    },
                    child: const Icon(IziIcons.close,color: IziColors.darkGrey,size: 30,),
                  )
                ],
              ),
              const SizedBox(height: 8,),
              IziImg.alertWarning(width: 72.3),
              const SizedBox(height: 8,),
              IziText.titleMedium(color: IziColors.dark, text: LocaleKeys.helpModal_title.tr()),
              const SizedBox(height: 32,),
              IziBtn(
                  buttonText: LocaleKeys.helpModal_buttons_call.tr(),
                  buttonType: ButtonType.primary,
                  buttonSize: ButtonSize.medium,
                  buttonOnPressed: state.helpActive?() {
                    context.read<PageUtilsBloc>().askHelp(context.read<AuthBloc>().state);
                    context.read<PageUtilsBloc>().showSnackBar(snackBar: SnackBarInfo(text: LocaleKeys.helpModal_messages_messageSent.tr(), snackBarType: SnackBarType.success));
                    Navigator.pop(context);
                  }:null),
              if(!state.helpActive)
                IziText.titleMedium(color: IziColors.primary, text: "${seconds}s"),
            ],
          ),
        );
      }
    );
  }
}
