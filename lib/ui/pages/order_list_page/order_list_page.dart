import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_list_item_status.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn_link_icon.dart';
import 'package:izi_design_system/molecules/izi_input.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/organisms/izi_side_nav.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/order_list/order_list_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/dto/filters_comanda.dart';
import 'package:izi_kiosco/ui/general/headers/back_mobile_header.dart';
import 'package:izi_kiosco/ui/general/izi_app_bar.dart';
import 'package:izi_kiosco/ui/general/list_builder_constructor.dart';
import 'package:izi_kiosco/ui/general/shimmer/shimer_item_list_lg.dart';
import 'package:izi_kiosco/ui/general/shimmer/shimer_item_list_sm.dart';
import 'package:izi_kiosco/ui/general/shimmer/shimmer_list_lg.dart';
import 'package:izi_kiosco/ui/general/shimmer/shimmer_list_sm.dart';
import 'package:izi_kiosco/ui/general/title/izi_title_lg.dart';
import 'package:izi_kiosco/ui/pages/order_list_page/modals/order_filters.dart';
import 'package:izi_kiosco/ui/pages/order_list_page/widgets/order_list_item.dart';
import 'package:izi_kiosco/ui/utils/column_container.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/flex_container.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class OrderListPage extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();
  OrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return BlocListener<AuthBloc,AuthState>(
      listener: (context,state){
        BlocProvider.of<OrderListBloc>(context).getOrders(first: true, authState: context.read<AuthBloc>().state);
      },
      listenWhen: (state1,state2){
        return state1.currentSucursal?.id != state2.currentSucursal?.id;
      },
      child: BlocConsumer<OrderListBloc,OrderListState>(
        listener: (context, state) {
          if(state.status == OrderListStatus.errorList || state.status == OrderListStatus.errorCancel || state.status == OrderListStatus.errorMarkInternal){
            context.read<PageUtilsBloc>().showSnackBar(
                snackBar: SnackBarInfo(
                    text: (state.status== OrderListStatus.errorCancel?
                    LocaleKeys.orderList_messages_errorCancel.tr():
                    state.status== OrderListStatus.errorMarkInternal?
                    LocaleKeys.orderList_messages_errorMarkInternal.tr():
                    LocaleKeys.orderList_messages_errorList.tr()),
                    snackBarType: SnackBarType.error));
          }
        },
        builder: (context,state) {
          return Container(
            color: ru.isXs()?null:IziColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if(ru.isXs())
                  BackMobileHeader(
                      title: IziText.title(color: IziColors.dark, text: LocaleKeys.orderList_title.tr()),
                      onBack: (){
                        GoRouter.of(context).goNamed(RoutesKeys.home);
                      }
                  ),
                if (ru.gtXs()) const IziAppBar(),
                if (ru.gtXs())
                  IziTitleLg(
                    title: LocaleKeys.orderList_title.tr(),
                  ),
                if(state.status == OrderListStatus.successList)
                _orderHeader(ru,context,state),
                if(state.status == OrderListStatus.successList)
                Expanded(child: _orderList(context,state,ru)),

                if(state.status == OrderListStatus.waitingList || state.status == OrderListStatus.init)
                  Expanded(child: ru.lwSm()?const ShimmerListSm():const ShimmerListLg())


              ],
            ),
          );
        }
      ),
    );
  }
  Widget _orderList(BuildContext context,OrderListState state,ResponsiveUtils ru){
    return ListBuilderConstructor(
        gap: 12,

        onRefresh: (){
          BlocProvider.of<OrderListBloc>(context).getOrders(first: true, authState: context.read<AuthBloc>().state);
        },
        controller: _scrollController..addListener((){
          if (_scrollController.offset ==
              _scrollController.position.maxScrollExtent &&
              !context.read<OrderListBloc>().state.loadItems&&!context.read<OrderListBloc>().state.endItems) {
            BlocProvider.of<OrderListBloc>(context).getOrders(authState: context.read<AuthBloc>().state);
          }
        }),
        itemBuilder: (context,index){

          if(index>=state.orders.length){
            if(state.endItems) {
              return const SizedBox(height: 100);
            }
            else{
              return ru.isXs()?const ShimmerItemListSm():const ShimmerItemListLg();
            }
          }
          return OrderListItem(order: state.orders[index], state: state);
        },
        count: state.orders.length+1,
        padding: EdgeInsets.symmetric(horizontal: ru.isXs()?16:32,vertical: ru.isXs()?8:16)
    );
  }
  Widget _orderHeader(ResponsiveUtils ru,BuildContext context,OrderListState state){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
      if(ru.gtXs())
      const SizedBox(height: 16,),
      Padding(
        padding: ru.isXs()?EdgeInsets.zero:const EdgeInsets.symmetric(horizontal: 32),
        child: IziCard(
            background: IziColors.lightGrey,
            elevation: false,
            radiusBottom: ru.gtXs(),
            radiusTop: ru.gtXs(),
            padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 15),
            child: ColumnContainer(
              gap: 16,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: ru.isXl()?1/4:ru.isLg()?1/2:ru.isMd()?1/2:1.0,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: IziInput(
                          background: IziColors.white,
                          inputHintText: LocaleKeys.orderList_inputs_search_placeholder.tr(),
                          inputType: InputType.clear,
                          value: state.searchInput.value,
                          onEditingComplete: (){
                            context.read<OrderListBloc>().getOrders(authState: context.read<AuthBloc>().state,first: true);
                          },
                          onClear: (){
                            context.read<OrderListBloc>().changeInputs(search: "");
                            context.read<OrderListBloc>().getOrders(authState: context.read<AuthBloc>().state,first: true);
                          },
                          onChanged: (value,valueRaw){
                            context.read<OrderListBloc>().changeInputs(search: value);
                          },
                          prefixIcon: IziIcons.search,
                        ),
                      ),
                      if(ru.lwSm())
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: IziBtnLinkIcon(
                            filterText: LocaleKeys.general_buttons_filters.tr(),
                            filterNumber: _getFiltersStatus(state.filters),
                            icon: IziIcons.plusB,
                            filterTextOnPress: (){
                              _openFilters(context, state,ru);
                            },
                            clearFilterOnPress: (){
                              context.read<OrderListBloc>().resetFilters(context.read<AuthBloc>().state);
                            },
                          ),
                        )
                    ],
                  ),
                ),
                if(ru.gtSm())
                  RowContainer(
                    gap: 24,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                      Expanded(
                        child: IziInput(
                          background: IziColors.white,
                          labelInput: LocaleKeys.orderList_inputs_status_label.tr(),
                          inputHintText: LocaleKeys.orderList_inputs_status_placeholder.tr(),
                          inputType: InputType.select,
                          value: state.statusInput.value,
                          selectOptions: {
                            "":LocaleKeys.orderList_inputs_status_options_all.tr(),
                            "Facturadas":LocaleKeys.orderList_inputs_status_options_invoiced.tr(),
                            "Sin Facturar":LocaleKeys.orderList_inputs_status_options_noInvoiced.tr(),
                            "Abiertas":LocaleKeys.orderList_inputs_status_options_opened.tr(),
                            "Finalizadas":LocaleKeys.orderList_inputs_status_options_ended.tr(),
                            "Anuladas":LocaleKeys.orderList_inputs_status_options_annulled.tr(),
                          },
                          onSelected: (value){
                            context.read<OrderListBloc>().changeInputs(status: value);
                            context.read<OrderListBloc>().getOrders(authState: context.read<AuthBloc>().state,first: true);
                          },
                        ),
                      ),

                      Expanded(
                        child: IziInput(
                          background: IziColors.white,
                          labelInput: LocaleKeys.orderList_inputs_dateStart_label.tr(),
                          inputHintText: LocaleKeys.orderList_inputs_dateStart_placeholder.tr(),
                          inputType: InputType.datePicker,
                          value: state.dateStartInput.value,
                          currentDate: DateTime.now(),
                          onChanged: (value,valueRaw){
                            context.read<OrderListBloc>().changeInputs(dateStart: valueRaw);
                            context.read<OrderListBloc>().getOrders(authState: context.read<AuthBloc>().state,first: true);
                          },
                          prefixText: LocaleKeys.orderList_inputs_dateStart_prefix.tr(),
                        ),
                      ),
                      Expanded(
                        child: IziInput(
                          background: IziColors.white,
                          inputHintText: LocaleKeys.orderList_inputs_dateEnd_placeholder.tr(),
                          inputType: InputType.datePicker,
                          value: state.dateEndInput.value,
                          currentDate: DateTime.now(),
                          onChanged: (value,valueRaw){
                            context.read<OrderListBloc>().changeInputs(dateEnd: valueRaw);
                            context.read<OrderListBloc>().getOrders(authState: context.read<AuthBloc>().state,first: true);
                          },
                          prefixText: LocaleKeys.orderList_inputs_dateEnd_prefix.tr(),
                        ),
                      ),
                      if(ru.gtMd() && _getFiltersStatus(state.filters)==0)
                        SizedBox(width: ru.isLg()?300:ru.isXl()?500:100,),
                      if(_getFiltersStatus(state.filters)>0)
                      Padding(
                        padding: EdgeInsets.only(left: ru.isLg()?100:ru.isXl()?150:20,bottom: 10),
                        child: IziBtnLinkIcon(
                          filterText: LocaleKeys.general_buttons_filters.tr(),
                          filterNumber: _getFiltersStatus(state.filters),
                          icon: IziIcons.plusB,
                          filterTextOnPress: (){

                          },
                          clearFilterOnPress: (){
                            context.read<OrderListBloc>().resetFilters(context.read<AuthBloc>().state);
                          },
                        ),
                      )
                    ],
                  )
              ],
            )
        ),
      ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32,vertical: 16),
          child: FlexContainer(
            gapH: ru.isXs()?16:36,
            gapV: 8,
            alignment: ru.isXs()?WrapAlignment.center:WrapAlignment.end,
            flexDirection: FlexDirection.row,
            children: [
              RowContainer(
                gap: 8,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IziText.body(color: IziColors.dark, text: LocaleKeys.orderList_body_invoiced.tr(),fontWeight: FontWeight.w400),
                  const IziListItemStatus(
                      listItemType:ListItemType.active,
                      listItemText: "",
                      listItemSize: ListItemSize.small
                  )
                ],
              ),
              RowContainer(
                gap: 8,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IziText.body(color: IziColors.dark, text: LocaleKeys.orderList_body_noInvoiced.tr(),fontWeight: FontWeight.w400),
                  const IziListItemStatus(
                      listItemType: ListItemType.warning,
                      listItemText: "",
                      listItemSize: ListItemSize.small
                  )
                ],
              ),
              RowContainer(
                gap: 8,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IziText.body(color: IziColors.dark, text: LocaleKeys.orderList_body_annulled.tr(),fontWeight: FontWeight.w400),
                  const IziListItemStatus(
                      listItemType:ListItemType.anulled,
                      listItemText: "",
                      listItemSize: ListItemSize.small
                  )
                ],
              ),
            ],
          ),
        )
    ],);
  }

  List<IziSideNavItem> menu(context) {
    return [
      IziSideNavItem(
          name: LocaleKeys.orderList_title.tr(),
          icon: IziIcons.order,
          itemValue: RoutesKeys.order,
          itemLocation: RoutesKeys.orderLink,
          onPressed: () {
            GoRouter.of(context).goNamed(RoutesKeys.order);
          }),
    ];
  }

  _openFilters(BuildContext context,OrderListState state,ResponsiveUtils ru){
    CustomAlerts.alertWithLayout(
        context: context,
        onResult: (value){
          if(value is FiltersComanda){
            context.read<OrderListBloc>().updateFilters(context.read<AuthBloc>().state,value);
          }
        },
        bottomAlert: ru.isXs(),
        widget: OrderFilters(filtersComanda: state.filters)
    );
  }

  int _getFiltersStatus(FiltersComanda filters){
    int val = 0;
    val = val +(filters.dateEnd!=null?1:0);
    val = val +(filters.dateStart!=null?1:0);
    val = val +(filters.searchStr!=null && (filters.searchStr?.isNotEmpty ?? false)?1:0);
    val = val +(filters.status!=null && (filters.status?.isNotEmpty ?? false)?1:0);
    return val;
  }


}
