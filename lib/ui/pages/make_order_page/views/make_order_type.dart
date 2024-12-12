
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Expanded(
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
                                  fontWeight: FontWeight.w600),
                              const SizedBox(
                                height: 60,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buttonSelect(IziIcons.bkComerAqui, LocaleKeys.makeOrder_body_eatHere.tr(), false)
                                  ),
                                  const SizedBox(width: 24,),
                                  Expanded(
                                      child: _buttonSelect(IziIcons.bkParaLlevar, LocaleKeys.makeOrder_body_takeAway.tr(), true)
                                  )
                                ],
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
              ),
            ],
    );
  }

  _buttonSelect(IconData icon,String text, bool takeAway){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AspectRatio(
            aspectRatio: 0.8,
          child: IziCard(
            background: IziColors.greyBurgerKing,
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
        IziText.titleBig(color: IziColors.darkGrey85, text: text,maxLines: 5,textAlign: TextAlign.center,fontWeight: FontWeight.w400)
      ],
    );
  }
}
