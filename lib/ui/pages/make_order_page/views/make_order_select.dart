import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/molecules/izi_btn_icon.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/item_options_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_item_options.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_category.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_header_sm.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_item_lg.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_item_sm.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class MakeOrderSelect extends StatefulWidget {
  final MakeOrderState makeOrderState;
  final bool fromTables;
  const MakeOrderSelect({super.key, required this.fromTables,required this.makeOrderState});

  @override
  State<MakeOrderSelect> createState() => _MakeOrderSelectState();
}

class _MakeOrderSelectState extends State<MakeOrderSelect> {
  bool searchOpen = false;
  TextEditingController searchInput = TextEditingController();
  FocusNode focusNode = FocusNode();
  ScrollController scrollControllerSm=ScrollController();

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ru.gtXs()) _headerLarge(),
        if(ru.isXs()) MakeOrderHeaderSm(state: widget.makeOrderState,onPop: (){
          if(widget.fromTables){
            GoRouter.of(context).goNamed(RoutesKeys.tables);
          }
          else{
            GoRouter.of(context).goNamed(RoutesKeys.home);
          }
        },),
        if (ru.isXs()) _headerSmall(),
        const Divider(
          color: IziColors.grey25,
          height: 1,
        ),
        if (ru.gtXs())
        Expanded(child: _itemsLg(ru)),
        if (ru.isXs())
        Expanded(child: _itemsSm(ru))
      ],
    );
  }
  Widget _itemsSm(ResponsiveUtils ru) {
    List<Item> items = widget.makeOrderState.categories.isNotEmpty
        ? List.of(widget.makeOrderState
        .categories[widget.makeOrderState.indexCategory].items)
        : [];
    items = items
        .where((element) =>
    searchInput.text.isEmpty ||
        element.nombre
            .toLowerCase()
            .contains(searchInput.text.toLowerCase()))
        .toList();
    return IziScroll(
      scrollController: scrollControllerSm,
      child: ListView.separated(
        controller: scrollControllerSm,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        padding:
        const EdgeInsets.only(top: 16, right: 16, left: 16, bottom: 63),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
            height: 76,
            child: MakeOrderItemSm(
              item: items[index],
              onPressed: () {
                CustomAlerts.alertExpanded(
                    context: context,
                    dismissible: true,
                  content: MakeOrderItemOptions(
                      item: items[index], state: widget.makeOrderState)
                )
                    .then((result) {
                  if (result is Item) {
                    var itemNew = result;
                    context.read<MakeOrderBloc>().addItem(item: itemNew);
                  }
                });
              },
              state: widget.makeOrderState,
            ),
          );
        },
      ),
    );
  }
  Widget _itemsLg(ResponsiveUtils ru) {
    List<Item> items = widget.makeOrderState.categories.isNotEmpty
        ? List.of(widget.makeOrderState
            .categories[widget.makeOrderState.indexCategory].items)
        : [];
    items = items
        .where((element) =>
            searchInput.text.isEmpty ||
            element.nombre
                .toLowerCase()
                .contains(searchInput.text.toLowerCase()))
        .toList();
    return LayoutBuilder(builder: (context, layout) {
      return GridView.builder(
        padding:
            const EdgeInsets.only(top: 16, right: 32, left: 32, bottom: 63),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.maxWidth > 1500
                ? 6
                : layout.maxWidth > 1250
                    ? 5
                : layout.maxWidth > 950
                ? 4
                    : layout.maxWidth > 700
                        ? 3
                        : layout.maxWidth > 450
                            ? 2
                            : 1,
            childAspectRatio: layout.maxWidth > 700?1.4:layout.maxWidth > 450?1.3:1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 18),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          return MakeOrderItemLg(
            item: items[index],
            onPressed: () {
              if (items[index].modificadores.isEmpty) {
                var itemNew = items[index].copyWith();
                itemNew.cantidad = 1;
                context.read<MakeOrderBloc>().addItem(item: itemNew);
              } else {
                CustomAlerts.defaultAlert(
                        defaultScroll: false,
                        padding: EdgeInsets.zero,
                        context: context,
                        dismissible: true,
                        child: ItemOptionsModal(
                            item: items[index], state: widget.makeOrderState))
                    .then((result) {
                  if (result is Item) {
                    var itemNew = result;
                    itemNew.cantidad = 1;
                    context.read<MakeOrderBloc>().addItem(item: itemNew);
                  }
                });
              }
            },
            state: widget.makeOrderState,
          );
        },
      );
    });
  }
  Widget _headerSmall() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16,top: 16),
          child: IziInput(
            background: IziColors.white,
            inputHintText: LocaleKeys
                .makeOrder_inputs_search_placeholder
                .tr(),
            inputType: InputType.clear,
            prefixIcon: IziIcons.search,
            forceNoSuffix: true,
            controller: searchInput,
            focusNode: focusNode,
            onChanged: (p0, p1) {
              setState(() {});
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: RowContainer(
            gap: 16,
            children: [
              ...widget.makeOrderState.categories.asMap().entries.map((e) {
                return MakeOrderCategory(
                  small: true,
                    onPressed: () {
                      context.read<MakeOrderBloc>().changeCategory(e.key);
                    },
                    title: e.value.nombre,
                    count: e.value.items.length,
                    active: widget.makeOrderState.indexCategory == e.key);
              })
            ],
          ),
        ),
      ],
    );
  }
  Widget _headerLarge() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: RowContainer(
        gap: 16,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: searchOpen ? 338 : 0,
                onEnd: () {
                  focusNode.requestFocus();
                },
                child: Stack(
                  children: [
                    Positioned(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 300,
                              child: IziInput(
                                background: IziColors.white,
                                inputHintText: LocaleKeys
                                    .makeOrder_inputs_search_placeholder
                                    .tr(),
                                inputType: InputType.clear,
                                prefixIcon: IziIcons.search,
                                forceNoSuffix: true,
                                controller: searchInput,
                                focusNode: focusNode,
                                onChanged: (p0, p1) {
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  searchOpen = false;
                                  searchInput.text = "";
                                });
                              },
                              child: const Icon(IziIcons.close,
                                  size: 30, color: IziColors.grey),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              if (!searchOpen)
                IziBtnIcon(
                    buttonIcon: IziIcons.search,
                    buttonType: ButtonType.terciary,
                    buttonSize: ButtonSize.large,
                    buttonOnPressed: () {
                      setState(() {
                        searchOpen = true;
                        focusNode.requestFocus();
                      });
                    }),
              const SizedBox(
                width: 16,
              ),
              const SizedBox(
                height: 30,
                child: VerticalDivider(
                  width: 1,
                  color: IziColors.grey35,
                ),
              ),
            ],
          ),
          ...widget.makeOrderState.categories.asMap().entries.map((e) {
            return MakeOrderCategory(
                onPressed: () {
                  context.read<MakeOrderBloc>().changeCategory(e.key);
                },
                title: e.value.nombre,
                count: e.value.items.length,
                active: widget.makeOrderState.indexCategory == e.key);
          })
        ],
      ),
    );
  }
}
