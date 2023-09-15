import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_radio_button.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/molecules/izi_switch.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/headers/back_mobile_header.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';

class MakeOrderItemOptions extends StatefulWidget {
  final Item item;
  final MakeOrderState state;
  const MakeOrderItemOptions(
      {super.key, required this.item, required this.state});

  @override
  State<MakeOrderItemOptions> createState() => _MakeOrderItemOptionsState();
}

class _MakeOrderItemOptionsState extends State<MakeOrderItemOptions> {
  Item? itemEdit;
  int? indexRequired;

  List<GlobalKey> titleKeys = [];
  ScrollController scrollController = ScrollController();
  @override
  void initState() {
    itemEdit = widget.item.copyWith();
    itemEdit?.cantidad = 1;
    for (var _ in itemEdit?.modificadores ?? []) {
      titleKeys.add(GlobalKey());
    }
    super.initState();
  }

  _verifyRequired() {
    for (int i = 0; i < (itemEdit?.modificadores.length ?? 0); i++) {
      var ver = false;
      for (var car in (itemEdit?.modificadores[i].caracteristicas ?? [])) {
        if (itemEdit?.modificadores[i].isObligatorio == false || car.check) {
          ver = true;
        }
      }
      if (!ver) {
        setState(() {
          indexRequired = i;
        });
        if (titleKeys[i].currentContext != null) {
          Scrollable.ensureVisible(titleKeys[i].currentContext!);
        }
        return false;
      }
    }
    setState(() {
      indexRequired = null;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BackMobileHeader(
          background: IziColors.lightGrey30,
          title: IziText.bodyBig(
              color: IziColors.dark,
              text: LocaleKeys.makeOrder_subtitles_details.tr(),
              fontWeight: FontWeight.w500),
          onBack: () {
            Navigator.pop(context);
          },
        ),
        Expanded(
          child: Container(
            color: IziColors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 76,
                    child: IziCard(
                      elevation: false,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              color: IziColors.grey25,
                              child: widget.item.imagen == null ||
                                      widget.item.imagen?.isEmpty == true
                                  ? const FittedBox(
                                      child: Icon(IziIcons.dish,
                                          color: IziColors.warmLighten))
                                  : CachedNetworkImage(
                                      imageUrl: widget.item.imagen ?? "",
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: IziColors.dark)),
                                      errorWidget: (context, url, error) {
                                        return const FittedBox(
                                            child: Icon(IziIcons.dish,
                                                color: IziColors.warmLighten));
                                      },
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IziText.bodyBig(
                                    fontWeight: FontWeight.w500,
                                    maxLines: 5,
                                    color: IziColors.dark,
                                    text: widget.item.nombre,
                                    textAlign: TextAlign.center),
                                IziText.body(
                                    color: IziColors.grey,
                                    text: widget.item.precioUnitario
                                        .moneyFormat(
                                            currency: widget.state
                                                .currentCurrency?.simbolo),
                                    fontWeight: FontWeight.w500,
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: IziText.bodyBig(
                            color: IziColors.darkGrey,
                            text: LocaleKeys.makeOrder_body_quantity.tr(),
                            fontWeight: FontWeight.w500),
                      ),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 200
                          ),
                          child: IziInput(
                              inputHintText: "0",
                              value: "1",
                              maxValue: 9999999999,
                              minValue: 1,
                              textAlign: TextAlign.center,
                              inputSize: InputSize.small,
                              onChanged: (value, valueRaw) {
                                setState(() {
                                  itemEdit?.cantidad = num.tryParse(value) ?? 1;
                                });
                              },
                              inputType: InputType.incremental),
                        ),
                      )
                    ],
                  ),
                ),
                const Divider(
                  color: IziColors.grey25,
                  height: 1,
                ),
                Expanded(
                  child: Container(
                    color: IziColors.white,
                    child: IziScroll(
                      scrollController: scrollController,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: (itemEdit?.modificadores ?? [])
                                .asMap()
                                .entries
                                .map((entry) {
                              var e1 = entry.value;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    SizedBox(
                                      key: titleKeys[entry.key],
                                      child: IziText.titleSmall(
                                          color: entry.key == indexRequired
                                              ? IziColors.red
                                              : IziColors.dark,
                                          text: e1.nombre +
                                              (e1.isObligatorio ? "*" : "")),
                                    ),
                                    ...e1.caracteristicas
                                        .asMap()
                                        .entries
                                        .map((e2) {
                                      return InkWell(
                                        onTap: () {
                                          if (e1.isMultiple) {
                                            setState(() {
                                              e2.value.check = !e2.value.check;
                                            });
                                          } else {
                                            setState(() {
                                              var lastCheck = e2.value.check;
                                              for (var ca in e1.caracteristicas) {
                                                ca.check = false;
                                              }
                                              e2.value.check = !lastCheck;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 18),
                                          decoration: BoxDecoration(
                                              border: e2.key <
                                                      e1.caracteristicas.length -
                                                          1
                                                  ? const Border(
                                                      bottom: BorderSide(
                                                          color: IziColors.grey25,
                                                          width: 1))
                                                  : null),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              IziText.body(
                                                  color: IziColors.darkGrey,
                                                  text:
                                                      "${e2.value.nombre}${e2.value.modPrecio > 0 ? " (+${e2.value.modPrecio.moneyFormat(currency: widget.state.currentCurrency?.simbolo)})" : ""}",
                                                  fontWeight: FontWeight.w600),
                                              e1.isMultiple
                                                  ? IziSwitch(
                                                      value: e2.value.check,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          e2.value.check = value;
                                                        });
                                                      })
                                                  : IziRadioButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          var lastCheck =
                                                              e2.value.check;
                                                          for (var ca in e1
                                                              .caracteristicas) {
                                                            ca.check = false;
                                                          }
                                                          e2.value.check =
                                                              !lastCheck;
                                                        });
                                                      },
                                                      radioButtonType: e2
                                                              .value.check
                                                          ? RadioButtonType
                                                              .checkboxChecked
                                                          : RadioButtonType
                                                              .checkboxDefault)
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                  ],
                                ),
                              );
                            }).toList()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        IziCard(
          radiusTop: false,
          radiusBottom: false,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IziText.bodyBig(
                  color: IziColors.dark,
                  text: _getTotal().moneyFormat(
                      currency: widget.state.currentCurrency?.simbolo),
                  fontWeight: FontWeight.w500,
                  textAlign: TextAlign.center),
              IziBtn(
                  buttonText: LocaleKeys.makeOrder_buttons_add.tr(),
                  buttonType: ButtonType.secondary,
                  buttonSize: ButtonSize.small,
                  buttonOnPressed: () {
                    if (_verifyRequired()) {
                      Navigator.pop(context, itemEdit);
                    }
                  }),
            ],
          ),
        ),
      ],
    );
  }

  num _getTotal() {
    if (itemEdit != null) {
      num pM = 0;
      for (var m in itemEdit!.modificadores) {
        for (var c in m.caracteristicas) {
          if (c.check) {
            pM += c.modPrecio * itemEdit!.cantidad;
          }
        }
      }
      return itemEdit!.cantidad * itemEdit!.precioUnitario + pM;
    } else {
      return 0;
    }
  }
}
