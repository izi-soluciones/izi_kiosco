import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/ui/general/headers/back_mobile_header.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:shimmer/shimmer.dart';

class PaymentShimmerResume extends StatelessWidget {
  const PaymentShimmerResume({super.key});

  @override
  Widget build(BuildContext context) {
    return IziCard(
      radiusBottom: false,
      radiusTop: false,
      child: Column(
        children: [
          BackMobileHeader(
            background: IziColors.white,
            title: IziText.title(
                color: IziColors.darkGrey,
                text: LocaleKeys.payment_titles_resume.tr()),
            onBack: () {
              if(GoRouter.of(context).canPop()){
                GoRouter.of(context).pop();
              }else{
                GoRouter.of(context).goNamed(RoutesKeys.order);
              }
            },
          ),
          const Divider(
            color: IziColors.grey25,
            height: 1,
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, layout) {
              return SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Shimmer.fromColors(
                  baseColor: IziColors.grey25,
                  highlightColor: IziColors.lightGrey30,
                  direction: ShimmerDirection.ltr,
                  period: const Duration(seconds: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(widthFactor: 0.3,child: _shimmerBox(height: 15)),
                      const SizedBox(
                        height: 10,
                      ),
                      _detailItems(context),
                      const SizedBox(
                        height: 40,
                      ),
                      _resumeTotal(context)
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _resumeTotal(BuildContext context) {
    return ColumnContainer(
      gap: 16,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: _shimmerBox(height: 15),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: _shimmerBox(height: 15),
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: _shimmerBox(height: 15),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth:30),
              child: _shimmerBox(height: 15),
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: _shimmerBox(height: 15),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 30),
              child: _shimmerBox(height: 15),
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: _shimmerBox(height: 20),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: _shimmerBox(height: 20),
            )
          ],
        ),
      ],
    );
  }



  Widget _detailItems(BuildContext context) {
    return _shimmerBox(height: 60);
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
