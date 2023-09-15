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
              labelInput: LocaleKeys.login_inputs_user_label.tr(),
              inputHintText: LocaleKeys.login_inputs_user_placeholder.tr(),
              autoFillHints: const [AutofillHints.email],
              onChanged: (value,_){
                context.read<LoginBloc>().changeInputsValues(user:value);
              },
              onEditingComplete: (){
                context.read<LoginBloc>().validateInput(user:true);
              },
              error: _getErrorsUser(),
              inputType: InputType.email,
          ),
          const SizedBox(height: 20,),
          IziInput(
              labelInput: LocaleKeys.login_inputs_password_label.tr(),
              inputHintText: LocaleKeys.login_inputs_password_placeholder.tr(),
              autoFillHints: const [AutofillHints.password],
              inputType: InputType.password,
              validator: (value){
                if(value == null || value.isEmpty){
                  return LocaleKeys.login_inputs_password_errors_required.tr();
                }
                return null;
              },
              onChanged: (value,_){
                context.read<LoginBloc>().changeInputsValues(password:value);
              },
              onEditingComplete: (){
                context.read<LoginBloc>().validateInput(password:true);
              },
              error: _getErrorsPassword()
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


  String? _getErrorsUser() {
    if (state.user.inputError == InputError.required) {
      return LocaleKeys.login_inputs_user_errors_required.tr();
    }
    if (state.user.inputError == InputError.invalid) {
      return LocaleKeys.login_inputs_user_errors_invalid.tr();
    }
    if(state.user.inputError!=null){
      return LocaleKeys.general_errors_input.tr();
    }
    return null;
  }

  String? _getErrorsPassword() {
    if (state.password.inputError == InputError.required) {
      return LocaleKeys.login_inputs_password_errors_required.tr();
    }
    if (state.password.inputError == InputError.invalid) {
      return LocaleKeys.login_inputs_password_errors_invalid.tr();
    }
    if(state.password.inputError!=null){
      return LocaleKeys.general_errors_input.tr();
    }
    return null;
  }
}
