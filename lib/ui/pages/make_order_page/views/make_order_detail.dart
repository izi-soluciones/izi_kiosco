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
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/utils/money_formatter.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class MakeOrderDetail extends StatefulWidget {
  final MakeOrderState state;
  const MakeOrderDetail({super.key, required this.state});

  @override
  State<MakeOrderDetail> createState() => _MakeOrderDetailState();
}

class _MakeOrderDetailState extends State<MakeOrderDetail> {
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
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: IziColors.grey35, width: 1),
          ),
        ),
        child: Column(
          children: [
            widget.state.itemsSelected.isNotEmpty
                ? Expanded(child: _listItems(ru))
                : Expanded(
                    child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: IziText.body(
                          color: IziColors.grey,
                          text:
                              LocaleKeys.makeOrder_body_addDishesOrDrinks.tr(),
                          fontWeight: FontWeight.w400),
                    ),
                  )),
            const Divider(
              color: IziColors.grey35,
              height: 1,
            ),
            _totalOrder()
          ],
        ),
      ),
    );
  }

  _totalOrder() {
    return Container(
      color: IziColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IziText.bodyBig(
                  color: IziColors.grey,
                  text: LocaleKeys.makeOrder_labels_total.tr(),
                  fontWeight: FontWeight.w600),
              IziText.bodyBig(
                  color: IziColors.darkGrey,
                  text: (_getTotal() - widget.state.discountAmount).moneyFormat(
                      currency: widget.state.currentCurrency?.simbolo),
                  fontWeight: FontWeight.w600),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: IziBtn(
                    buttonText: LocaleKeys.makeOrder_buttons_cancel.tr(),
                    buttonType: ButtonType.terciary,
                    buttonSize: ButtonSize.large,
                    buttonOnPressed: () {
                      GoRouter.of(context).goNamed(RoutesKeys.home);
                      context.read<PageUtilsBloc>().closeScreenActive();
                    }),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                flex: 8,
                child: IziBtn(
                    buttonText: LocaleKeys.makeOrder_buttons_confirm.tr(),
                    buttonType: ButtonType.secondary,
                    buttonSize: ButtonSize.large,
                    loading: loadingEmit,
                    buttonOnPressed: _getTotal() > 0
                        ? (){_next(context);}
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

  _next(BuildContext context){
    context.read<MakeOrderBloc>().changeReviewStatus(true);
  }

  _item(Item item, TextEditingController? controller, int indexCategory,
      int indexItem) {
    return SizedBox(
      width: 300,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10,right: 10),
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
                                padding: const EdgeInsets.only(right: 16,top: 8),
                                child: IziText.body(color: IziColors.dark, text: item.nombre, fontWeight: FontWeight.w600,maxLines: 2),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 100
                                ),
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
              context
                  .read<MakeOrderBloc>()
                  .removeItem(indexCategory, indexItem);
            },
            child: Container(
              decoration: const BoxDecoration(
                color: IziColors.dark,
                shape: BoxShape.circle
              ),
              child: const Icon(
                IziIcons.close,
                size: 25,
                color: IziColors.white,
              ),
            ),
          ),)
        ],
      ),
    );
  }


  _listItems(ResponsiveUtils ru) {
    var cIndex = -1;
    return IziScroll(
      scrollController: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 8),
        child: RowContainer(
          gap: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.state.itemsSelected.asMap().entries.map((e) {
            return RowContainer(
              gap: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...e.value.items.asMap().entries.map(
                  (i) {
                    cIndex++;
                    return _item(
                        i.value,
                        cIndex < controllers.length - 1
                            ? controllers[cIndex]
                            : null,
                        e.key,
                        i.key);
                  },
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }



  num _getTotal() {
    num total = 0;
    for (var e in widget.state.itemsSelected) {
      for (var i in e.items) {
        total += i.cantidad * i.precioUnitario + i.precioModificadores;
      }
    }
    return total;
  }
}
