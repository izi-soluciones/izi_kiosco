import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/ui/general/headers/back_modal_header.dart';

class MakeOrderEditTableModal extends StatefulWidget {
  final List<ConsumptionPoint> tables;
  final String? tableSelect;
  const MakeOrderEditTableModal(
      {super.key, required this.tables, required this.tableSelect});

  @override
  State<MakeOrderEditTableModal> createState() =>
      _MakeOrderEditTableModalState();
}

class _MakeOrderEditTableModalState extends State<MakeOrderEditTableModal> {
  String? newTableSelect;
  @override
  void initState() {
    newTableSelect = widget.tableSelect;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BackModalHeader(title: LocaleKeys.makeOrder_subtitles_editTable.tr()),
        const SizedBox(
          height: 22,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              IziInput(
                inputHintText:
                    LocaleKeys.makeOrder_inputs_table_placeholder.tr(),
                labelInput: LocaleKeys.makeOrder_inputs_table_label.tr(),
                inputType: InputType.select,
                value: widget.tableSelect,
                selectOptions: {
                  for (var table in widget.tables) table.id: table.nombre
                },
                onSelected: (value) {
                  if (value is String) {
                    setState(() {
                      newTableSelect = value;
                    });
                  }
                },
              ),
              const SizedBox(
                height: 27,
              ),
              IziBtn(
                  buttonText: LocaleKeys.makeOrder_buttons_save.tr(),
                  buttonType: ButtonType.primary,
                  buttonSize: ButtonSize.medium,
                  buttonOnPressed: () {
                    Navigator.of(context).pop(newTableSelect);
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
