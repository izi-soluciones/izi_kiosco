import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order_retail/make_order_retail_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_header_lg.dart';
import 'package:izi_kiosco/ui/utils/dynamic_list.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

class MakeOrderRetailInit extends StatefulWidget {
  final MakeOrderRetailState state;
  const MakeOrderRetailInit({super.key, required this.state});

  @override
  State<MakeOrderRetailInit> createState() => _MakeOrderRetailInitState();
}

class _MakeOrderRetailInitState extends State<MakeOrderRetailInit> {
  FocusNode focusNodeKeyboard = FocusNode();
  String barCode = "";
  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    final canInvoice=context.read<AuthBloc>().state.currentContribuyente?.habilitadoFacturacion==true;
    return KeyboardListener(
      focusNode: focusNodeKeyboard,
      autofocus: true,
      onKeyEvent: (value) {
        if(widget.state.status != MakeOrderRetailStatus.waitingGet){
          _verifyKeyboard(value);
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: ru.lwMd()?32:64),
                child: widget.state.status == MakeOrderRetailStatus.waitingGet?_shimmer(ru):DynamicList(
                  direction: ru.isVertical()
                      ? DynamicListDirection.column
                      : DynamicListDirection.row,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Table(

                            defaultColumnWidth: const IntrinsicColumnWidth(),
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: [
                              _infoItem(
                                  IziIcons.barCode,
                                  "1. ${LocaleKeys.makeOrderRetail_init_scanProducts.tr()}",
                                  ru),
                              if(canInvoice)
                              _infoItem(
                                  IziIcons.invoice2,
                                  "2. ${LocaleKeys.makeOrderRetail_init_enterInvoiceData.tr()}",
                                  ru),
                              _infoItem(
                                  IziIcons.paymentMethod,
                                  "${canInvoice?3:2}. ${LocaleKeys.makeOrderRetail_init_selectPaymentMethod.tr()}",
                                  ru),
                              _infoItem(
                                  IziIcons.purchase,
                                  "${canInvoice?4:3}. ${LocaleKeys.makeOrderRetail_init_retirePurchase.tr()}",
                                  ru)
                            ],
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: ru.isVertical()?0:48,top: ru.isVertical()?32:0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IziCard(
                              elevation: true,
                              border: true,
                              padding: const EdgeInsets.all(8),
                              child:
                              Lottie.asset(
                                AssetsKeys.barCodeJson,
                                width: ru.gtMd() || (ru.gtSm() && ru.isVertical())?400:200,
                                repeat: true,
                              )
                            ),
                            const SizedBox(height: 16,),
                            Text(
                              LocaleKeys.makeOrderRetail_scan_waitingScan.tr(),
                              maxLines: 5,
                              textAlign: TextAlign.center,
                              style:  TextStyle(
                                  fontSize: ru.gtMd() || (ru.gtSm() && ru.isVertical())?30:24,
                                  color: IziColors.darkGrey85,
                                  fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child:
          MakeOrderHeaderLg(onPop: () {
            GoRouter.of(context).goNamed(RoutesKeys.home);
            context.read<PageUtilsBloc>().closeScreenActive();
          },
          hideLogo: ru.lwMd(),
          ),
           
          )
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

  _verifyKeyboard(
      value,
      ) {
    if (value is KeyDownEvent) {
      if (value.logicalKey.keyLabel == 'Enter' ||
          value.logicalKey.keyId == 4294967309) {
        _verifyBarCode(context, null);
      }
      if (value.character != null) {
        RegExp regex = RegExp(r'^[a-zA-Z0-9 ]+$');
        if (regex.hasMatch(value.character!)) {
          barCode += value.character ?? "";
        }
      }
    }
  }

  _verifyBarCode(BuildContext context, String? value) {
    context.read<MakeOrderRetailBloc>().changeStepStatus(1);
    context.read<MakeOrderRetailBloc>().addItem(barCode: barCode);
    focusNodeKeyboard.requestFocus();
    barCode = "";
  }
  _shimmer(ResponsiveUtils ru){
    double size = 30;
    if (ru.gtSm()) {
      size = 42;
    }
    if (ru.isXl()) {
      size = 50;
    }
    return Shimmer.fromColors(
      baseColor: IziColors.grey25,
      highlightColor: IziColors.lightGrey30,
      direction: ShimmerDirection.ltr,
      period: const Duration(seconds: 1),
      child: DynamicList(
        direction: ru.isVertical()
            ? DynamicListDirection.column
            : DynamicListDirection.row,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints:  BoxConstraints( maxWidth: ru.gtMd() || (ru.gtSm() && ru.isVertical())?500:350),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _shimmerBox(height: size),
                  const SizedBox(height: 16,),
                  _shimmerBox(height: size),
                  const SizedBox(height: 16,),
                  _shimmerBox(height: size),
                  const SizedBox(height: 16,),
                  _shimmerBox(height: size),
                  const SizedBox(height: 16,),
                  _shimmerBox(height: size),
                ],
              ),
            ),
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints( maxWidth: 350),
              child: Padding(
                padding: EdgeInsets.only(left: ru.isVertical()?0:48,top: ru.isVertical()?32:0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: ru.gtMd() || (ru.gtSm() && ru.isVertical())?400:200,child: _shimmerBox(height: ru.gtMd() || (ru.gtSm() && ru.isVertical())?280:140)),
                    const SizedBox(height: 16,),
                    _shimmerBox(height: 30),
                    const SizedBox(height: 8,),
                    _shimmerBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _infoItem(IconData icon, String text, ResponsiveUtils ru) {
    double sizeText = 20;
    if (ru.isXs()) {
      sizeText = 16;
    }
    if (ru.gtSm()) {
      sizeText = 24;
    }
    if (ru.gtMd() || (ru.gtSm() && ru.isVertical())) {
      sizeText = 38;
    }
    double sizeIcon = 40;
    if (ru.gtSm()) {
      sizeIcon = 48;
    }
    if (ru.isXl()) {
      sizeIcon = 60;
    }
    return TableRow(
      children: [
        Icon(
          icon,
          color: IziColors.primary,
          size: sizeIcon,
        ),
        SizedBox(
          width: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))?32:16,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            text,
            maxLines: 5,
            style: TextStyle(
                fontSize: sizeText,
                color: IziColors.primary,
                fontWeight: FontWeight.w500),
          ),
        )
      ],
    );
  }
}
