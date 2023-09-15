import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/molecules/izi_switch.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';

class MakeOrderDiscountModal extends StatefulWidget {
  final MakeOrderState state;
  const MakeOrderDiscountModal({super.key,required this.state});

  @override
  State<MakeOrderDiscountModal> createState() => _MakeOrderDiscountModalState();
}

class _MakeOrderDiscountModalState extends State<MakeOrderDiscountModal> {
  final List<num> discounts=[5,10,15];
  final List<bool> discountsStatus=[false,false,false];

  TextEditingController amountController= TextEditingController();
  
  bool isAmount=true;

  @override
  void initState() {
    amountController.text=widget.state.discountAmount.toString();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
         Padding(
           padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 18),
           child: IziText.titleSmall(color: IziColors.dark, text: LocaleKeys.makeOrder_subtitles_discounts.tr()),
         ),
        const Divider(color: IziColors.grey25,height: 1,),
        ...discounts.asMap().entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: IziColors.grey25,width: 1))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IziText.body(color: IziColors.darkGrey, text: "-${e.value}%", fontWeight: FontWeight.w600),
                IziSwitch(value: discountsStatus[e.key], onChanged: (value){
                  for(var i=0;i<discountsStatus.length;i++){
                    discountsStatus[i]=false;
                  }
                  discountsStatus[e.key]=value;
                  context.read<MakeOrderBloc>().changeDiscountAmount(num.tryParse((_getMaxAmount()*e.value/100).toStringAsFixed(2)));
                  amountController.text=e.value.toString();
                  setState(() {
                    isAmount=false;
                  });
                })
              ],
            ),
          );
        }).toList(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 16),
          child: IziInput(
            autoSelect: true,
            labelInput: LocaleKeys.makeOrder_inputs_amountOrPercentage_label.tr(),
              inputHintText: LocaleKeys.makeOrder_inputs_amountOrPercentage_placeholder.tr(),
              inputType: InputType.number,
            controller: amountController,
            onChanged: (value,valueRaw){
              for(var i=0;i<discountsStatus.length;i++){
                discountsStatus[i]=false;
              }
              if(isAmount){
                var amount= num.tryParse(value) ?? 0;
                if(amount>_getMaxAmount()){
                  amountController.text="0";
                }
                context.read<MakeOrderBloc>().changeDiscountAmount(amount);
              }
              else{
                var amount= num.tryParse(value) ?? 0;
                if(amount>100){
                  amountController.text="100";
                }
                for(var i=0;i<discounts.length;i++){
                  if(discounts[i]==amount){
                    discountsStatus[i]=true;
                  }
                }
                context.read<MakeOrderBloc>().changeDiscountAmount(num.tryParse((_getMaxAmount()*amount/100).toStringAsFixed(2)));
              }
            },
            suffixWidget: InkWell(
              onTapDown: (tapDetails){
                _openSelection(tapDetails.globalPosition);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IziText.body(color: IziColors.darkGrey, text: isAmount?widget.state.currentCurrency?.simbolo??AppConstants.defaultCurrency:"%", fontWeight: FontWeight.w600),
                  const SizedBox(width: 6,),
                  const Icon(IziIcons.downB,size: 20,color: IziColors.darkGrey,),
                  const SizedBox(width: 10,),
                ],
              ),
            ),
          )
        ),

      ],
    );
  }
  _getMaxAmount(){
    num total =0;
    for(var e in widget.state.itemsSelected){
      for(var i in e.items){
        total += i.cantidad*i.precioUnitario + i.precioModificadores;
      }
    }
    return total;
  }
  _openSelection(Offset offset)async{
    var result= await CustomAlerts.showTapMenu(
        offset,
        [
          TapMenuItem(name: widget.state.currentCurrency?.simbolo??AppConstants.defaultCurrency, value: 0),
          TapMenuItem(name: "%", value: 1),
        ],
        context,
      minWidth: 70
    );
    switch(result){
      case 1:
        setState(() {
          isAmount=false;
        });
        break;
      case 0:
        setState(() {
          isAmount=true;
        });
        break;
    }
  }
}
