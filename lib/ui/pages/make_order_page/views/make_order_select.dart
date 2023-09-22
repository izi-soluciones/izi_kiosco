import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/item_options_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_category.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_header_lg.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_item_lg.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class MakeOrderSelect extends StatefulWidget {
  final MakeOrderState makeOrderState;
  final bool fromTables;
  const MakeOrderSelect(
      {super.key, required this.fromTables, required this.makeOrderState});

  @override
  State<MakeOrderSelect> createState() => _MakeOrderSelectState();
}

class _MakeOrderSelectState extends State<MakeOrderSelect> {
  bool searchOpen = false;
  TextEditingController searchInput = TextEditingController();
  FocusNode focusNode = FocusNode();
  ScrollController scrollControllerSm = ScrollController();
  ScrollController scrollControllerLg = ScrollController();

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Column(
      children: [
        /*if(widget.makeOrderState.itemsFeatured.isNotEmpty)
        SizedBox(
          height: 250,
          child: MakeOrderFeatured(state: widget.makeOrderState),
        ),*/

        MakeOrderHeaderLg(onPop: () {
          GoRouter.of(context).goNamed(RoutesKeys.home);
          context.read<PageUtilsBloc>().closeScreenActive();
        }),
        _headerLarge(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _itemsLg(ru)),
            ],
          ),
        ),
      ],
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
      return IziScroll(
        scrollController: scrollControllerLg,
        child: GridView.builder(
          controller: scrollControllerLg,
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
                              ? 4
                              : layout.maxWidth > 450
                                  ? 2
                                  : 1,
              childAspectRatio: layout.maxWidth > 700
                  ? 0.6
                  : layout.maxWidth > 450
                      ? 0.6
                      : 1.5,
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
        ),
      );
    });
  }

  Widget _headerLarge() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: RowContainer(
          gap: 16,
          children: widget.makeOrderState.categories.asMap().entries.map((e) {
            return MakeOrderCategory(
                icon: e.value.nombre.isEmpty
                    ? IziIcons.client
                    : e.value.nombre.toLowerCase().contains("postre")
                        ? IziIcons.cake
                        : e.value.nombre.toLowerCase().contains("sandwich") ||
                                e.value.nombre
                                    .toLowerCase()
                                    .contains("sándwich")
                            ? IziIcons.sandwich
                            : e.value.nombre.toLowerCase().contains("jugo")
                                ? IziIcons.juices
                                : IziIcons.list,
                onPressed: () {
                  context.read<MakeOrderBloc>().changeCategory(e.key);
                },
                title: e.value.nombre.isEmpty
                    ? LocaleKeys.makeOrder_body_featured.tr()
                    : e.value.nombre,
                count: e.value.items.length,
                active: widget.makeOrderState.indexCategory == e.key);
          }).toList()),
    );
  }
}
