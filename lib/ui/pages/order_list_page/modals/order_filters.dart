import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/dto/filters_comanda.dart';
import 'package:izi_kiosco/ui/general/headers/back_modal_header.dart';
import 'package:izi_kiosco/domain/utils/date_formatter.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class OrderFilters extends StatefulWidget {

  final FiltersComanda filtersComanda;



  const OrderFilters({super.key,required this.filtersComanda});

  @override
  State<OrderFilters> createState() => _OrderFiltersState();
}

class _OrderFiltersState extends State<OrderFilters> {
  TextEditingController statusController=TextEditingController();
  String? status;
  TextEditingController dateStartController=TextEditingController();
  DateTime? dateStart;

  TextEditingController dateEndController=TextEditingController();
  DateTime? dateEnd;

  @override
  void initState() {
    setState(() {
      status = widget.filtersComanda.status ?? "";
      dateStart = widget.filtersComanda.dateStart;
      dateEnd = widget.filtersComanda.dateEnd;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BackModalHeader(title: LocaleKeys.orderList_filters_title.tr()),
          const SizedBox(height: 16,),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RowContainer(
                    gap: 8,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: IziInput(
                          background: IziColors.white,
                          labelInput: LocaleKeys.orderList_inputs_status_label.tr(),
                          inputHintText: LocaleKeys.orderList_inputs_status_placeholder.tr(),
                          inputType: InputType.select,
                          value: widget.filtersComanda.status ?? "",
                          controller: statusController,
                          selectOptions: {
                            "":LocaleKeys.orderList_inputs_status_options_all.tr(),
                            "Facturadas":LocaleKeys.orderList_inputs_status_options_invoiced.tr(),
                            "Sin Facturar":LocaleKeys.orderList_inputs_status_options_noInvoiced.tr(),
                            "Abiertas":LocaleKeys.orderList_inputs_status_options_opened.tr(),
                            "Finalizadas":LocaleKeys.orderList_inputs_status_options_ended.tr(),
                            "Anuladas":LocaleKeys.orderList_inputs_status_options_annulled.tr(),
                          },
                          onSelected: (value){
                            setState(() {
                              status= value;
                            });
                          },
                        ),
                      ),
                      if(status != null && status != "")
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: (){
                            statusController.text=LocaleKeys.orderList_inputs_status_options_all.tr();
                            setState(() {
                              status="";
                            });
                          },
                          child: const Icon(
                            IziIcons.close,
                            size: 30,
                            color: IziColors.grey,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16,),
                  RowContainer(
                    gap: 8,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: IziInput(
                          background: IziColors.white,
                          labelInput: LocaleKeys.orderList_inputs_dateStart_label.tr(),
                          inputHintText: LocaleKeys.orderList_inputs_dateStart_placeholder.tr(),
                          inputType: InputType.datePicker,
                          controller: dateStartController,
                          value: widget.filtersComanda.dateStart?.dateFormat(DateFormatterType.visual),
                          currentDate: DateTime.now(),
                          onChanged: (value,valueRaw){
                            setState(() {
                              dateStart= valueRaw;
                            });
                          },
                          prefixText: LocaleKeys.orderList_inputs_dateStart_prefix.tr(),
                        ),
                      ),
                      if(dateStart != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: (){
                            dateStartController.text="";
                            setState(() {
                              dateStart = null;
                            });
                          },
                          child: const Icon(
                            IziIcons.close,
                            size: 30,
                            color: IziColors.grey,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16,),
                  RowContainer(
                    gap: 8,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: IziInput(
                          background: IziColors.white,
                          inputHintText: LocaleKeys.orderList_inputs_dateEnd_placeholder.tr(),
                          inputType: InputType.datePicker,
                          value: widget.filtersComanda.dateEnd?.dateFormat(DateFormatterType.visual),
                          currentDate: DateTime.now(),
                          controller: dateEndController,
                          onChanged: (value,valueRaw){
                            setState(() {
                              dateEnd= valueRaw;
                            });
                          },
                          prefixText: LocaleKeys.orderList_inputs_dateEnd_prefix.tr(),
                        ),
                      ),
                      if(dateEnd != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: (){
                            dateEndController.text="";
                            setState(() {
                              dateEnd = null;
                            });
                          },
                          child: const Icon(
                            IziIcons.close,
                            size: 30,
                            color: IziColors.grey,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 40,),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16,left: 16,right: 16),
            child: IziBtn(
                buttonText: LocaleKeys.orderList_filters_buttons_apply.tr(),
                buttonType: ButtonType.primary,
                buttonSize: ButtonSize.medium,
                buttonOnPressed: (){
                  widget.filtersComanda.dateEnd=dateEnd;
                  widget.filtersComanda.dateStart=dateStart;
                  widget.filtersComanda.status=status;
                  Navigator.of(context).pop(widget.filtersComanda);
                }
            ),
          ),

        ],
      ),
    );
  }
}
