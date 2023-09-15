import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:shimmer/shimmer.dart';
class ShimmerItemListSm extends StatelessWidget {
  const ShimmerItemListSm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: IziColors.grey25,
        direction: ShimmerDirection.ltr,
        period: const Duration(seconds: 1),
        highlightColor: IziColors.lightGrey30,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _shimmerList(height: 83),
        )
    );
  }
  Widget _shimmerList({required double height}){
    return Row(
      children: [
        Container(
          height: 12,width: 12,
          decoration: BoxDecoration(
              color: IziColors.dark,
              borderRadius: BorderRadius.circular(20)
          ),
        ),
        const SizedBox(
          width: 16,
        ),
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Container(
                  height: 10,
                  decoration: BoxDecoration(
                      color: IziColors.dark,
                      borderRadius: BorderRadius.circular(8)
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 1/3,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                        color: IziColors.dark,
                        borderRadius: BorderRadius.circular(8)
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 2/3,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                        color: IziColors.dark,
                        borderRadius: BorderRadius.circular(8)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Expanded(
            flex: 3,
            child: SizedBox.shrink()
        ),
        Container(
          height: 14,
          width: 100,
          decoration: BoxDecoration(
              color: IziColors.dark,
              borderRadius: BorderRadius.circular(8)
          ),
        )
      ],
    );
  }
}
