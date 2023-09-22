import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn_icon.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';

class MakeOrderItemLg extends StatelessWidget {

  final Item item;
  final MakeOrderState state;
  final VoidCallback onPressed;
  const MakeOrderItemLg({super.key,required this.item,required this.onPressed,required this.state});

  @override
  Widget build(BuildContext context) {
    final itemAdded=_itemAdded(item.id);
    return Material(
      elevation: 0,
      color: IziColors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: IziColors.grey25,width: 1)
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Ink(
                    color: IziColors.grey25,
                    child:
                    item.imagen==null || item.imagen?.isEmpty==true?
                    const FittedBox(child: Icon(IziIcons.dish,color: IziColors.warmLighten)):
                    CachedNetworkImage(
                      imageBuilder: (context, imageProvider) {
                        return Ink.image(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        );
                      },

                      imageUrl: item.imagen??"",
                      fit: BoxFit.cover,
                      placeholder: (context, url) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2,color: IziColors.dark));
                      },
                      errorWidget: (context, url, error)  {
                        return const FittedBox(child: Icon(IziIcons.dish,color: IziColors.warmLighten));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4,horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                         height: 90,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IziText.titleSmall(height: 1.1,maxLines: 2,color: IziColors.dark, text: item.nombre,textAlign: TextAlign.start),
                            const SizedBox(height: 4,),
                            IziText.label(maxLines: 2,color: IziColors.dark, text: item.descripcion??"",textAlign: TextAlign.start,fontWeight: FontWeight.w400),

                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IziText.body(color: IziColors.grey, text: item.precioUnitario.moneyFormat(currency: state.currentCurrency?.simbolo), fontWeight: FontWeight.w400,textAlign: TextAlign.start),
                          const SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: itemAdded!=null?MainAxisAlignment.spaceBetween:MainAxisAlignment.end,
                            children: [
                              if(itemAdded!=null)
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                      maxWidth: 100
                                  ),
                                  child: IziInput(
                                    autoSelect: true,
                                    controller: TextEditingController(text: itemAdded.cantidad.toString())..selection=TextSelection.fromPosition(TextPosition(offset: itemAdded.cantidad.toString().length)),
                                    textAlign: TextAlign.center,
                                    inputHintText: "0",
                                    inputType: InputType.incremental,
                                    minValue: 1,
                                    maxValue: 999999999,
                                    inputSize: InputSize.extraSmall,
                                    value: itemAdded.cantidad.toString(),
                                    onChanged: (value, valueRaw) {
                                      itemAdded.cantidad = num.tryParse(value) ??1;
                                      context.read<MakeOrderBloc>().reloadItems();
                                    },
                                  ),
                                ),
                              if(itemAdded!=null)
                                InkWell(
                                  onTap: (){
                                    _removeItem(itemAdded.id,context);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(2.5),
                                    child: Icon(IziIcons.close,size: 20,color: IziColors.darkGrey,),
                                  ),
                                ),
                              if(itemAdded==null)
                                IziBtnIcon(
                                    buttonIcon: IziIcons.plusB,
                                    buttonType: ButtonType.secondary,
                                    buttonSize: ButtonSize.small,
                                    buttonOnPressed: onPressed
                                ),
                            ],
                          ),
                          const SizedBox(height: 4,),
                        ],
                      )
                    ],
                  ),
                )
              ],
            )
      ),
    );
  }

  _removeItem(int itemId,BuildContext context){
    for(int ic=0;ic<state.itemsSelected.length;ic++){
      var indexItem=state.itemsSelected[ic].items.indexWhere((element) => element.id==itemId);
      if(indexItem!=-1){
        context.read<MakeOrderBloc>().removeItem(ic, indexItem);
      }
    }{
    }
  }

   Item? _itemAdded(int itemId){

    for(var c in state.itemsSelected){
      var indexItem=c.items.indexWhere((element) => element.id==itemId);
      if(indexItem!=-1){
        return c.items[indexItem];
      }
    }
    return null;
  }
}
