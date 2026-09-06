import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/molecules/izi_selectable_btn.dart';
import 'package:izi_kiosco/app/utils/kiosk_locale.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    var config = context.watch<AuthBloc>().state.currentDevice?.config;
    if (!KioskLocale.canSwitch(config)) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var locale in KioskLocale.supported)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: IziSelectableBtn(
              selectableButtonText: KioskLocale.nameOf(locale),
              selectableGroupValue: context.locale.languageCode,
              selectableItemValue: locale.languageCode,
              selectableButtonPressed: () => KioskLocale.apply(context, locale),
            ),
          )
      ],
    );
  }
}
