import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/login/login_bloc.dart';
import 'package:izi_kiosco/domain/utils/input_obj.dart';

class LoginForm extends StatelessWidget {
  final LoginState state;

  const LoginForm({Key? key,required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IziText.titleBig(text: LocaleKeys.login_subtitles_enterIzi.tr(), color: IziColors.dark),
          const SizedBox(height: 25,),
          IziInput(
              labelInput: LocaleKeys.login_inputs_token_label.tr(),
              inputHintText: LocaleKeys.login_inputs_token_placeholder.tr(),
              onChanged: (value,_){
                context.read<LoginBloc>().changeInputsValues(token:value);
              },
              onEditingComplete: (){
                context.read<LoginBloc>().validateInput(token:true);
              },
              error: _getErrorsToken(),
              inputType: InputType.normal,
          ),
          const SizedBox(height: 20,),
          IziInput(
              labelInput: LocaleKeys.login_inputs_tokenCard_label.tr(),
              inputHintText: LocaleKeys.login_inputs_tokenCard_placeholder.tr(),
              inputType: InputType.normal,
              validator: (value){
                if(value == null || value.isEmpty){
                  return LocaleKeys.login_inputs_tokenCard_errors_required.tr();
                }
                return null;
              },
              onChanged: (value,_){
                context.read<LoginBloc>().changeInputsValues(tokenCard:value);
              },
              onEditingComplete: (){
                context.read<LoginBloc>().validateInput(tokenCard:true);
              },
          ),
          const SizedBox(height: 20,),
          IziInput(
              labelInput: LocaleKeys.login_inputs_deviceId_label.tr(),
              inputHintText: LocaleKeys.login_inputs_deviceId_placeholder.tr(),
              inputType: InputType.number,
              validator: (value){
                if(value == null || value.isEmpty){
                  return LocaleKeys.login_inputs_deviceId_errors_required.tr();
                }
                return null;
              },
              onChanged: (value,_){
                context.read<LoginBloc>().changeInputsValues(deviceId:value);
              },
              onEditingComplete: (){
                context.read<LoginBloc>().validateInput(deviceId:true);
              },
              error: _getErrorsDeviceId()
          ),
          const SizedBox(height: 30,),
          IziBtn(
            buttonOnPressed:(){
              BlocProvider.of<LoginBloc>(context).login();
            },
            loading:state.status==LoginStatus.waitingLogin,
            buttonSize: ButtonSize.medium,
            buttonText: LocaleKeys.login_buttons_login.tr(),
            buttonType: ButtonType.primary,
          ),

        ],
      ),
    );
  }


  String? _getErrorsToken() {
    if (state.token.inputError == InputError.required) {
      return LocaleKeys.login_inputs_token_errors_required.tr();
    }
    if (state.token.inputError == InputError.invalid) {
      return LocaleKeys.login_inputs_token_errors_invalid.tr();
    }
    if(state.token.inputError!=null){
      return LocaleKeys.general_errors_input.tr();
    }
    return null;
  }

  String? _getErrorsDeviceId() {
    if (state.deviceId.inputError == InputError.required) {
      return LocaleKeys.login_inputs_deviceId_errors_required.tr();
    }
    if (state.deviceId.inputError == InputError.invalid) {
      return LocaleKeys.login_inputs_deviceId_errors_invalid.tr();
    }
    if(state.deviceId.inputError!=null){
      return LocaleKeys.general_errors_input.tr();
    }
    return null;
  }
}
