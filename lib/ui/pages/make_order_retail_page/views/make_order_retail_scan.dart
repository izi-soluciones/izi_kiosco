
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_btn_icon.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/izi_typography_config.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order_retail/make_order_retail_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/domain/models/sale_link.dart';
import 'package:izi_kiosco/ui/modals/help_modal.dart';
import 'package:izi_kiosco/ui/modals/warning_modal.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/dynamic_list.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:lottie/lottie.dart';

class MakeOrderRetailScan extends StatefulWidget {
  final MakeOrderRetailState state;
  const MakeOrderRetailScan({super.key, required this.state});

  @override
  State<MakeOrderRetailScan> createState() => _MakeOrderRetailScanState();
}

class _MakeOrderRetailScanState extends State<MakeOrderRetailScan> {
  FocusNode focusNodeKeyboard = FocusNode();
  String barCode = "";
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return KeyboardListener(
      focusNode: focusNodeKeyboard,
      autofocus: true,
      onKeyEvent: (value) {
        _verifyKeyboard(value);
      },
      child: Column(
        children: [
          _header(),
          Expanded(
            child: widget.state.itemsSelected.isEmpty
                ? _waitScanned(ru)
                : _listScanned(ru),
          ),
          _footer(ru)
        ],
      ),
    );
  }

  Widget _waitScanned(ResponsiveUtils ru) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IziCard(
            elevation: true,
            border: true,
            padding: const EdgeInsets.all(8),
            child: Lottie.asset(
              AssetsKeys.barCodeJson,
              width: ru.gtMd() || (ru.gtSm() && ru.isVertical()) ? 400 : 200,
              repeat: true,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            LocaleKeys.makeOrderRetail_scan_waitingScan.tr(),
            maxLines: 5,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: ru.gtMd() || (ru.gtSm() && ru.isVertical()) ? 30 : 24,
                color: IziColors.darkGrey85,
                fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }


  Widget _listScanned(ResponsiveUtils ru) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IziText.titleMedium(
                color: IziColors.darkGrey,
                text: LocaleKeys.makeOrderRetail_scan_productsScanned.tr()),
            Row(
              children: [
                const SizedBox(
                  width: 80,
                ),
                const Expanded(flex: 8, child: SizedBox.shrink()),
                Expanded(
                    flex: 4,
                    child: IziText.body(
                        color: IziColors.darkGrey,
                        textAlign: TextAlign.center,
                        text: ru.gtSm()
                            ? LocaleKeys.makeOrderRetail_scan_unitPrice.tr()
                            : LocaleKeys.makeOrderRetail_scan_unitPriceAbr.tr(),
                        fontWeight: FontWeight.w500)),
                Expanded(
                    flex: 4,
                    child: IziText.body(
                        color: IziColors.darkGrey,
                        textAlign: TextAlign.center,
                        text: ru.gtSm()
                            ? LocaleKeys.makeOrderRetail_scan_totalPrice.tr()
                            : LocaleKeys.makeOrderRetail_scan_totalPriceAbr
                                .tr(),
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 32,)
              ],
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                            itemCount: widget.state.itemsSelected.length,
                            separatorBuilder: (context, index) {
              return const Divider(
                color: IziColors.grey35,
                height: 1,
                thickness: 1,
                indent: 8,
                endIndent: 8,
              );
                            },
                            itemBuilder: (context, index) {
              return _item(widget.state.itemsSelected[index], ru,
                  first: index == 0,
                  last: widget.state.itemsSelected.length == index + 1);
                            },
                          ),
            )
          ],
        ),
      ),
    );
  }

  _item(Item item, ResponsiveUtils ru,
      {required bool first, required bool last}) {
    return IziCard(
      rt: first,
      rb: last,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 80,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: IziColors.grey25,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.imagen == null || item.imagen?.isEmpty == true
                      ? const FittedBox(
                          child:
                              Icon(IziIcons.dish, color: IziColors.warmLighten))
                      : CachedNetworkImage(
                          imageUrl: item.imagen ?? "",
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: IziColors.dark)),
                          errorWidget: (context, url, error) {
                            return const FittedBox(
                                child: Icon(IziIcons.dish,
                                    color: IziColors.warmLighten));
                          },
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(left: 8,top: 8,bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IziText.titleSmall(
                      mobile: !(ru.gtMd() || (ru.gtSm() && ru.isVertical())),
                      height: 1,
                      textAlign: TextAlign.left,
                      color: IziColors.dark,
                      text: item.nombre,
                      fontWeight: FontWeight.w500,
                      maxLines: 7),
                  const SizedBox(height: 8,),
                  RichText(
                      textAlign: TextAlign.left,
                      text: TextSpan(children: [
                        TextSpan(
                            text:
                                "${LocaleKeys.makeOrderRetail_scan_quantity.tr()}: ",
                            style: const TextStyle(
                              fontFamily:
                                  IziTypographyConfig.familyHindSiliguri,
                              color: IziColors.darkGrey,
                              fontWeight: FontWeight.w400,
                            )),
                        TextSpan(
                            text: "${item.cantidad}",
                            style: const TextStyle(
                              fontFamily:
                                  IziTypographyConfig.familyHindSiliguri,
                              color: IziColors.primaryDarken,
                              fontWeight: FontWeight.w600,
                            )),
                      ]))
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IziText.body(
                  textAlign: TextAlign.center,
                  color: IziColors.grey,
                  text: item.precioUnitario.moneyFormat(
                      currency: widget.state.currentCurrency?.simbolo),
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IziText.body(
                  textAlign: TextAlign.center,
                  color: IziColors.grey,
                  text: (item.precioUnitario * item.cantidad).moneyFormat(
                      currency: widget.state.currentCurrency?.simbolo),
                  fontWeight: FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IziBtnIcon(
              buttonOnPressed: (){
                context.read<MakeOrderRetailBloc>().removeItem(item);
              },
              buttonSize: ButtonSize.small,
              buttonType: ButtonType.terciary,
              buttonIcon: IziIcons.close,
            ),
          ),
        ],
      ),
    );
  }

  _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () {
            _back();
          },
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Icon(IziIcons.leftB, color: IziColors.grey, size: 50),
          ),
        ),
        if (widget.state.itemsSelected.isNotEmpty)
          Lottie.asset(
            AssetsKeys.barCodeJson,
            width: 50,
            repeat: true,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: IziBtnIcon(
              buttonIcon: IziIcons.help,
              buttonType: ButtonType.outline,
              buttonSize: ButtonSize.medium,
              buttonOnPressed: () {
                _openHelp(context);
              }),
        )
      ],
    );
  }

  _openHelp(BuildContext context){
    CustomAlerts.defaultAlert(
        dismissible: true,
        padding: EdgeInsets.zero,
        context: context,
        child: const HelpModal()).then((value){
          focusNodeKeyboard.requestFocus();
    });
  }
  _footer(ResponsiveUtils ru) {
    double size = 24;
    if (ru.gtSm()) {
      size = 30;
    }
    if ((ru.gtMd() || (ru.gtSm() && ru.isVertical()))) {
      size = 42;
    }
    return Padding(
      padding:  EdgeInsets.symmetric(vertical: 8.0,horizontal: (ru.gtMd() || (ru.gtSm() && ru.isVertical()))?32:16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
      "${LocaleKeys.makeOrderRetail_scan_total.tr()}: ${_total().moneyFormat(currency: widget.state.currentCurrency?.simbolo??"")}",
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w600,
                  color: IziColors.dark,
                ),
              )
            ],
          ),
          const SizedBox(height: 16,),
          DynamicList(
            direction: (ru.gtXs())?DynamicListDirection.row:DynamicListDirection.column,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                flex: 3,
                  child: IziBtn(
                    buttonType: ButtonType.outline,
                    buttonText: LocaleKeys.makeOrderRetail_scan_initAgain.tr(),
                    buttonSize: (ru.gtSm())?ButtonSize.large:ButtonSize.medium,
                    buttonOnPressed: () {
                      _initAgain();
                    },
                  )
              ),
              const SizedBox(width: 16,height: 8,),
              Flexible(
                flex: 4,
                  child: IziBtn(
                    buttonType: ButtonType.secondary,
                    iconSuffix: IziIcons.rightB,
                    buttonText: LocaleKeys.makeOrderRetail_scan_finishPurchase.tr(),
                    buttonSize: (ru.gtSm())?ButtonSize.large:ButtonSize.medium,
                    buttonOnPressed: widget.state.itemsSelected.isEmpty?null:() async {
                      _emitPurchase();
                    },
                  )
              )
            ],
          )
        ],
      ),
    );
  }

  _emitPurchase(){

    context.read<PageUtilsBloc>().showLoading("Procesando compra");
    context.read<PageUtilsBloc>().closeScreenActive();
    context.read<MakeOrderRetailBloc>().emitOrder(context.read<AuthBloc>().state).then((value) {
      context.read<PageUtilsBloc>().closeLoading();
      if(value is SaleLink){
        var paymentObj = PaymentObj(
            id: value.id,
            custom: {},
            amount: value.monto,
            isComanda: false,
            uuid: value.uuid,
            items: value.items.map((e) => ItemPaymentObj(
                quantity: e.cantidad ,
                custom: {},
                name: e.nombre)
            ).toList()
        );
        context.read<PageUtilsBloc>().initScreenActiveInvoiced(context.read<AuthBloc>().state);
        GoRouter.of(context).goNamed(RoutesKeys.payment,
            extra: paymentObj, pathParameters: {"id": value.id.toString()});
      } else {
        context.read<PageUtilsBloc>().initScreenActive(context.read<AuthBloc>().state);
      }
    });
  }
  num _total(){
    return widget.state.itemsSelected.fold(0.0, (previousValue, element) => previousValue + (element.cantidad*element.precioUnitario));
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
    context.read<MakeOrderRetailBloc>().addItem(barCode: barCode);
    focusNodeKeyboard.requestFocus();
    barCode = "";
  }
  _back(){
    if(widget.state.itemsSelected.isNotEmpty){
      CustomAlerts.defaultAlert(
          context: context,
          child: WarningModal(
              onAccept: ()async{
                GoRouter.of(context).goNamed(RoutesKeys.home);
                context.read<PageUtilsBloc>().closeScreenActive();
              },
              title: LocaleKeys.makeOrderRetail_scan_areYouSureBack.tr()
          )
      ).then((value) {
        if(mounted){
          focusNodeKeyboard.requestFocus();
        }
      });
      return;
    }

    GoRouter.of(context).goNamed(RoutesKeys.home);
    context.read<PageUtilsBloc>().closeScreenActive();
  }
  _initAgain(){
    if(widget.state.itemsSelected.isNotEmpty){
      CustomAlerts.defaultAlert(
          context: context,
          child: WarningModal(
              onAccept: ()async{
                context.read<MakeOrderRetailBloc>().resetItems();
                focusNodeKeyboard.requestFocus();
              },
              title: LocaleKeys.makeOrderRetail_scan_areYouSureInitAgain.tr()
          )
      ).then((value) {
        if(mounted){
          focusNodeKeyboard.requestFocus();
        }
      });
      return;
    }
    context.read<MakeOrderRetailBloc>().resetItems();
    focusNodeKeyboard.requestFocus();
  }
}
