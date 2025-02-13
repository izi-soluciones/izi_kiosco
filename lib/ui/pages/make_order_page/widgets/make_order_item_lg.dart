import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn_icon.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class MakeOrderItemLg extends StatelessWidget {

  final Item item;
  final MakeOrderState state;
  final VoidCallback onPressed;
  const MakeOrderItemLg({super.key,required this.item,required this.onPressed,required this.state});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Material(
      elevation: 0,
      color: IziColors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: IziColors.grey25,width: 1)
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Column(
              mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
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
                      padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IziText.titleSmall(height: 1.1,maxLines: 3,color: IziColors.dark, text: item.nombre,textAlign: TextAlign.start),
                              if(item.descripcion!=null)
                              const SizedBox(height: 4,),
                              if(item.descripcion!=null)
                              IziText.label(maxLines: 5,color: IziColors.darkGrey85, text: item.descripcion??"",textAlign: TextAlign.start,fontWeight: FontWeight.w400),

                            ],
                          ),

                          IziText.titleSmall(color: IziColors.darkGrey, text: item.precioUnitario.moneyFormat(currency: state.currentCurrency?.simbolo), fontWeight: FontWeight.w400,textAlign: TextAlign.start),
                          if(ru.isVertical() && ru.gtSm())
                          const SizedBox(height: 10,),

                        ],
                      ),
                    )
                  ],
                ),
                if(ru.isVertical() && ru.gtSm())
                  Padding(
                  padding: const EdgeInsets.only(bottom: 16,left: 16,right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IziBtnIcon(
                          buttonIcon: IziIcons.plusB,
                          buttonType: ButtonType.secondary,
                          buttonSize: ButtonSize.medium,
                          buttonOnPressed: onPressed
                      ),
                    ],
                  ),
                ),
              ],
            )
      ),
    );
  }
}
