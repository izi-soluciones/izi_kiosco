import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:shimmer/shimmer.dart';
class ShimmerItemListLg extends StatelessWidget {
  const ShimmerItemListLg({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: IziColors.grey25,
        direction: ShimmerDirection.ltr,
        period: const Duration(seconds: 1),
        highlightColor: IziColors.lightGrey30,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _shimmerList(height: 60),
        )
    );
  }
  Widget _shimmerList({required double height}){
    return Row(
      children: [
        Container(
          height: 14,width: 74,
          margin: const EdgeInsets.only(left: 19),
          decoration: BoxDecoration(
              color: IziColors.dark,
              borderRadius: BorderRadius.circular(20)
          ),
        ),
        const SizedBox(
          width: 16,
        ),
        Expanded(
          flex: 10,
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
              ],
            ),
          ),
        ),
        Container(
          height: 10,
          width: 50,
          margin: const EdgeInsets.only(left:19 ),
          decoration: BoxDecoration(
              color: IziColors.dark,
              borderRadius: BorderRadius.circular(8)
          ),
        )
      ],
    );
  }
}
