import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
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
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          context.read<MakeOrderBloc>().changeReviewStatus(false);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(24),
                          child:
                              Icon(IziIcons.leftB, color: IziColors.darkGrey, size: 50),
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: IziScroll(
                        scrollController: scrollController,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          controller: scrollController,
                          child: Column(
                            children: [
                              IziText.titleMedium(
                                  color: IziColors.darkGrey,
                                  text: LocaleKeys.makeOrder_body_confirmOrder.tr(),
                                  fontWeight: FontWeight.w500),
                              const SizedBox(
                                height: 50,
                              ),
                              FractionallySizedBox(
                                  widthFactor: 0.7,
                                  alignment: Alignment.center,
                                  child: _listItems(widget.state))
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _totalOrder(context,widget.state)
                ],
              ),
            ),
            if(loadingEmit)
              Positioned.fill(child: Container(color: Colors.transparent,))
          ],
        )
    );
  }

  _listItems(MakeOrderState state) {
    var cIndex = -1;
    return ColumnContainer(
      gap: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          state.itemsSelected.asMap().entries.map((e) {
        return ColumnContainer(
          gap: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...e.value.items.asMap().entries.map(
              (i) {
                cIndex++;
                return SizedBox(
                    height: 110,
                    child: _item(
                        i.value,
                        cIndex < controllers.length - 1
                            ? controllers[cIndex]
                            : null,
                        e.key,
                        i.key));
              },
            )
          ],
        );
      }).toList(),
    );
  }

  _totalOrder(BuildContext context,MakeOrderState state) {
    return Container(
      color: IziColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IziText.bodyBig(
                  color: IziColors.grey,
                  text: LocaleKeys.makeOrder_labels_total.tr(),
                  fontWeight: FontWeight.w600),
              const SizedBox(
                width: 16,
              ),
              IziText.bodyBig(
                  color: IziColors.darkGrey,
                  text:
                      (_getTotal(state) - state.discountAmount)
                          .moneyFormat(
                              currency: state
                                  .currentCurrency?.simbolo),
                  fontWeight: FontWeight.w600),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: IziBtn(
                    buttonText: LocaleKeys.makeOrder_buttons_addMore.tr(),
                    buttonType: ButtonType.terciary,
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
                child: IziBtn(
                    buttonText: LocaleKeys.makeOrder_buttons_confirmAndPay.tr(),
                    buttonType: ButtonType.secondary,
                    buttonSize: ButtonSize.large,
                    loading: loadingEmit,
                    buttonOnPressed: _getTotal(state) > 0
                        ? () {
                            _emitOrder(context);
                          }
                        : null),
              )
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
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 10),
          child: IziCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: IziColors.grey25,
                    child: item.imagen == null || item.imagen?.isEmpty == true
                        ? const FittedBox(
                            child: Icon(IziIcons.dish,
                                color: IziColors.warmLighten))
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 16, top: 8),
                              child: IziText.body(
                                  color: IziColors.dark,
                                  text: item.nombre,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 2),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: IziInput(
                                autoSelect: true,
                                textAlign: TextAlign.center,
                                controller: controller,
                                inputHintText: "0",
                                inputType: InputType.incremental,
                                minValue: 1,
                                maxValue: 999999999,
                                inputSize: InputSize.extraSmall,
                                value: item.cantidad.toString(),
                                onChanged: (value, valueRaw) {
                                  item.cantidad = num.tryParse(value) ?? 1;
                                  context.read<MakeOrderBloc>().reloadItems();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IziText.bodyBig(
                                color: IziColors.grey,
                                text: LocaleKeys.makeOrder_labels_price.tr(),
                                fontWeight: FontWeight.w400),
                            const SizedBox(width: 5),
                            IziText.body(
                                textAlign: TextAlign.center,
                                color: IziColors.darkGrey,
                                text: (item.precioModificadores +
                                        item.cantidad * item.precioUnitario)
                                    .moneyFormat(),
                                fontWeight: FontWeight.w500),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: InkWell(
            radius: 20,
            onTap: () {
              context.read<MakeOrderBloc>().removeItem(indexCategory, indexItem);
            },
            child: Container(
              decoration: const BoxDecoration(
                  color: IziColors.dark, shape: BoxShape.circle),
              child: const Icon(
                IziIcons.close,
                size: 25,
                color: IziColors.white,
              ),
            ),
          ),
        )
      ],
    );
  }

  _emitOrder(BuildContext context) async {
    setState(() {
      loadingEmit = true;
    });
    await context.read<MakeOrderBloc>().emitOrder(context.read<AuthBloc>().state).then(
      (value) {
        if (value is Comanda) {
          GoRouter.of(this.context).goNamed(RoutesKeys.payment,
              extra: value, pathParameters: {"id": value.id.toString()});
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
