import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_btn_icon.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/campos_extra.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/item_options_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_amount_btn.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class MakeOrderConfirm extends StatefulWidget {
  final MakeOrderState state;
  const MakeOrderConfirm({super.key, required this.state});

  @override
  State<MakeOrderConfirm> createState() => _MakeOrderConfirmState();
}

class _MakeOrderConfirmState extends State<MakeOrderConfirm> {
  late AuthState authState;
  List<TextEditingController> controllers = [];
  final Map<int, TextEditingController> camposExtraControllers = {};
  ScrollController scrollController = ScrollController();
  bool loadingEmit = false;

  @override
  void initState() {
    authState = context.read<AuthBloc>().state;
    for (var c in widget.state.itemsSelected) {
      List.generate(c.items.length, (index) {
        controllers.add(TextEditingController());
      });
    }
    for (var c in widget.state.camposExtra) {
      if (c.tipoCampo != 'select') {
        camposExtraControllers[c.id] =
            TextEditingController(text: c.valor ?? "");
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    for (var c in camposExtraControllers.values) {
      c.dispose();
    }
    for (var c in controllers) {
      c.dispose();
    }
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return BlocListener<MakeOrderBloc, MakeOrderState>(
      listener: (context, state) {
        int cIndex = 0;
        for (var c in state.itemsSelected) {
          for (var i in c.items) {
            if (cIndex >= controllers.length - 1) {
              controllers.add(TextEditingController());
            }
            if (controllers[cIndex].text == i.cantidad.toString()) {
              cIndex++;
              continue;
            }
            controllers[cIndex].text =
                i.cantidad > 0 ? i.cantidad.toString() : "0";
            cIndex++;
          }
        }
        for (var c in state.camposExtra) {
          if (camposExtraControllers.containsKey(c.id)) {
            if (camposExtraControllers[c.id]!.text != (c.valor ?? "")) {
              camposExtraControllers[c.id]!.text = c.valor ?? "";
            }
          } else if (c.tipoCampo != 'select') {
            camposExtraControllers[c.id] =
                TextEditingController(text: c.valor ?? "");
          }
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IziHeaderKiosk(
                  onPop: () {
                    context.read<MakeOrderBloc>().changeStepStatus(1);
                  },
                  smallLogo: !ru.isVertical(),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 650),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ru.isXs()
                                    ? IziText.bodyBig(
                                        color: context.iziColors.darkGrey,
                                        textAlign: TextAlign.left,
                                        text:
                                            "${authState.currentDevice?.config.isRetail == true ? LocaleKeys.makeOrder_subtitles_myPurchase.tr() : widget.state.takeAway ? LocaleKeys.makeOrder_body_confirmOrderTakeWay.tr() : LocaleKeys.makeOrder_body_confirmOrderEatHere.tr()}:",
                                        fontWeight: FontWeight.w600)
                                    : IziText.titleBig(
                                        color: context.iziColors.darkGrey,
                                        textAlign: TextAlign.left,
                                        text:
                                            "${authState.currentDevice?.config.isRetail == true ? LocaleKeys.makeOrder_subtitles_myPurchase.tr() : widget.state.takeAway ? LocaleKeys.makeOrder_body_confirmOrderTakeWay.tr() : LocaleKeys.makeOrder_body_confirmOrderEatHere.tr()}:",
                                        fontWeight: FontWeight.w500),
                                SizedBox(height: ru.isXs() ? 16 : 32),
                                Flexible(
                                  child: IziScroll(
                                    scrollController: scrollController,
                                    child: SingleChildScrollView(
                                      controller: scrollController,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _listItems(widget.state, ru),
                                          if (widget.state.camposExtra
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 16),
                                            _camposExtraSection(
                                                widget.state, ru),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: ru.isXs() ? 16 : 30),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ru.isXs()
                                        ? IziText.bodyBig(
                                            color: context.iziColors.darkGrey,
                                            fontWeight: FontWeight.w500,
                                            text:
                                                "${LocaleKeys.makeOrder_labels_total.tr()}: ${(_getTotal(widget.state) - widget.state.discountAmount).moneyFormat(currency: widget.state.currentCurrency?.simbolo, digitsTaxes: authState.taxesStrategy.decimals)}",
                                          )
                                        : IziText.titleMedium(
                                            color: context.iziColors.darkGrey,
                                            fontWeight: FontWeight.w500,
                                            text:
                                                "${LocaleKeys.makeOrder_labels_total.tr()}: ${(_getTotal(widget.state) - widget.state.discountAmount).moneyFormat(currency: widget.state.currentCurrency?.simbolo, digitsTaxes: authState.taxesStrategy.decimals)}",
                                          ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _totalOrder(context, widget.state, ru),
              ],
            ),
          ),
          if (loadingEmit)
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _camposExtraSection(MakeOrderState state, ResponsiveUtils ru) {
    return IziCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: context.iziColors.primary,
              ),
              const SizedBox(width: 8),
              IziText.titleSmall(
                color: context.iziColors.dark,
                text: "Información adicional",
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...state.camposExtra.map((c) => _buildCampoExtraInput(c, ru)),
        ],
      ),
    );
  }

  Widget _buildCampoExtraInput(CamposExtra c, ResponsiveUtils ru) {
    final label = "${c.nombre}${c.isObligatorio ? ' *' : ' (opcional)'}";

    if (c.tipoCampo == 'select') {
      final options = c.values ?? [];
      final Map<String, String> selectOpts = {
        for (var opt in options) opt: opt,
      };

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IziInput(
          labelInput: label,
          inputHintText: "Seleccione una opción",
          inputType: InputType.select,
          value: c.valor,
          selectOptions: selectOpts,
          onSelected: (val) {
            context
                .read<MakeOrderBloc>()
                .updateCampoExtra(c.id, val?.toString());
          },
        ),
      );
    }

    if (c.tipoCampo == 'fijo') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IziInput(
          labelInput: label,
          inputHintText: "",
          inputType: InputType.normal,
          value: c.valor ?? "",
          readOnly: true,
        ),
      );
    }

    final controller = camposExtraControllers.putIfAbsent(
      c.id,
      () => TextEditingController(text: c.valor ?? ""),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IziInput(
        labelInput: label,
        inputHintText: "Ingrese ${c.nombre.toLowerCase()}",
        inputType:
            c.tipoCampo == 'number' ? InputType.number : InputType.normal,
        controller: controller,
        onChanged: (val, raw) {
          context.read<MakeOrderBloc>().updateCampoExtra(c.id, val);
        },
      ),
    );
  }

