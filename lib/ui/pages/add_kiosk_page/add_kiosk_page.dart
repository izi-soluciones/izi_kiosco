import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/add_kiosk/add_kiosk_bloc.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/dto/add_kiosk_dto.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
class AddKioskPage extends StatefulWidget {
  const AddKioskPage({Key? key}) : super(key: key);

  @override
  State<AddKioskPage> createState() => _AddKioskPageState();
}

class _AddKioskPageState extends State<AddKioskPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController cashRegisterController = TextEditingController();
  bool nameError=false;
  int? branchOffice;
  bool branchOfficeError=false;
  int? cashRegister;
  bool cashRegisterError=false;
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddKioskBloc,AddKioskState>(
      listener: (context, state) {
        if(state.status == AddKioskStatus.okCashRegister){
          context.read<PageUtilsBloc>().closeLoading();
        }
        if(state.status == AddKioskStatus.okSave){
          context.read<AuthBloc>().getKiosks().then((value){
            context.read<PageUtilsBloc>().closeLoading();
            context.read<PageUtilsBloc>().showSnackBar(snackBar: SnackBarInfo(
                text: LocaleKeys.kioskNew_messages_successSave, snackBarType: SnackBarType.success));
            GoRouter.of(context).goNamed(RoutesKeys.kioskList);
          });
        }
        if(state.status == AddKioskStatus.errorSave){
          context.read<PageUtilsBloc>().closeLoading();
          context.read<PageUtilsBloc>().showSnackBar(snackBar: SnackBarInfo(
              text: LocaleKeys.kioskNew_messages_errorSave, snackBarType: SnackBarType.error));
        }
        if(state.status == AddKioskStatus.errorCashRegister){
          context.read<PageUtilsBloc>().closeLoading();
          context.read<PageUtilsBloc>().showSnackBar(snackBar: SnackBarInfo(
              text: LocaleKeys.kioskNew_messages_errorCashRegisters, snackBarType: SnackBarType.error));
        }
      },
        builder: (context,state) {
          return Stack(
            children: [
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Image.asset(
                        AssetsKeys.cityGraphic,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  )),
              Positioned.fill(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: (){
                                  GoRouter.of(context).goNamed(RoutesKeys.kioskList);
                                },
                                child: const Icon(
                                  IziIcons.leftB,
                                  size: 32,
                                  color: IziColors.darkGrey,
                                ),
                              ),
                              Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.all(16),
                                  child: const FittedBox(
                                      fit: BoxFit.fill,
                                      child: Icon(IziIcons.izi,color: IziColors.primary)
                                  )
                              ),
                            ],
                          ),
                          IziText.titleMedium(
                              color: IziColors.dark,
                              text: LocaleKeys.kioskNew_title.tr()
                          ),
                          Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 600,
                                  ),
                                  child: _kioskForm(state),
                                ),
                              )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            ],
          );
        }
    );
  }

  _kioskForm(AddKioskState state){
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      children: [
        IziInput(
          labelInput: LocaleKeys.kioskNew_inputs_name_label.tr(),
            inputHintText: LocaleKeys.kioskNew_inputs_name_placeholder.tr(),
            inputType: InputType.normal,
          onChanged: (value,valueRaw){
            _errorName();
          },
          error: nameError?LocaleKeys.kioskNew_inputs_name_error:null,
          controller: nameController,
        ),
        const SizedBox(height: 16,),
        IziInput(
          labelInput: LocaleKeys.kioskNew_inputs_branchOffice_label.tr(),
          inputHintText: "",
          selectOptions: {
            for(Sucursal s in (context.read<AuthBloc>().state.currentContribuyente?.sucursales??[])) s.id:s.nombre??""
          },
          onSelected: (val){
            if(val is int){
              context.read<PageUtilsBloc>().showLoading(LocaleKeys.kioskNew_messages_waitingCashRegisters);
              context.read<AddKioskBloc>().getCashRegisters(val, context.read<AuthBloc>().state);
              setState(() {
                branchOffice=val;
                cashRegister=null;
                cashRegisterController.text="";
              });
              _errorBranchOffice();
            }
          },
          error: branchOfficeError?LocaleKeys.kioskNew_inputs_branchOffice_error:null,
          inputType: InputType.select,
        ),
        const SizedBox(height: 16,),
        IziInput(
          labelInput: LocaleKeys.kioskNew_inputs_cashRegister_label.tr(),
          inputHintText: LocaleKeys.kioskNew_inputs_cashRegister_placeholder.tr(),
          inputType: InputType.select,
          controller: cashRegisterController,
          selectOptions: {
            for(CashRegister s in state.cashRegisters) s.id:s.nombre
          },
          onSelected: (val){
            if(val is int){
              setState(() {
                cashRegister=val;
              });
            }
            _errorCashRegister();
          },
          error: cashRegisterError?LocaleKeys.kioskNew_inputs_cashRegister_error:null,
        ),
        const SizedBox(height: 16,),
        IziBtn(
            buttonText: LocaleKeys.kioskNew_button_add.tr(),
            buttonType: ButtonType.primary,
            buttonSize: ButtonSize.large,
            buttonOnPressed: nameError ||  branchOffice==null || cashRegister==null?null:(){
              _save();
            }
        )

      ],
    );
  }
  _save(){
    if(_verifyErrors()){
      return;
    }
    context.read<PageUtilsBloc>().showLoading(LocaleKeys.kioskNew_messages_waitingSave);
    var addKioskDto = AddKioskDto(
        branchOffice: branchOffice??0,
        cashRegister: cashRegister??0,
        business: context.read<AuthBloc>().state.currentContribuyente?.id??0,
        name: nameController.text
    );
    context.read<AddKioskBloc>().save(addKioskDto);
  }

  _errorCashRegister(){
    if(cashRegister==null){
      setState(() {
        cashRegisterError=true;
      });
    }
    else if(cashRegisterError){
      setState(() {
        cashRegisterError = false;
      });
    }
  }
  _errorBranchOffice(){
    if(branchOffice==null){
      setState(() {
        branchOfficeError=true;
      });
    }
    else if(branchOfficeError){
      setState(() {
        branchOfficeError=false;
      });
    }
  }
  _errorName(){
    if(nameController.text.isEmpty){
      setState(() {
        nameError=true;
      });
    }
    else if(nameError){
      setState(() {
        nameError=false;
      });
    }
  }
  _verifyErrors(){
    _errorBranchOffice();
    _errorCashRegister();
    _errorName();
    return cashRegisterError || branchOfficeError || nameError;
  }
}
