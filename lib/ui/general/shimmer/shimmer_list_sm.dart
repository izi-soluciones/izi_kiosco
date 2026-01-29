import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:shimmer/shimmer.dart';
class ShimmerListSm extends StatelessWidget {
  const ShimmerListSm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: context.iziColors.grey25,
        direction: ShimmerDirection.ltr,
        period: const Duration(seconds: 1),


        highlightColor: context.iziColors.lightGrey30,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 11),
              child: Row(
                children: [
                  Expanded(
                      child: _shimmerBox(context,height: 40)),
                  const SizedBox(width:16,),
                  SizedBox(
                      width: 70,
                      child: _shimmerBox(context,height: 20)
                  )
                ],
              ),
            ),
            /*Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 15),
                child: FractionallySizedBox(
                    widthFactor: 1/3,
                    child: _shimmerBox(height: 14)
                )
            ),*/
            Expanded(
              child: LayoutBuilder(
                  builder: (context,constraints) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: _buildShimmerList(context,screenHeight: constraints.maxHeight),
                    );
                  }
              ),
            )

          ],
        )
    );
  }

  List<Widget> _buildShimmerList(BuildContext context,{required double screenHeight}){
    double height=83;
    List<Widget> widgets=[];
    int num=(screenHeight/height).ceil();
    for(int i=0;i<num;i++){
      widgets.addAll(
          [
            _shimmerList(context,height: height),
          ]
      );
    }
    return widgets;
  }
  Widget _shimmerList(BuildContext context,{required double height}){
    return Row(
      children: [
        Container(
          height: 12,width: 12,
          decoration: BoxDecoration(
              color: context.iziColors.dark,
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
                      color: context.iziColors.dark,
                      borderRadius: BorderRadius.circular(8)
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 1/3,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                        color: context.iziColors.dark,
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
                        color: context.iziColors.dark,
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
              color: context.iziColors.dark,
              borderRadius: BorderRadius.circular(8)
          ),
        )
      ],
    );
  }
  Widget _shimmerBox(BuildContext context,{required double height}){
    return Container(
      height: height,
      decoration: BoxDecoration(
          color: context.iziColors.dark,
          borderRadius: BorderRadius.circular(8)
      ),
    );
  }
}