  Widget _listItems(MakeOrderState state, ResponsiveUtils ru) {
    var cIndex = -1;
    return IziCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: state.itemsSelected.asMap().entries.map((e) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...e.value.items.asMap().entries.map(
                (i) {
                  cIndex++;
                  return Container(
                    decoration: BoxDecoration(
                      border: e.key < state.itemsSelected.length - 1 ||
                              i.key < e.value.items.length - 1
                          ? Border(
                              bottom: BorderSide(
                                  color: context.iziColors.grey35, width: 1))
                          : null,
                    ),
                    child: _item(
                      context,
                      i.value,
                      cIndex < controllers.length - 1
                          ? controllers[cIndex]
                          : null,
                      e.key,
                      i.key,
                      ru,
                    ),
                  );
                },
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _totalOrder(
      BuildContext context, MakeOrderState state, ResponsiveUtils ru) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Row(
              children: [
                ru.isXs()
                    ? IziBtnIcon(
                        buttonIcon: IziIcons.plusB,
                        buttonType: ButtonType.outline,
                        buttonSize: ButtonSize.medium,
                        buttonOnPressed: () {
                          context.read<MakeOrderBloc>().changeStepStatus(1);
                        })
                    : Expanded(
                        flex: 5,
                        child: IziBtn(
                            buttonText: LocaleKeys.makeOrder_buttons_addMore.tr(),
                            buttonType: ButtonType.outline,
                            buttonSize: ButtonSize.large,
                            buttonOnPressed: () {
                              context.read<MakeOrderBloc>().changeStepStatus(1);
                            }),
                      ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 8,
                  child: MakeOrderAmountBtn(
                    noAmount: ru.width < 500,
                    medium: ru.isXs(),
                    onPressed: _getTotal(state) > 0
                        ? () {
                            _emitOrder(context);
                          }
                        : null,
                    text: ru.isXs()
                        ? LocaleKeys.makeOrder_buttons_confirmAndPaySm.tr()
                        : LocaleKeys.makeOrder_buttons_confirmAndPay.tr(),
                    amount: (_getTotal(state) - state.discountAmount).moneyFormat(
                        currency: state.currentCurrency?.simbolo,
                        digitsTaxes: authState.taxesStrategy.decimals),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _item(
      BuildContext context,
      Item item,
      TextEditingController? controller,
      int indexCategory,
      int indexItem,
      ResponsiveUtils ru) {
    return InkWell(
      onTap: () {
        _editItem(context, item, indexCategory, indexItem);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IziText.title(
                color: context.iziColors.dark,
                text: "x${item.cantidad}",
                mobile: ru.isXs()),
            if (ru.gtXxs()) const SizedBox(width: 16),
            if (ru.gtXxs())
              SizedBox(
                height: ru.isXs() ? 32 : 68,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: context.iziColors.grey25,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.imagen == null || item.imagen?.isEmpty == true
                        ? FittedBox(
                            child: Icon(IziIcons.dish,
                                color: context.iziColors.warmLighten))
                        : CachedNetworkImage(
                            imageUrl: item.imagen ?? "",
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.iziColors.dark)),
                            errorWidget: (context, url, error) {
                              return FittedBox(
                                  child: Icon(IziIcons.dish,
                                      color: context.iziColors.warmLighten));
                            },
                          ),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ru.isXs()
                      ? IziText.body(
                          textAlign: TextAlign.left,
                          color: context.iziColors.dark,
                          text: item.nombreMostrar,
                          fontWeight: FontWeight.w600,
                          maxLines: 10)
                      : IziText.title(
                          textAlign: TextAlign.left,
                          color: context.iziColors.dark,
                          text: item.nombreMostrar,
                          fontWeight: FontWeight.w600,
                          maxLines: 10),
                  ...item.modificadores.where((element) {
                    return element.caracteristicas
                            .indexWhere((c) => c.check) !=
                        -1;
                  }).map(
                    (e) {
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "${e.nombre}: ",
                              style: IziText.bodySmall(
                                      color: context.iziColors.dark,
                                      text: "",
                                      fontWeight: FontWeight.w500)
                                  .style,
                            ),
                            TextSpan(
                              text: e.caracteristicas.fold("",
                                  (previousValue, c) {
                                previousValue ??= "";
                                if (!c.check) {
                                  return previousValue;
                                }
                                if (previousValue != "") {
                                  previousValue += ", ";
                                }
                                previousValue +=
                                    "${c.nombre}${c.modPrecio > 0 ? " (+${c.modPrecio})" : ""}";
                                return previousValue;
                              }),
                              style: IziText.bodySmall(
                                      color: context.iziColors.darkGrey85,
                                      maxLines: 50,
                                      text: "",
                                      fontWeight: FontWeight.w400)
                                  .style,
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  if (item.detalle?.isNotEmpty == true)
                    IziText.body(
                        textAlign: TextAlign.left,
                        color: context.iziColors.primary,
                        text: item.detalle!,
                        fontWeight: FontWeight.w400,
                        maxLines: 2),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IziText.body(
                textAlign: TextAlign.center,
                color: context.iziColors.grey,
                text: item.taxPrice.moneyFormat(
                    currency: widget.state.currentCurrency?.simbolo,
                    digitsTaxes: authState.taxesStrategy.decimals),
                fontWeight: FontWeight.w500),
            const SizedBox(width: 16),
            IziBtnIcon(
                buttonIcon: IziIcons.close,
                buttonType: ButtonType.secondary,
                buttonSize: ru.isXs() ? ButtonSize.small : ButtonSize.medium,
                color: context.iziColors.red,
                buttonOnPressed: () {
                  context
                      .read<MakeOrderBloc>()
                      .removeItem(indexCategory, indexItem);
                  if (widget.state.itemsSelected.length == 1 &&
                      widget.state.itemsSelected[0].items.length == 1) {
                    context.read<MakeOrderBloc>().changeStepStatus(1);
                  }
                })
          ],
        ),
      ),
    );
  }

  _emitOrder(BuildContext context) async {
    final validationError = context.read<MakeOrderBloc>().validateCamposExtra();
    if (validationError != null) {
      context.read<PageUtilsBloc>().showSnackBar(
            snackBar: SnackBarInfo(
              text: validationError,
              snackBarType: SnackBarType.error,
            ),
          );
      return;
    }

    setState(() {
      loadingEmit = true;
    });
    context
        .read<PageUtilsBloc>()
        .showLoading(LocaleKeys.makeOrder_buttons_confirmingOrder.tr());
    context.read<PageUtilsBloc>().closeScreenActive();
    await context
        .read<MakeOrderBloc>()
        .emitOrder(authState)
        .then(
      (paymentObj) {
        context.read<PageUtilsBloc>().closeLoading();
        if (paymentObj is PaymentObj) {
          context.read<PageUtilsBloc>().initScreenActiveInvoiced(authState);
          GoRouter.of(this.context).goNamed(RoutesKeys.payment,
              extra: paymentObj,
              pathParameters: {"id": paymentObj.id.toString()});
        } else {
          context.read<PageUtilsBloc>().initScreenActive(authState);
        }
      },
    );
    setState(() {
      loadingEmit = false;
    });
  }

  num _getTotal(MakeOrderState state) {
    num total = 0;
    for (var e in state.itemsSelected) {
      for (var i in e.items) {
        total += i.taxPrice;
      }
    }
    return total;
  }

  _editItem(BuildContext context, Item item, int indexC, int indexI) {
    CustomAlerts.defaultAlert(
        defaultScroll: false,
        padding: EdgeInsets.zero,
        context: context,
        dismissible: true,
        child: ItemOptionsModal(
          item: item,
          state: widget.state,
        )).then((result) {
      if (result is Item) {
        var itemNew = result;
        context
            .read<MakeOrderBloc>()
            .updateItemSelected(itemNew, indexC, indexI);
      }
    });
  }
}
