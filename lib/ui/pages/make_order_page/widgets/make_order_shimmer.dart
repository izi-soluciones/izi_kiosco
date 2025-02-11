import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_header_lg.dart';
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
        MakeOrderHeaderLg(onPop: () {
          GoRouter.of(context).goNamed(RoutesKeys.home);
          context.read<PageUtilsBloc>().closeScreenActive();
        }),
        Shimmer.fromColors(
            baseColor: IziColors.grey25,
            highlightColor: IziColors.lightGrey30,
            direction: ShimmerDirection.ltr,
            child: _headerLarge()),
        Expanded(
          child: Shimmer.fromColors(
              baseColor: IziColors.grey25,
              highlightColor: IziColors.lightGrey30,
              direction: ShimmerDirection.ltr,
              child: _itemsLg(ru)),
        ),
      ],
    );
  }
  Widget _itemsLg(ResponsiveUtils ru) {
    return LayoutBuilder(builder: (context, layout) {
      return AlignedGridView.count(
        crossAxisCount: ((layout.maxWidth > 1500
            ? 6
            : layout.maxWidth > 1250
            ? 5
            : layout.maxWidth > 950
            ? 4
            : layout.maxWidth > 700
            ? 4
            : layout.maxWidth > 450
            ? 2
            : 1)/(2)).ceil(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        padding:
        const EdgeInsets.only(top: 16, right: 32, left: 32, bottom: 63),
        itemCount: 10,
        itemBuilder: (BuildContext context, int index) {
          return _shimmerBox(height: 400);
        },
      );
    });
  }
  Widget _headerLarge() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: RowContainer(
          gap: 16,
          children: List.generate(7, (index) {
            return SizedBox(width: 140,child: _shimmerBox(height: 140));
          })),
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