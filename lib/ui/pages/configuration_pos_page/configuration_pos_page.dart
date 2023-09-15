import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_radio_button.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_radio_button_label.dart';
import 'package:izi_design_system/molecules/izi_resume.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/pos_configuration/pos_configuration_bloc.dart';
import 'package:izi_kiosco/domain/models/pos.dart';
import 'package:izi_kiosco/ui/general/headers/back_mobile_header.dart';
import 'package:izi_kiosco/ui/general/izi_app_bar.dart';
import 'package:izi_kiosco/ui/general/title/izi_title_lg.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class ConfigurationPosPage extends StatelessWidget {
  const ConfigurationPosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return BlocBuilder<AuthBloc,AuthState>(
      builder: (context,authState) {
        return BlocConsumer<PosConfigurationBloc, PosConfigurationState>(
          listener: (context,state){

            if(state.status==PosConfigurationStatus.successActivate){

              context.read<PageUtilsBloc>().unlockPage();
              context.read<PageUtilsBloc>().showSnackBar(
                  snackBar: SnackBarInfo(
                      text: LocaleKeys.configurationPos_messages_successActivate.tr(),
                      snackBarType: SnackBarType.success));
            }
            if(state.status==PosConfigurationStatus.errorActivate){
              context.read<PageUtilsBloc>().unlockPage();
              context.read<PageUtilsBloc>().showSnackBar(
                  snackBar: SnackBarInfo(
                      text: LocaleKeys.configurationPos_messages_errorActivate.tr(),
                      snackBarType: SnackBarType.error));
            }

            if(state.status==PosConfigurationStatus.successChangeEnvironment){
              context.read<PageUtilsBloc>().unlockPage();
              context.read<PageUtilsBloc>().showSnackBar(
                  snackBar: SnackBarInfo(
                      text: LocaleKeys.configurationPos_messages_successChangeEnvironment.tr(),
                      snackBarType: SnackBarType.success));
            }
            if(state.status==PosConfigurationStatus.errorChangeEnvironment){
              context.read<PageUtilsBloc>().unlockPage();
              context.read<PageUtilsBloc>().showSnackBar(
                  snackBar: SnackBarInfo(
                      text: LocaleKeys.configurationPos_messages_errorChangeEnvironment.tr(),
                      snackBarType: SnackBarType.error));
            }

          },
            builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ru.isXs())
                BackMobileHeader(
                    title: IziText.title(
                        color: IziColors.dark,
                        text: LocaleKeys.configurationPos_title.tr()),
                    onBack: () {
                      GoRouter.of(context).goNamed(RoutesKeys.home);
                    }),
              if (ru.gtXs()) const IziAppBar(),
              if (ru.gtXs())
                IziTitleLg(
                  title: LocaleKeys.configurationPos_title.tr(),
                ),
              _headerSymbiotic(ru),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 20, horizontal: ru.isXs() ? 17 : 63),
                child: ColumnContainer(
                  gap: 24,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _status(ru, authState, state),
                    if(authState.currentPos?.activo!=false)
                    _form(authState, state, context),

                    if (authState.currentPos == null)
                      Row(
                        children: [
                          IziBtn(
                              buttonText:
                                  LocaleKeys.configurationPos_buttons_activate.tr(),
                              buttonType: ButtonType.primary,
                              buttonSize: ButtonSize.medium,
                              loading: state.status==PosConfigurationStatus.waitingActivate,
                              buttonOnPressed: () async {
                                context.read<PageUtilsBloc>().lockPage();
                                context
                                    .read<PosConfigurationBloc>()
                                    .activatePos(
                                        authState: context.read<AuthBloc>().state)
                                    .then(
                                  (Pos? pos) {
                                    context.read<AuthBloc>().updatePos(pos);
                                  },
                                );
                              }),
                        ],
                      )
                  ],
                ),
              )
            ],
          );
        });
      }
    );
  }

  Widget _form(
      AuthState authState, PosConfigurationState state, BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: ColumnContainer(
        gap: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IziText.body(
              color: IziColors.dark,
              text:
                  "${LocaleKeys.configurationPos_subtitles_environment.tr()}:",
              fontWeight: FontWeight.w600),
          IziRadioButtonLabel(
              radioButtonType: state.isTest
                  ? RadioButtonType.checkboxDefault
                  : RadioButtonType.checkboxChecked,
              loading: state.status == PosConfigurationStatus.waitingChangeEnvironment && state.isTest,
              onPressedRadioButton: () {
                if (authState.currentPos == null) {
                  context.read<PosConfigurationBloc>().changeIsTest(false);
                } else {
                  context.read<PageUtilsBloc>().lockPage();
                  context.read<PosConfigurationBloc>().changeEnvironment(false, context.read<AuthBloc>().state).then((Pos? value) {
                    if(value!=null){
                      context.read<AuthBloc>().updatePos(value);
                    }
                  });
                }
              },
              description: LocaleKeys
                  .configurationPos_inputs_productionMode_description
                  .tr(),
              radioButtonLabelTitle:
                  LocaleKeys.configurationPos_inputs_productionMode_label.tr()),
          IziRadioButtonLabel(
              radioButtonType: state.isTest
                  ? RadioButtonType.checkboxChecked
                  : RadioButtonType.checkboxDefault,
              loading: state.status == PosConfigurationStatus.waitingChangeEnvironment && !state.isTest,
              onPressedRadioButton: () {
                if (authState.currentPos == null) {
                  context.read<PosConfigurationBloc>().changeIsTest(true);
                } else {
                  context.read<PageUtilsBloc>().lockPage();
                  context.read<PosConfigurationBloc>().changeEnvironment(true, context.read<AuthBloc>().state).then((Pos? value) {
                    if(value!=null){
                      context.read<AuthBloc>().updatePos(value);
                    }
                  });
                }
              },
              description:
                  LocaleKeys.configurationPos_inputs_testMode_description.tr(),
              radioButtonLabelTitle:
                  LocaleKeys.configurationPos_inputs_testMode_label.tr())
        ],
      ),
    );
  }

  Widget _status(
      ResponsiveUtils ru, AuthState authState, PosConfigurationState state) {
    return IziResume(
      iziResumeType: authState.currentPos?.activo == true
          ? IziResumeType.success
          : IziResumeType.warning,
      status: authState.currentPos != null
          ? authState.currentPos?.activo == true
              ? LocaleKeys.configurationPos_body_okConfiguration.tr()
              : LocaleKeys.configurationPos_body_reviewConfiguration.tr()
          : LocaleKeys.configurationPos_body_noConfiguration.tr(),
      statusLabel: LocaleKeys.configurationPos_body_status.tr(),
      icon: true,
      content: IziText.bodySmall(
          color: IziColors.darkGrey85,
          text: authState.currentPos != null
              ? authState.currentPos?.activo == true
                  ? LocaleKeys.configurationPos_body_okConfigurationDescription
                      .tr()
                  : LocaleKeys
                      .configurationPos_body_reviewConfigurationDescription
                      .tr()
              : LocaleKeys.configurationPos_body_noConfigurationDescription
                  .tr(),
          fontWeight: FontWeight.w400),
    );
  }

  Widget _headerSymbiotic(ResponsiveUtils ru) {
    return Container(
      color: IziColors.white,
      padding: EdgeInsets.symmetric(
          vertical: ru.isXs() ? 16 : 26, horizontal: ru.isXs() ? 17 : 63),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            AssetsKeys.symbioticLogo,
            height: 60,
          ),
          const SizedBox(
            height: 8,
          ),
          IziText.body(
              color: IziColors.dark,
              text: LocaleKeys.configurationPos_subtitles_tapOnPhone.tr(),
              fontWeight: FontWeight.w600),
          const SizedBox(
            height: 8,
          ),
          IziText.body(
              color: IziColors.darkGrey,
              maxLines: 20,
              text: LocaleKeys.configurationPos_subtitles_tapOnPhoneDescription
                  .tr(),
              fontWeight: FontWeight.w400),
        ],
      ),
    );
  }
}
