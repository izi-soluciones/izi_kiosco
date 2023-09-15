import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn_icon.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';

class MakeOrderItemSm extends StatelessWidget {
  final Item item;
  final MakeOrderState state;
  final VoidCallback onPressed;
  const MakeOrderItemSm(
      {super.key,
      required this.item,
      required this.onPressed,
      required this.state});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IziCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: IziColors.grey25,
                  child: item.imagen == null || item.imagen?.isEmpty == true
                      ? const FittedBox(
                          child:
                              Icon(IziIcons.dish, color: IziColors.warmLighten))
                      : CachedNetworkImage(
                          imageUrl: item.imagen ?? "",
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: IziColors.dark)),
                          errorWidget: (context, url, error) {
                            return const FittedBox(
                                child: Icon(IziIcons.dish,
                                    color: IziColors.warmLighten));
                          },
                        ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IziText.bodyBig(
                        fontWeight: FontWeight.w500,
                          maxLines: 1,
                          color: IziColors.dark,
                          text: item.nombre,
                          textAlign: TextAlign.center),
                      IziText.body(
                          color: IziColors.grey,
                          text: item.precioUnitario.moneyFormat(
                              currency: state.currentCurrency?.simbolo),
                          fontWeight: FontWeight.w500,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: IziBtnIcon(
              buttonIcon: IziIcons.plusB,
              buttonType: ButtonType.secondary,
              buttonSize: ButtonSize.small,
              buttonOnPressed: onPressed
          ),
        )
      ],
    );
  }
}
