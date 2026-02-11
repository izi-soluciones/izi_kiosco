import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/ui/general/izi_header_kiosk.dart';
import 'package:izi_kiosco/ui/general/izi_scroll.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/modals/item_options_modal.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/widgets/make_order_category.dart';
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

        IziHeaderKiosk(onPop: () {
          GoRouter.of(context).goNamed(RoutesKeys.home);
          context.read<PageUtilsBloc>().closeScreenActive();
        },
          smallLogo: !ru.isVertical() || ru.isXs(),
        ),
        _headerLarge(ru),
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
      bool isFeatured = widget.makeOrderState.itemsFeatured.isNotEmpty && widget.makeOrderState.indexCategory==0;
      int isHorizontal = !ru.isVertical()?1:0;
      return IziScroll(
        scrollController: scrollControllerLg,
        child: AlignedGridView.count(
          crossAxisCount: layout.maxWidth > 1500
              ? (isFeatured?4:6)+isHorizontal
              : layout.maxWidth > 1250
              ? (isFeatured?3:5)+isHorizontal
              : layout.maxWidth > 1000
              ? (isFeatured?2:4)+isHorizontal
              : layout.maxWidth > 800
              ? (isFeatured?2:3)+isHorizontal
              : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          controller: scrollControllerLg,
          padding:
              EdgeInsets.only(top: ru.isXs()?0:16, right: 32, left: 32, bottom: 63),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return MakeOrderItemLg(
              item: items[index],
              onPressed: () {
                _selectItem(items,index);
              },
              state: widget.makeOrderState,
            );
          },
        ),
      );
    });
  }
  _selectItem(List<Item> items,int index){
    if (items[index].modificadores.isEmpty) {
      var itemNew = items[index].copyWith();
      itemNew.cantidad = 1;
      context.read<MakeOrderBloc>().addItem(item: itemNew);
    } else {
      CustomAlerts.defaultAlert(
          defaultScroll: false,
          padding: EdgeInsets.zero,
          context: context,
          dismissible: false,
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
  }
  
IconData _selectIconCategory(String name) {
  if (name.isEmpty) {
    return IziIcons.values["client"]!;
  }
  for (var entry in IziIcons.values.entries) {
    final key = entry.key.toLowerCase();
    final contains = name.toLowerCase().contains(key);
    if (contains) {
      return entry.value;
    }
  }
  return IziIcons.values["list"]!; //icono predeterminado
}


  Widget _headerLarge(ResponsiveUtils ru) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: ru.isXs()?16:ru.isVertical()?32:16),
      child: RowContainer(
          gap: 16,
          children: widget.makeOrderState.categories.asMap().entries.map((e) {
            return MakeOrderCategory(
                isHorizontal: !ru.isVertical() || ru.isXs(),
                icon: _selectIconCategory(e.value.nombre.toLowerCase()),
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
