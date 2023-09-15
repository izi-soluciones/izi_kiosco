import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/hoverStates/on_hover.dart';
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
    return InkWell(
      onTap: onPressed,
      child: OnHover(
        builder: (isHovered) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: IziColors.white,
                  border: Border.all(color: IziColors.grey25,width: 1),
                  borderRadius: BorderRadius.circular(8)
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        color: IziColors.grey25,
                        child:
                        item.imagen==null || item.imagen?.isEmpty==true?
                        const FittedBox(child: Icon(IziIcons.dish,color: IziColors.warmLighten)):
                        CachedNetworkImage(
                          imageUrl: item.imagen??"",
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2,color: IziColors.dark)),
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
              if(isHovered)
              Container(
                decoration: BoxDecoration(
                    color: IziColors.dark.withOpacity(0.1),
                    border: Border.all(color: IziColors.grey25,width: 1),
                    borderRadius: BorderRadius.circular(8)
                ),
              )
            ],
          );
        }
      ),
    );
  }
}
