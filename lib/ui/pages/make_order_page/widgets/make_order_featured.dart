import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';

class MakeOrderFeatured extends StatelessWidget {
  final MakeOrderState state;
  const MakeOrderFeatured({super.key,required this.state});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
        itemCount: (state.itemsFeatured.length / 2).round(),
        itemBuilder: (context, index, realIndex) {

          final int first = index * 2;
          final int second = first + 1;
          return Row(
              children: [first, second].map((idx) {
                if(idx>=state.itemsFeatured.length){
                  return const Expanded(child: SizedBox.shrink());
                }
                final item = state.itemsFeatured[idx];
                return Expanded(
                  flex: 1,
                  child: Container(
                    margin: EdgeInsets.only(right: idx==first?10:0),
                    color: context.iziColors.grey25,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: item.imagen==null || item.imagen?.isEmpty==true?
                          FittedBox(child: Icon(IziIcons.dish,color: context.iziColors.warmLighten)):
                          CachedNetworkImage(
                            imageUrl: item.imagen??"",
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2,color: context.iziColors.dark)),
                            errorWidget: (context, url, error)  {
                              return FittedBox(child: Icon(IziIcons.dish,color: context.iziColors.warmLighten));
                            },
                          ),
                        ),
                        Positioned(
                          top: 20,
                          right: 0,
                          left: 0,
                          child: FractionallySizedBox(
                            widthFactor: 0.7,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: context.iziColors.primary,
                                  borderRadius: const BorderRadius.only(topRight: Radius.circular(8),bottomRight: Radius.circular(8))
                              ),
                              padding: const EdgeInsets.all(8),
                              child: IziText.body(color: context.iziColors.white, text: item.nombreMostrar, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList());
        },
        options: CarouselOptions(
          height: 200,
          viewportFraction: 1,
          aspectRatio: 2,
          autoPlay: true,
          enableInfiniteScroll: true,
          disableCenter: true,
          padEnds: false,


        )
    );
  }
}
