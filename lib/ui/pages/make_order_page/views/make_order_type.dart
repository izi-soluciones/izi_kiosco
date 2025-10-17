
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
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/utils/dynamic_list.dart';
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
              IziHeaderKiosk(onPop: () {
                GoRouter.of(context).goNamed(RoutesKeys.home);
                context.read<PageUtilsBloc>().closeScreenActive();
              },
              smallLogo: ru.isXs(),
              ),
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: IziText.titleBig(
                                  color: IziColors.darkGrey,
                                  mobile: ru.lwSm(),
                                  cropText: false,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  text: "${LocaleKeys
                                      .makeOrder_body_selectWhere
                                      .tr()}:",
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(
                              height: 60,
                            ),
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: ru.gtSm() && ru.isVertical()?500:400,
                                  maxWidth: ru.isXs()?280:double.infinity
                                  ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                  child: DynamicList(
                                    direction: ru.isXs()?DynamicListDirection.column:DynamicListDirection.row,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: _buttonSelect(IziIcons.hereOrder, LocaleKeys.makeOrder_body_eatHere.tr(), false,ru)
                                      ),
                                      const SizedBox(width: 24,height: 24,),
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
              context.read<MakeOrderBloc>().init(context.read<AuthBloc>().state,takeAway);
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
        SizedBox(height: ru.gtXs()?12:4,),
        ru.gtXs()?
        IziText.titleBig(color: IziColors.darkGrey85, text: text,maxLines: 1,textAlign: TextAlign.center):
        IziText.bodyBig(color: IziColors.darkGrey85, text: text,maxLines: 1,textAlign: TextAlign.center,fontWeight: FontWeight.w600),
      ],
    );
  }
}
