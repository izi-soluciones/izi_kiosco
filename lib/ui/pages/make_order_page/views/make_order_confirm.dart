import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_btn_icon.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_amount_btn.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_header_lg.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';

class MakeOrderConfirm extends StatefulWidget {
  final MakeOrderState state;
  const MakeOrderConfirm({super.key, required this.state});

  @override
  State<MakeOrderConfirm> createState() => _MakeOrderConfirmState();
}

class _MakeOrderConfirmState extends State<MakeOrderConfirm> {
  List<TextEditingController> controllers = [];
  ScrollController scrollController = ScrollController();
  bool loadingEmit = false;
  @override
  void initState() {
    for (var c in widget.state.itemsSelected) {
      List.generate(c.items.length, (index) {
        controllers.add(TextEditingController());
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MakeOrderHeaderLg(onPop: () {
                    context.read<MakeOrderBloc>().changeReviewStatus(false);
                  }),
                  const SizedBox(
                    height: 40,
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  IziText.titleMedium(
                                      color: IziColors.darkGrey,
                                      textAlign: TextAlign.left,
                                      text: "${LocaleKeys
                                          .makeOrder_body_confirmOrder
                                          .tr()}:",
                                      fontWeight: FontWeight.w500),
                                  const SizedBox(
                                    height: 32,
                                  ),
                                  Flexible(
                                    child: IziScroll(
                                      scrollController: scrollController,
                                      child: SingleChildScrollView(
                                        controller: scrollController,
                                        child: _listItems(widget.state),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IziText.title(
                                        color: IziColors.darkGrey,
                                        fontWeight: FontWeight.w600,
                                        text:
                                            "${LocaleKeys.makeOrder_labels_total.tr()}: ${(_getTotal(widget.state) - widget.state.discountAmount).moneyFormat(currency: widget.state.currentCurrency?.simbolo)}",
                                      ),
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
                  _totalOrder(context, widget.state)
                ],
              ),
            ),
            if (loadingEmit)
              Positioned.fill(
                  child: Container(
                color: Colors.transparent,
              ))
          ],
        ));
  }

  _listItems(MakeOrderState state) {
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
                      border: e.key<state.itemsSelected.length-1 || i.key<e.value.items.length-1?const Border(bottom: BorderSide(color: IziColors.grey35,width: 1)):null
                    ),
                    child: SizedBox(
                        child: _item(
                            i.value,
                            cIndex < controllers.length - 1
                                ? controllers[cIndex]
                                : null,
                            e.key,
                            i.key)),
                  );
                },
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  _totalOrder(BuildContext context, MakeOrderState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: IziBtn(
                    buttonText: LocaleKeys.makeOrder_buttons_addMore.tr(),
                    buttonType: ButtonType.outline,
                    buttonSize: ButtonSize.large,
                    buttonOnPressed: () {
                      context.read<MakeOrderBloc>().changeReviewStatus(false);
                    }),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                  flex: 8,
                  child: MakeOrderAmountBtn(
                      onPressed: _getTotal(state) > 0
                          ? () {
                              _emitOrder(context);
                            }
                          : null,
                      text: LocaleKeys.makeOrder_buttons_confirmAndPay.tr(),
                      amount: (_getTotal(state) - state.discountAmount)
                          .moneyFormat(
                              currency: state.currentCurrency?.simbolo)))
            ],
          ),
          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }

  _item(Item item, TextEditingController? controller, int indexCategory,
      int indexItem) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 68,
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
                        child: Icon(IziIcons.dish, color: IziColors.warmLighten))
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
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IziText.title(
                    textAlign: TextAlign.left,
                    color: IziColors.dark,
                    text: item.nombre,
                    fontWeight: FontWeight.w600,
                    maxLines: 2),

                ...item.modificadores.map(
                      (e) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: e.caracteristicas
                          .where((element) => element.check)
                          .map((c) {
                        return IziText.bodySmall(
                            color: IziColors.darkGrey,
                            text:
                            "${c.nombre}${c.modPrecio > 0 ? " (+${c.modPrecio})" : ""}",
                            fontWeight: FontWeight.w400);
                      }).toList(),
                    );
                  },
                ).toList(),
              ],
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          IziText.body(
              textAlign: TextAlign.center,
              color: IziColors.grey,
              text: (item.precioModificadores +
                  item.cantidad * item.precioUnitario)
                  .moneyFormat(currency: widget.state.currentCurrency?.simbolo),
              fontWeight: FontWeight.w500),
          const SizedBox(
            width: 16,
          ),
          IziBtnIcon(
              buttonIcon: IziIcons.close,
              buttonType: ButtonType.secondary,
              buttonSize: ButtonSize.medium,
              color: IziColors.red,
              buttonOnPressed: () {
                context
                    .read<MakeOrderBloc>()
                    .removeItem(indexCategory, indexItem);
                if (widget.state.itemsSelected.length == 1 &&
                    widget.state.itemsSelected[0].items.length == 1) {
                  context.read<MakeOrderBloc>().changeReviewStatus(false);
                }
              })
        ],
      ),
    );
  }

  _emitOrder(BuildContext context) async {
    setState(() {
      loadingEmit = true;
    });
    context
        .read<PageUtilsBloc>()
        .showLoading(LocaleKeys.makeOrder_buttons_confirmingOrder.tr());
    context.read<PageUtilsBloc>().closeScreenActive();
    await context
        .read<MakeOrderBloc>()
        .emitOrder(context.read<AuthBloc>().state)
        .then(
      (value) {
        context.read<PageUtilsBloc>().closeLoading();
        if (value is Comanda) {
          context.read<PageUtilsBloc>().initScreenActiveInvoiced();
          GoRouter.of(this.context).goNamed(RoutesKeys.payment,
              extra: value, pathParameters: {"id": value.id.toString()});
        } else {
          context.read<PageUtilsBloc>().initScreenActive();
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
        total += i.cantidad * i.precioUnitario + i.precioModificadores;
      }
    }
    return total;
  }
}
