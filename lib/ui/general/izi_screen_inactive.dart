import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';

class IziScreenInactive extends StatefulWidget {
  const IziScreenInactive({super.key});

  @override
  State<IziScreenInactive> createState() => _IziScreenInactiveState();
}

class _IziScreenInactiveState extends State<IziScreenInactive> {
  late Timer timer;
  @override
  void initState() {
    timer = Timer(const Duration(seconds: 12), () {
      context.read<PageUtilsBloc>().closeScreenActive();
      GoRouter.of(context).goNamed(RoutesKeys.home);
    });
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (){
        context.read<PageUtilsBloc>().updateScreenActive();
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  color: IziColors.white.withOpacity(0.6),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IziText.titleBig(textAlign: TextAlign.center,color: IziColors.dark, text: LocaleKeys.general_body_thisScreenClose.tr(),fontWeight: FontWeight.w600,maxLines: 2),
                    const SizedBox(height: 8,),
                    IziText.bodyBig(color: IziColors.darkGrey, text: LocaleKeys.general_buttons_pressToContinue.tr(),fontWeight: FontWeight.w600),
                    const SizedBox(height: 8,),
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(color: IziColors.primary,strokeWidth: 2),
                    ),
                  ],
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}
