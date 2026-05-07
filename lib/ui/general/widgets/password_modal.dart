import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_btn_icon.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class PasswordModal extends StatefulWidget {
  final String correctPin;
  const PasswordModal({super.key, required this.correctPin});

  @override
  State<PasswordModal> createState() => _PasswordModalState();
}

class _PasswordModalState extends State<PasswordModal> {
  final TextEditingController _pinController = TextEditingController();

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
        _pinController.text = _pinController.text.substring(
          0,
          _pinController.text.length - 1,
        );
      });
    }
  }

  void _submitPin() {
    if (_pinController.text == widget.correctPin) {
      Navigator.of(context).pop(true);
    } else {
      _pinController.text = "";
      context.read<PageUtilsBloc>().showSnackBar(
        snackBar: SnackBarInfo(
          text: LocaleKeys.passwordModal_errors_wrongPin.tr(),
          snackBarType: SnackBarType.warning,
        ),
      );
    }
  }

  Widget _buildNumberButton(String number, ResponsiveUtils ru) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IziBtn(
        buttonSize: ru.gtSm() ? ButtonSize.large : ButtonSize.medium,
        expandText: true,
        buttonType: ButtonType.primary,
        buttonOnPressed: () => _addDigit(number),
        buttonText: number,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: Colors.white60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(20.0),
                child: IziInput(
                  controller: _pinController,
                  inputSize: ru.gtSm() ? InputSize.big : InputSize.normal,
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
                      for (int i = 1; i <= 3; i++)
                        _buildNumberButton(i.toString(), ru),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 4; i <= 6; i++)
                        _buildNumberButton(i.toString(), ru),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 7; i <= 9; i++)
                        _buildNumberButton(i.toString(), ru),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNumberButton('0', ru),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IziBtnIcon(
                          buttonSize: ru.gtSm() ? ButtonSize.large : ButtonSize.medium,
                          buttonType: ButtonType.primary,
                          buttonOnPressed: _deleteDigit,
                          buttonIcon: Icons.backspace,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IziBtn(
                    buttonSize: ButtonSize.medium,
                    buttonType: ButtonType.secondary,
                    buttonOnPressed: () => _submitPin(),
                    buttonText: LocaleKeys.passwordModal_buttons_confirm.tr(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IziBtn(
                    buttonSize: ButtonSize.medium,
                    buttonType: ButtonType.terciary,
                    buttonOnPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    buttonText: LocaleKeys.passwordModal_buttons_cancel.tr(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
