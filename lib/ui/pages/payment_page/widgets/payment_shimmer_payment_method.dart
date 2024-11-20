import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/modals/warning_modal.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/flex_container.dart';
import 'package:shimmer/shimmer.dart';

class PaymentShimmerPaymentMethod extends StatelessWidget {

  const PaymentShimmerPaymentMethod({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IziHeaderKiosk(onBack: (){
          _cancelOrder(context);
        }),
        Container(
          width: double.infinity,
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
                    maxWidth: 1000,
                  ),
                  child: _methods(context)),
            ),
          ),
        )
      ],
    );
  }

  Widget _methods(BuildContext context) {
    return FlexContainer(
      flexDirection: FlexDirection.row,
      gapV: 16,
      gapH: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      children: [
        SizedBox(width: 292,child:
        _shimmerBox(height: 250),),
        SizedBox(width: 292,child:
        _shimmerBox(height: 250),),
        SizedBox(width: 292,child:
        _shimmerBox(height: 250),)
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
  _cancelOrder(BuildContext context){

    CustomAlerts.defaultAlert(
        context: context,
        child: WarningModal(
            onAccept: ()async{
              GoRouter.of(context).goNamed(RoutesKeys.home);
              context.read<PageUtilsBloc>().closeScreenActive();
            },
            title: LocaleKeys.makeOrderRetail_scan_areYouSureBack.tr()
        )
    );
    return;
  }
}
