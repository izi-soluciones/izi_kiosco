import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
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
    return Stack(
      children: [
        Material(
          elevation: 0,
          color: IziColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: IziColors.grey25,width: 1)
          ),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap:onPressed,
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
                    children: [
                      IziText.titleSmall(maxLines: 5,color: IziColors.dark, text: item.nombre,textAlign: TextAlign.center),
                      IziText.body(color: IziColors.grey, text: item.precioUnitario.moneyFormat(currency: state.currentCurrency?.simbolo), fontWeight: FontWeight.w500,textAlign: TextAlign.center),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
