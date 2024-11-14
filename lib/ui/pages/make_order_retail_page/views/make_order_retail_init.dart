import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_header_lg.dart';
import 'package:izi_kiosco/ui/utils/dynamic_list.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class MakeOrderRetailInit extends StatefulWidget {
  final MakeOrderState state;
  const MakeOrderRetailInit({super.key, required this.state});

  @override
  State<MakeOrderRetailInit> createState() => _MakeOrderRetailInitState();
}

class _MakeOrderRetailInitState extends State<MakeOrderRetailInit> {
  ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: (){

            },
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DynamicList(
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
                                  IziIcons.qrCode,
                                  "1. ${LocaleKeys.makeOrderRetail_init_scanProducts.tr()}",
                                  ru),
                              _infoItem(
                                  IziIcons.qrCode,
                                  "2. ${LocaleKeys.makeOrderRetail_init_enterInvoiceData.tr()}",
                                  ru),
                              _infoItem(
                                  IziIcons.qrCode,
                                  "3. ${LocaleKeys.makeOrderRetail_init_selectPaymentMethod.tr()}",
                                  ru),
                              _infoItem(
                                  IziIcons.qrCode,
                                  "4. ${LocaleKeys.makeOrderRetail_init_retirePurchase.tr()}",
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
                              child: SvgPicture.asset(
                                AssetsKeys.barCodeSvg,
                                width: ru.gtMd() || (ru.gtSm() && ru.isVertical())?400:200,
                              ),
                            ),
                            const SizedBox(height: 16,),
                            Text(
                              LocaleKeys.makeOrderRetail_init_pressToInit.tr(),
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
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child:
        MakeOrderHeaderLg(onPop: () {
          GoRouter.of(context).goNamed(RoutesKeys.home);
          context.read<PageUtilsBloc>().closeScreenActive();
        }),)
      ],
    );
  }

  _infoItem(IconData icon, String text, ResponsiveUtils ru) {
    double sizeText = 20;
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
        const SizedBox(
          width: 16,
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
