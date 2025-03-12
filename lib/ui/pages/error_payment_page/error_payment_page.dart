import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_btn_icon.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
class ErrorPaymentPage extends StatefulWidget {
  const ErrorPaymentPage({super.key});

  @override
  State<ErrorPaymentPage> createState() => _ErrorPaymentPageState();
}

class _ErrorPaymentPageState extends State<ErrorPaymentPage> {
  List<CardPayment> list=[];
  final TextEditingController _pinController = TextEditingController();
  bool usaPin =true;
  String? pin;
  @override
  void initState() {
    LocalStorageCardErrors.getErrors().then((value) {
      for(var e in value){
        list.add(CardPayment.fromJsonStorage(jsonDecode(e)));
      }
      list = list.reversed.toList();
      setState(() {

      });
    });
    pin =context.read<AuthBloc>().state.currentDevice?.config.pin;
    usaPin= pin !=null && pin?.isNotEmpty==true;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final ResponsiveUtils ru =ResponsiveUtils(context);
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child:IziText.titleSmall(color: IziColors.dark, text: "Nº"),
                          ),
                          Expanded(
                            flex: 2,
                            child:IziText.titleSmall(color: IziColors.dark, text: "Respuesta"),
                          ),
                          Expanded(
                            child:IziText.titleSmall(color: IziColors.dark, text: "Fecha"),
                          ),
                          Expanded(
                            flex: 2,
                            child:IziText.titleSmall(color: IziColors.dark, text: "Tarjeta (U. 4 digitos)"),
                          )
                        ],
                      ),
                      const SizedBox(height: 20,),
                      ...list.asMap().entries.map((e) {
                        return
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child:IziText.titleSmall(color: IziColors.dark, text: (e.key+1).toString()),
                                ),
                                Expanded(
                                  flex: 2,
                                  child:IziText.titleSmall(color: IziColors.dark, text: e.value.response),
                                ),
                                Expanded(
                                  child:IziText.titleSmall(color: IziColors.dark, text: "${e.value.date} ${e.value.hour}"),
                                ),
                                Expanded(
                                  flex: 2,
                                  child:IziText.titleSmall(color: IziColors.dark, text: (e.value.cardNumber?.length ?? 0)>4?e.value.cardNumber!.substring(e.value.cardNumber!.length-4,e.value.cardNumber!.length):""),
                                )
                              ],
                            ),
                          );
                      })
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: IziBtn(
                        buttonText: "Cancelar",
                        buttonType: ButtonType.primary,
                        buttonSize: ButtonSize.medium,
                        buttonOnPressed: (){
                          context.read<PageUtilsBloc>().closeScreenActive();
                          GoRouter.of(context).pop();
                        }
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: IziBtn(
                        buttonText: "Cerrar Sesión",
                        buttonType: ButtonType.terciary,
                        buttonSize: ButtonSize.medium,
                        buttonOnPressed: (){
                          context.read<PageUtilsBloc>().closeScreenActive();
                          context.read<AuthBloc>().logout();
                        }
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        if(usaPin)
        Positioned.fill(
          child: _pin(ru),
        )
      ],
    );
  }

  void _addDigit(String digit) {
    if (_pinController.text.length < 4) {
      setState(() {
        _pinController.text += digit;
      });
    }
  }

  void _deleteDigit() {
    if (_pinController.text.isNotEmpty) {
      setState(() {
        _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
      });
    }
  }

  void _submitPin() {
    if(_pinController.text==pin){
      usaPin=false;
      setState(() {});
    }
    else{
      _pinController.text = "";
      context.read<PageUtilsBloc>().showSnackBar(snackBar: SnackBarInfo(text: "El pin no es correcto", snackBarType: SnackBarType.warning));
    }
  }


  Widget _buildNumberButton(String number,ResponsiveUtils ru) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IziBtn(
        buttonSize: ru.gtSm()?ButtonSize.large:ButtonSize.medium,
        expandText: true,
        buttonType: ButtonType.primary,
        buttonOnPressed: () => _addDigit(number),
        buttonText:  number
      ),
    );
  }

  _pin(ResponsiveUtils ru){
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: Container(
        color: Colors.white60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(
                maxWidth: 400
              ),
              padding: const EdgeInsets.all(20.0),
              child: IziInput(
                controller: _pinController,
                inputSize: ru.gtSm()?InputSize.big:InputSize.normal,
                readOnly: true,
                textAlign: TextAlign.center,
                inputHintText: '',
                inputType: InputType.normal,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 1; i <= 3; i++) _buildNumberButton(i.toString(),ru),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 4; i <= 6; i++) _buildNumberButton(i.toString(),ru),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 7; i <= 9; i++) _buildNumberButton(i.toString(),ru),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNumberButton('0',ru),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IziBtnIcon(
                        buttonSize: ru.gtSm()?ButtonSize.large:ButtonSize.medium,
                        buttonType: ButtonType.primary,
                        buttonOnPressed: _deleteDigit,
                        buttonIcon: Icons.backspace,
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            IziBtn(
                buttonSize: ButtonSize.medium,
                expandText: true,
                buttonType: ButtonType.secondary,
                buttonOnPressed: () => _submitPin(),
                buttonText:  "Confirmar"
            ),
          ],
        ),
      ),
    );
  }
}
