
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_header_lg.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class MakeOrderType extends StatefulWidget {
  final MakeOrderState state;
  const MakeOrderType({super.key, required this.state});

  @override
  State<MakeOrderType> createState() => _MakeOrderTypeState();
}

class _MakeOrderTypeState extends State<MakeOrderType> {
  ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ru= ResponsiveUtils(context);
    return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MakeOrderHeaderLg(onPop: () {
                GoRouter.of(context).goNamed(RoutesKeys.home);
                context.read<PageUtilsBloc>().closeScreenActive();
              }),
              const SizedBox(
                height: 60,
              ),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 650),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IziText.titleBig(
                                color: IziColors.darkGrey,
                                textAlign: TextAlign.left,
                                text: "${LocaleKeys
                                    .makeOrder_body_selectWhere
                                    .tr()}:",
                                fontWeight: FontWeight.w500),
                            const SizedBox(
                              height: 60,
                            ),
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: ru.gtSm() && ru.isVertical()?500:400),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: _buttonSelect(IziIcons.hereOrder, LocaleKeys.makeOrder_body_eatHere.tr(), false,ru)
                                      ),
                                      const SizedBox(width: 24,),
                                      Expanded(
                                          child: _buttonSelect(IziIcons.takeAwayOrder, LocaleKeys.makeOrder_body_takeAway.tr(), true,ru)
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 60,
              ),
            ],
    );
  }

  _buttonSelect(IconData icon,String text, bool takeAway, ResponsiveUtils ru){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: IziCard(
            padding: const EdgeInsets.all(16),
            onPressed: (){
              context.read<MakeOrderBloc>().changeTakeAway(takeAway);
              context.read<MakeOrderBloc>().changeStepStatus(1);
            },
            child: FractionallySizedBox(
              widthFactor: 0.6,
              child: FittedBox(
                child: Icon(
                  icon,
                  weight: 0.5,
                  color: IziColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12,),
        ru.gtSm()?
        IziText.titleBig(color: IziColors.darkGrey85, text: text,maxLines: 1,textAlign: TextAlign.center):
        IziText.titleMedium(color: IziColors.darkGrey85, text: text,maxLines: 1,textAlign: TextAlign.center,fontWeight: FontWeight.w600),
      ],
    );
  }
}
