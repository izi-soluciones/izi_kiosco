import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_header_sm.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:shimmer/shimmer.dart';

class MakeOrderShimmer extends StatelessWidget {
  final MakeOrderState state;
  const MakeOrderShimmer({super.key,required this.state});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ru.isXs()) MakeOrderHeaderSm(state: state),
        Expanded(
            child: Shimmer.fromColors(
              baseColor: IziColors.grey25,
              highlightColor: IziColors.lightGrey30,
              direction: ShimmerDirection.ltr,
              period: const Duration(seconds: 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              SizedBox(
                width: 120,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: ColumnContainer(
                    gap: 16,
                    children: [
                      ...List.generate(8, (index) {
                        return SizedBox(
                            child: _shimmerBox(height: 88));
                      })
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ru.isXs()
                    ? ListView.separated(
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 12);
                        },
                        padding: const EdgeInsets.only(
                            top: 16, right: 16, left: 16, bottom: 63),
                        itemBuilder: (context, index) {
                          return _shimmerBox(height: 76);
                        },
                        itemCount: 10,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(
                            top: 16, right: 32, left: 32, bottom: 63),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: ru.isXl()
                                ? 6
                                : ru.isMdLg()
                                    ? 3
                                    : ru.isLg()
                                        ? 4
                                        : 3,
                            childAspectRatio: 1.4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 18),
                        itemCount: 10,
                        itemBuilder: (BuildContext context, int index) {
                          return _shimmerBox(height: 10);
                        },
                      ),
              )
          ],
        ),
            ))
      ],
    );
  }

  Widget _shimmerBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
          color: IziColors.dark, borderRadius: BorderRadius.circular(8)),
    );
  }
}
