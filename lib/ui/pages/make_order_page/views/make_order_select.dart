import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/item_options_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_category.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_item_lg.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

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
  ScrollController scrollControllerLg=ScrollController();

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120,child: _headerLarge()),
        Expanded(child: _itemsLg(ru)),
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
                          ? 3
                          : layout.maxWidth > 450
                              ? 2
                              : 1,
              childAspectRatio: layout.maxWidth > 700?1:layout.maxWidth > 450?1.3:1.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: ColumnContainer(
        gap: 16,
        children: 
          widget.makeOrderState.categories.asMap().entries.map((e) {
            return MakeOrderCategory(
                onPressed: () {
                  context.read<MakeOrderBloc>().changeCategory(e.key);
                },
                title: e.value.nombre,
                count: e.value.items.length,
                active: widget.makeOrderState.indexCategory == e.key);
          }).toList()
      ),
    );
  }
}
