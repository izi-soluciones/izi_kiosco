import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

class SelectBusinessForm extends StatelessWidget {
  final AuthState state;

  const SelectBusinessForm({Key? key,required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IziText.bodyBig(text: LocaleKeys.selectBusiness_subtitles_select.tr(), color: IziColors.dark,fontWeight: FontWeight.w600),
          const SizedBox(height: 25,),
          IziInput(
              labelInput: LocaleKeys.selectBusiness_inputs_contribuyente_label.tr(),
              inputHintText: LocaleKeys.selectBusiness_inputs_contribuyente_placeholder.tr(),
              value: state.currentContribuyente?.id,
              selectOptions: {
                for(var c in state.contribuyentes??[]) c.id:c.nombre
              },
              onSelected: (value) {
                int contribuyenteIndex=(state.contribuyentes??[]).indexWhere((element) => element.id==value);
                if(contribuyenteIndex!=-1){
                  context.read<AuthBloc>().updateContribuyente(state.contribuyentes![contribuyenteIndex], 0);
                }
              },
              inputType: InputType.select,
          ),
          const SizedBox(height: 20,),
          /*IziInput(
            labelInput: LocaleKeys.selectBusiness_inputs_sucursal_label.tr(),
            inputHintText: LocaleKeys.selectBusiness_inputs_sucursal_placeholder.tr(),
            value: state.currentSucursal?.id,
            selectOptions: {
              for(var c in state.currentContribuyente?.sucursales??[]) c.id:c.nombre
            },
            onSelected: (value) {
              int sucursalIndex=(state.currentContribuyente?.sucursales??[]).indexWhere((element) => element.id==value);
              if(sucursalIndex!=-1){
                context.read<AuthBloc>().updateSucursal(state.currentContribuyente!.sucursales![sucursalIndex]);
              }
            },
            inputType: InputType.select,
          ),
          const SizedBox(height: 30,),*/
          IziBtn(
            buttonOnPressed:(){
              GoRouter.of(context).goNamed(RoutesKeys.kioskList);
            },
            buttonSize: ButtonSize.medium,
            buttonText: LocaleKeys.selectBusiness_buttons_accept.tr(),
            buttonType: ButtonType.primary,
          ),

        ],
      ),
    );
  }
}
