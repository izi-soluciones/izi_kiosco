import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/ui/general/headers/back_modal_header.dart';

class NumberDinersModal extends StatefulWidget {
  final int? diners;
  const NumberDinersModal(
      {super.key,  this.diners});

  @override
  State<NumberDinersModal> createState() =>
      _NumberDinersModalState();
}

class _NumberDinersModalState extends State<NumberDinersModal> {
  int? numberDiners;
  @override
  void initState() {
    numberDiners = widget.diners ?? 1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackModalHeader(title: LocaleKeys.makeOrder_subtitles_numberDinners.tr()),
        const SizedBox(
          height: 22,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 150,
                child: IziInput(
                  inputHintText:"0",
                  inputType: InputType.incremental,
                  minValue: 1,
                  maxValue: 99999,
                  value: numberDiners.toString(),
                  onChanged: (value,valueRaw){
                    setState(() {
                      numberDiners=int.tryParse(value) ?? 1;
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 27,
              ),
              IziBtn(
                  buttonText: LocaleKeys.tables_buttons_continue.tr(),
                  buttonType: ButtonType.primary,
                  buttonSize: ButtonSize.medium,
                  buttonOnPressed: () {
                    Navigator.of(context).pop(numberDiners);
                  }),
              const SizedBox(
                height: 43,
              ),
            ],
          ),
        )
      ],
    );
  }
}
