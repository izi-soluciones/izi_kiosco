import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/ui/utils/flex_container.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:shimmer/shimmer.dart';

class TablesShimmer extends StatelessWidget {
  const TablesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1300,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 12,
                    ),
                    _roomSelect(ru, context),
                    const SizedBox(
                      height: 16,
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: ru.height - 300),
                      child: _tableSelect(ru, context),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    const SizedBox(height: 24,),
                    if(ru.lwSm())
                      _cashRegistersHorizontal(),
                    if(ru.lwSm())
                      const SizedBox(height: 24,),
                  ],
                ),
              ),
            ),
          ),
          if (ru.gtSm())
            const SizedBox(
              width: 24,
            ),
          if (ru.gtSm())
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 260,
              ),
              child: _cashRegisters(),
            )
        ],
      ),
    );
  }
  _cashRegistersHorizontal(){
    return Shimmer.fromColors(
      baseColor: IziColors.grey25,
      highlightColor: IziColors.lightGrey30,
      direction: ShimmerDirection.ltr,
      child: FlexContainer(
        flexDirection: FlexDirection.row,
        gapV: 16,
        gapH: 16,
        children: List.generate(3, (index) {
          return SizedBox(width: 260,child: _shimmerBox(height: 120));
        })
      ),
    );
  }
  _cashRegisters() {
    return Shimmer.fromColors(
      baseColor: IziColors.grey25,
      highlightColor: IziColors.lightGrey30,
      direction: ShimmerDirection.ltr,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: 2,
              itemBuilder: (context, index) {
                return _shimmerBox(height: 120);
              },
              separatorBuilder: (context, index) {
                return const SizedBox(
                  height: 20,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _tableSelect(ResponsiveUtils ru, BuildContext context) {
    return IziCard(
      border: ru.isXs() ? false : true,
      elevation: ru.isXs() ? true : false,
      big: ru.isXs() ? false : true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: IziColors.grey25,
            highlightColor: IziColors.lightGrey30,
            direction: ShimmerDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(width: ru.isXs()?20:100, child: _shimmerBox(height: 15)),
                const SizedBox(
                  width: 16,
                ),
                SizedBox(width: ru.isXs()?20:100, child: _shimmerBox(height: 15))
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                    color: IziColors.dark, strokeWidth: 2),
              ),
            ),
          )
        ],
      ),
    );
  }

  _roomSelect(ResponsiveUtils ru, BuildContext context) {
    return Shimmer.fromColors(
      baseColor: IziColors.grey25,
      highlightColor: IziColors.lightGrey30,
      direction: ShimmerDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                child: _shimmerBox(height: 15),
              ),
            ],
          ),
          if(ru.lwSm())
            const SizedBox(height: 16,),
          const SizedBox(
            height: 8,
          ),
          FlexContainer(
              flexDirection: FlexDirection.row,
              gapH: 16,
              gapV: 10,
              children: List.generate(3, (index) {
                return SizedBox(
                    width: ru.isXs() ? 136 : 240,
                    child: _shimmerBox(height: ru.isXs() ? 22 : 45));
              }))
        ],
      ),
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
