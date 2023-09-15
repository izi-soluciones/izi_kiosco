import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:shimmer/shimmer.dart';

class PaymentShimmerPaymentMethod extends StatelessWidget {

  const PaymentShimmerPaymentMethod({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
            decoration: const BoxDecoration(
                color: Colors.white,
                border:
                Border(bottom: BorderSide(color: IziColors.grey25, width: 1))),
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Shimmer.fromColors(
              baseColor: IziColors.grey25,
              highlightColor: IziColors.lightGrey30,
              direction: ShimmerDirection.ltr,
              period: const Duration(seconds: 1),
              child: Stack(
                children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 150,child: _shimmerBox(height: 20)),
                        const SizedBox(height: 10,),
                        SizedBox(width: 150,child: _shimmerBox(height: 35))
                      ],
                    ),
                ],
              ),
            )),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Shimmer.fromColors(
              baseColor: IziColors.grey25,
              highlightColor: IziColors.lightGrey30,
              direction: ShimmerDirection.ltr,
              period: const Duration(seconds: 1),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 444,
                  ),
                  child: _methods(context)),
            ),
          ),
        )
      ],
    );
  }

  Widget _methods(BuildContext context) {
    return ColumnContainer(
      gap: 16,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: _shimmerBox(height: 20),
        ),
        _shimmerBox(height: 60),
        _shimmerBox(height: 60),
        _shimmerBox(height: 60),
        _shimmerBox(height: 60),
        _shimmerBox(height: 60),
        _shimmerBox(height: 60),
        const Divider(height: 1, color: IziColors.grey25),
        _shimmerBox(height: 60),
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
