import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_header_sm.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';
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
              child: Column(
          children: [
              if (ru.isXs())
                Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, top: 16),
                    child: _shimmerBox(height: 48)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    EdgeInsets.symmetric(horizontal: ru.isXs()?16:32, vertical: 16),
                child: RowContainer(
                  gap: 16,
                  children: [
                    if (ru.gtXs())
                      Row(
                        children: [
                          SizedBox(width: 48, child: _shimmerBox(height: 48)),
                          const SizedBox(
                            width: 16,
                          ),
                          const SizedBox(
                            height: 30,
                            child: VerticalDivider(
                              width: 1,
                              color: IziColors.grey35,
                            ),
                          ),
                        ],
                      ),
                    ...List.generate(8, (index) {
                      return SizedBox(
                          width: ru.isXs() ? 150 : 213,
                          child: _shimmerBox(height: 48));
                    })
                  ],
                ),
              ),
              const Divider(
                color: IziColors.grey25,
                height: 1,
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
                                        : 2,
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
