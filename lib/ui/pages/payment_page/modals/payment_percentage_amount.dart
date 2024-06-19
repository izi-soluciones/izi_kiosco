import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';

class PaymentPercentageAmount extends StatelessWidget {
  final String title;
  final String buttonText;
  final num amount;
  final num? currentValue;
  final TextEditingController _percentageInput = TextEditingController();
  final TextEditingController _amountInput = TextEditingController();
  PaymentPercentageAmount(
      {super.key,
        this.currentValue,
      required this.title,
      required this.amount,
      required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: IziText.title(color: IziColors.dark, text: title),
        ),
        const Divider(
          color: IziColors.grey25,
          height: 1,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ColumnContainer(
              gap: 16,
              children: [
                IziInput(
                  labelInput: LocaleKeys.payment_inputs_percentage_label.tr(),
                  inputHintText:
                      LocaleKeys.payment_inputs_percentage_placeholder.tr(),
                  inputType: InputType.number,
                  value: currentValue == null?null:(100*currentValue!/amount).toStringAsFixed(2),
                  controller: _percentageInput,
                  onChanged: (value,valueRaw){
                    num valor=(num.tryParse(value) ?? 0);
                    if(valor>100){
                      _percentageInput.text = "100";
                      valor = 100;
                    }
                    _amountInput.text = (amount*valor/100).toStringAsFixed(2);
                  },
                ),
                IziInput(
                    labelInput: LocaleKeys.payment_inputs_specificAmount_label.tr(),
                    inputHintText:
                        LocaleKeys.payment_inputs_specificAmount_placeholder.tr(),
                    inputType: InputType.number,
                  value: currentValue?.toStringAsFixed(2),
                  controller: _amountInput,
                    onChanged: (value,valueRaw){
                      num valor=(num.tryParse(value) ?? 0);
                      if(valor>amount){
                        _amountInput.text = amount.toStringAsFixed(2);
                        valor = amount;
                      }
                      _percentageInput.text = (100*valor/amount).toStringAsFixed(2);
                    },
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: IziBtn(
              buttonText: buttonText,
              buttonType: ButtonType.secondary,
              buttonSize: ButtonSize.medium,
              buttonOnPressed: () {
                Navigator.pop(context, num.tryParse(_amountInput.text));
              }),
        )
      ],
    );
  }
}
