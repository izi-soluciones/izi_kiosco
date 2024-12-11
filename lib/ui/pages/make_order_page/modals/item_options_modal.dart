import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_radio_button.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/molecules/izi_switch.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/headers/back_modal_header.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
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
  final ScrollController _scrollController = ScrollController();

  List<GlobalKey> titleKeys = [];
  @override
  void initState() {
    itemEdit = widget.item.copyWith();
    for(Modifier m in itemEdit?.modificadores??[]){
      titleKeys.add(GlobalKey());
      var existList = m.caracteristicas.where((element) => element.check);

      if(existList.isEmpty){
        for(ModifierItem c in m.caracteristicas){
          if(c.defaultValue){
            c.check=true;
          }
        }
      }
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
    return BlocListener<PageUtilsBloc,PageUtilsState>(
      listener: (context, state) {
        if(state.screenActive==false){
          if(itemEdit != null){
            context.read<MakeOrderBloc>().setItemModal(itemEdit!);
          }
          Navigator.pop(context);
        }
      },
      child: Listener(
        onPointerDown: (e) {
          context.read<PageUtilsBloc>().updateScreenActive();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            BackModalHeader(title: LocaleKeys.makeOrder_subtitles_itemOptions.tr(args: [itemEdit?.nombre??""])),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: IziScroll(
                      scrollController: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children:(itemEdit?.modificadores??[]).asMap().entries.map((entry) {
                            var e1 = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                      border:Border(bottom: BorderSide(color: IziColors.grey25,width: 1))
                                  ),
                                  child: ExpansionTile(
                                    key: titleKeys[entry.key],
                                    initiallyExpanded: e1.isObligatorio,
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 32,vertical: 8),
                                    title: IziText.titleSmall(color: entry.key==indexRequired?IziColors.red:IziColors.dark, text: e1.nombre+(e1.isObligatorio?"*":"")),
                                    children:
                                    e1.caracteristicas.asMap().entries.map((e2) {
                                      return InkWell(
                                        onTap: (){
                                          if(e1.isMultiple){
                                            setState(() {
                                              e2.value.check=!e2.value.check;
                                            });
                                          }
                                          else if(e1.isLimitado!=null){
                                            int count = 0;
                                            for(var i in e1.caracteristicas){
                                              if(i.check){
                                                count++;
                                              }
                                            }
                                            if(count<e1.isLimitado! || e2.value.check){
                                              setState(() {
                                                e2.value.check=!e2.value.check;
                                              });
                                            }
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
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(child: IziText.body(color: IziColors.darkGrey, text: "${e2.value.nombre}${e2.value.modPrecio>0? " (+${e2.value.modPrecio.moneyFormat(currency: widget.state.currentCurrency?.simbolo)})":""}", fontWeight: FontWeight.w400)),
                                              e1.isMultiple || e1.isLimitado!=null?
                                              IziSwitch( value: e2.value.check, onChanged: (value){
                                                setState(() {
                                                  if(e1.isMultiple){
                                                    e2.value.check=value;
                                                  }
                                                  else{
                                                    int count = 0;
                                                    for(var i in e1.caracteristicas){
                                                      if(i.check){
                                                        count++;
                                                      }
                                                    }
                                                    if(count<e1.isLimitado! || !value){
                                                      e2.value.check=value;
                                                    }
                                                  }
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
                                  ),
                                ),
                              ],
                            );
                            }).toList()
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 8),
                    child: IziInput(
                      background: IziColors.white,
                      labelInput: LocaleKeys.makeOrder_inputs_comments_label.tr(),
                      inputHintText: LocaleKeys.makeOrder_inputs_comments_placeholder.tr(),
                      inputType: InputType.textArea,
                      value: widget.item.detalle,
                      onChanged: (value,valueRaw){
                        context.read<PageUtilsBloc>().updateScreenActive();
                        setState(() {
                          itemEdit?.detalle=value;
                        });
                      },
                      minLines: 4,
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
        ),
      ),
    );
  }
}
