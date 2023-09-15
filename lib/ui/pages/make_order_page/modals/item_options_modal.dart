import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_radio_button.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_switch.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';

class ItemOptionsModal extends StatefulWidget {

  final Item item;
  final MakeOrderState state;
  const ItemOptionsModal({super.key,required this.item,required this.state});

  @override
  State<ItemOptionsModal> createState() => _ItemOptionsModalState();
}

class _ItemOptionsModalState extends State<ItemOptionsModal> {
  Item? itemEdit;
  int? indexRequired;

  List<GlobalKey> titleKeys = [];
  @override
  void initState() {
    itemEdit = widget.item.copyWith();
    for(var _ in itemEdit?.modificadores??[]){
      titleKeys.add(GlobalKey());
    }
    super.initState();
  }

  _verifyRequired(){
    for(int i=0;i<(itemEdit?.modificadores.length ?? 0);i++){

      var ver=false;
      for(var car in (itemEdit?.modificadores[i].caracteristicas ?? [])){
        if(itemEdit?.modificadores[i].isObligatorio == false || car.check){
          ver =true;
        }
      }
      if(!ver){
        setState(() {
          indexRequired=i;
        });
        if(titleKeys[i].currentContext!=null){
          Scrollable.ensureVisible(titleKeys[i].currentContext!);
        }
        return false;
      }
    }
    setState(() {
      indexRequired=null;
    });
    return true;
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 32),
          child: IziText.title(color: IziColors.dark, text: LocaleKeys.makeOrder_subtitles_itemOptions.tr(args: [itemEdit?.nombre??""])),
        ),
        const Divider(color: IziColors.grey25,height: 1,),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:(itemEdit?.modificadores??[]).asMap().entries.map((entry) {
                      var e1 = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16,),
                            Padding(
                              key: titleKeys[entry.key],
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: IziText.titleSmall(color: entry.key==indexRequired?IziColors.red:IziColors.dark, text: e1.nombre+(e1.isObligatorio?"*":"")),
                            ),
                            ...e1.caracteristicas.asMap().entries.map((e2) {
                              return InkWell(
                                onTap: (){
                                  if(e1.isMultiple){
                                    setState(() {
                                      e2.value.check=!e2.value.check;
                                    });
                                  }
                                  else{
                                    setState(() {
                                      var lastCheck=e2.value.check;
                                      for(var ca in e1.caracteristicas){
                                        ca.check=false;
                                      }
                                      e2.value.check=!lastCheck;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 18,horizontal: 32),
                                  decoration: BoxDecoration(
                                      border: e2.key<e1.caracteristicas.length-1?const Border(bottom: BorderSide(color: IziColors.grey25,width: 1)):null
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IziText.body(color: IziColors.darkGrey, text: "${e2.value.nombre}${e2.value.modPrecio>0? " (+${e2.value.modPrecio.moneyFormat(currency: widget.state.currentCurrency?.simbolo)})":""}", fontWeight: FontWeight.w600),
                                      e1.isMultiple?
                                      IziSwitch( value: e2.value.check, onChanged: (value){
                                        setState(() {
                                          e2.value.check=value;
                                        });
                                      }):
                                          IziRadioButton(
                                              onPressed: (){
                                                setState(() {
                                                  var lastCheck=e2.value.check;
                                                  for(var ca in e1.caracteristicas){
                                                    ca.check=false;
                                                  }
                                                  e2.value.check=!lastCheck;
                                                });
                                              },
                                              radioButtonType: e2.value.check?RadioButtonType.checkboxChecked:RadioButtonType.checkboxDefault
                                          )
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 16,),
                          ],
                        );
                      }).toList()
                  ),
                ),
              ),
            ]

          ),
        ),
        const SizedBox(height: 16,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: IziBtn(
              buttonText: LocaleKeys.makeOrder_buttons_accept.tr(),
              buttonType: ButtonType.primary,
              buttonSize: ButtonSize.medium,
              buttonOnPressed: (){
                if(_verifyRequired()){
                  Navigator.pop(context,itemEdit);
                }

              }
          ),
        ),
        const SizedBox(height: 32,),
      ],
    );
  }
}
