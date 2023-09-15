import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerListLg extends StatelessWidget {
  const ShimmerListLg({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: IziColors.grey25,
        highlightColor: IziColors.lightGrey30,
        direction: ShimmerDirection.ltr,
        period: const Duration(seconds: 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.only(left: 33,right: 33,top: 33,bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 1/2,
                      child: _shimmerBox(height: 42),
                    ),
                    const SizedBox(height: 38),
                    RowContainer(
                      gap: 16,
                      children: [
                        Expanded(child: _shimmerBox(height: 42),),
                        Expanded(child: _shimmerBox(height: 42),),
                        Expanded(child: _shimmerBox(height: 42),)
                      ],
                    )
                  ],
                ),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 33,vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      flex:1,
                      child: _shimmerBox(height: 12),
                    ),
                    /*const SizedBox(width: 20,),
                    Expanded(
                      flex:2,
                      child: _shimmerBox(height: 40),
                    ),
                    const SizedBox(width: 20,),
                    Expanded(
                      flex:2,
                      child: _shimmerBox(height: 40),
                    ),*/
                    const Expanded(
                      flex:3,
                      child: SizedBox.shrink(),
                    ),
                    SizedBox(
                      width: 120,
                      child: _shimmerBox(height: 20),
                    )
                  ],
                )
            ),
            Expanded(
              child: LayoutBuilder(
                  builder: (context,constraints) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 33),
                      children: _buildShimmerList(screenHeight: constraints.maxHeight),
                    );
                  }
              ),
            )

          ],
        )
    );
  }

  List<Widget> _buildShimmerList({required double screenHeight}){
    double height=60;
    List<Widget> widgets=[];
    int num=(screenHeight/height).ceil();
    for(int i=0;i<num;i++){
      widgets.addAll(
          [
            _shimmerList(height: height),
          ]
      );
    }
    return widgets;
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
  Widget _shimmerBox({required double height}){
    return Container(
      height: height,
      decoration: BoxDecoration(
          color: IziColors.dark,
          borderRadius: BorderRadius.circular(8)
      ),
    );
  }
}