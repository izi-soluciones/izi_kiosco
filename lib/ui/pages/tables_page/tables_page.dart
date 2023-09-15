import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/atoms/izi_list_item_status.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/tables/tables_bloc.dart';
import 'package:izi_kiosco/domain/models/cash_register.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/domain/models/consumption_point.dart';
import 'package:izi_kiosco/ui/modals/number_diners_modal.dart';
import 'package:izi_kiosco/ui/modals/warning_config_modal.dart';
import 'package:izi_kiosco/ui/modals/warning_modal.dart';
import 'package:izi_kiosco/ui/general/headers/back_mobile_header.dart';
import 'package:izi_kiosco/ui/general/izi_app_bar.dart';
import 'package:izi_kiosco/ui/modals/order_details.dart';
import 'package:izi_kiosco/ui/pages/tables_page/widgets/cash_register_component.dart';
import 'package:izi_kiosco/ui/pages/tables_page/widgets/table_component.dart';
import 'package:izi_kiosco/ui/pages/tables_page/widgets/table_component_sm.dart';
import 'package:izi_kiosco/ui/pages/tables_page/widgets/tables_shimmer.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/flex_container.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class TablesPage extends StatelessWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        BlocProvider.of<TablesBloc>(context)
            .init(context.read<AuthBloc>().state);
      },
      listenWhen: (state1, state2) {
        return state1.currentSucursal?.id != state2.currentSucursal?.id;
      },
      child: BlocConsumer<TablesBloc, TablesState>(listener: (context, state) {
        if (state.status == TablesStatus.errorPermissions) {
          CustomAlerts.defaultAlert(
                  context: context,
                  dismissible: true,
                  child: WarningConfigModal(
                      title: LocaleKeys.warningPermissions_title.tr(),
                      description: ""))
              .then((value) {
            GoRouter.of(context).goNamed(RoutesKeys.home);
          });
        }
        if (state.status == TablesStatus.errorRooms) {
          CustomAlerts.defaultAlert(
                  context: context,
                  dismissible: true,
                  child: WarningConfigModal(
                      title: LocaleKeys.warningRooms_title.tr(),
                      description: LocaleKeys.warningRooms_description.tr()))
              .then((value) {
            GoRouter.of(context).goNamed(RoutesKeys.home);
          });
        }
        if (state.status == TablesStatus.errorCashRegisters) {
          CustomAlerts.defaultAlert(
                  context: context,
                  dismissible: true,
                  child: WarningConfigModal(
                      title: LocaleKeys.warningCashRegisters_title.tr(),
                      description:
                          LocaleKeys.warningCashRegisters_description.tr()))
              .then((value) {
            GoRouter.of(context).goNamed(RoutesKeys.home);
          });
        }

        if (state.status == TablesStatus.errorGetOrder ||
            state.status == TablesStatus.errorGet ||
            state.status == TablesStatus.errorCancelTable ||
            state.status == TablesStatus.errorCancelOrder) {
          context.read<PageUtilsBloc>().showSnackBar(
              snackBar: SnackBarInfo(
                  text: (state.status == TablesStatus.errorGetOrder
                      ? LocaleKeys.tables_messages_errorGetOrder.tr()
                      : state.status == TablesStatus.errorGet
                          ? LocaleKeys.tables_messages_errorGet.tr()
                          : state.status == TablesStatus.errorCancelOrder
                              ? LocaleKeys.tables_messages_errorCancelOrder.tr()
                              : state.status == TablesStatus.errorCancelTable
                                  ? LocaleKeys.tables_messages_errorCancelTable
                                      .tr()
                                  : LocaleKeys.tables_messages_errorRooms.tr()),
                  snackBarType: SnackBarType.error));
        }
      }, builder: (context, state) {
        return Column(
          children: [
            if (ru.isXs())
              BackMobileHeader(
                  title: IziText.title(
                      mobile: true,
                      color: IziColors.dark,
                      text: LocaleKeys.tables_title.tr()),
                  onBack: () {
                    GoRouter.of(context).goNamed(RoutesKeys.home);
                  }),
            if (ru.gtXs()) const IziAppBar(),
            if (state.status == TablesStatus.init ||
                state.status == TablesStatus.waitingGet)
              const Expanded(child: TablesShimmer()),
            if (state.status == TablesStatus.successGet)
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: ru.isXs() ? 16 : 32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: state.consumptionPoints.isNotEmpty &&
                                    state.consumptionPoints.first.length > 12
                                ? double.infinity
                                : 1300,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(
                                  height: 12,
                                ),
                                _roomSelect(ru, state, context),
                                const SizedBox(
                                  height: 16,
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (ru.isXs() || _isSmallTable(ru, state)) {
                                      return _tableSelectSm(
                                          ru, state, constraints, context);
                                    }
                                    return _tableSelect(
                                        ru, state, constraints, context);
                                  },
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                if (ru.lwSm() || _isSmall(ru, state))
                                  const Divider(color: IziColors.grey25),
                                if (ru.lwSm() || _isSmall(ru, state))
                                  const SizedBox(
                                    height: 20,
                                  ),
                                if (ru.lwSm() || _isSmall(ru, state))
                                  Row(
                                    children: [
                                      IziText.titleSmall(
                                          color: IziColors.darkGrey85,
                                          text: LocaleKeys
                                              .tables_subtitles_cashRegisters
                                              .tr(),
                                          mobile: true),
                                    ],
                                  ),
                                if (ru.lwSm() || _isSmall(ru, state))
                                  const SizedBox(
                                    height: 12,
                                  ),
                                if (ru.lwSm() || _isSmall(ru, state))
                                  _cashRegistersHorizontal(state, ru),
                                if (ru.lwSm() || _isSmall(ru, state))
                                  const SizedBox(
                                    height: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (ru.gtSm() && !_isSmall(ru, state))
                        const SizedBox(
                          width: 24,
                        ),
                      if (ru.gtSm() && !_isSmall(ru, state))
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 260,
                          ),
                          child: _cashRegisters(state),
                        )
                    ],
                  ),
                ),
              )
          ],
        );
      }),
    );
  }

  bool _isSmallTable(ResponsiveUtils ru, TablesState tablesState) {
    if (ru.isMd() &&
        tablesState.consumptionPoints.isNotEmpty &&
        tablesState.consumptionPoints.first.length > 11) {
      return true;
    }
    if (ru.isSm() &&
        tablesState.consumptionPoints.isNotEmpty &&
        tablesState.consumptionPoints.first.length > 7) {
      return true;
    }
    return false;
  }

  bool _isSmall(ResponsiveUtils ru, TablesState tablesState) {
    if (ru.isXl() &&
        tablesState.consumptionPoints.isNotEmpty &&
        tablesState.consumptionPoints.first.length > 15) {
      return true;
    }
    if (ru.isLg() &&
        tablesState.consumptionPoints.isNotEmpty &&
        tablesState.consumptionPoints.first.length > 12) {
      return true;
    }
    if (ru.isMd() &&
        tablesState.consumptionPoints.isNotEmpty &&
        tablesState.consumptionPoints.first.length > 3) {
      return true;
    }
    return false;
  }

  _cashRegisters(TablesState tablesState) {
    List<CashRegister> listFilter = [];
    for (var cash in tablesState.cashRegisters) {
      if (tablesState.rooms[tablesState.roomSelected].cajas.contains(cash.id)) {
        listFilter.add(cash);
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: listFilter.length,
            itemBuilder: (context, index) {
              return CashRegisterComponent(cashRegister: listFilter[index]);
            },
            separatorBuilder: (context, index) {
              return const SizedBox(
                height: 20,
              );
            },
          ),
        ),
      ],
    );
  }

  _cashRegistersHorizontal(TablesState tablesState, ResponsiveUtils ru) {
    List<CashRegister> listFilter = [];
    for (var cash in tablesState.cashRegisters) {
      if (tablesState.rooms[tablesState.roomSelected].cajas.contains(cash.id)) {
        listFilter.add(cash);
      }
    }
    return FlexContainer(
      flexDirection: FlexDirection.row,
      alignment: WrapAlignment.start,
      gapH: 16,
      gapV: 16,
      children: listFilter.asMap().entries.map((e) {
        return SizedBox(
            width: ru.isXs() ? double.infinity : 260,
            child: CashRegisterComponent(cashRegister: e.value));
      }).toList(),
    );
  }

  _tableSelectSm(ResponsiveUtils ru, TablesState tablesState,
      BoxConstraints layout, BuildContext context) {
    List<Widget> list = [];
    for (int i = 0; i < tablesState.consumptionPoints.length; i++) {
      for (int j = 0; j < tablesState.consumptionPoints[i].length; j++) {
        if (tablesState.consumptionPoints[i][j] != null) {
          list.add(TableComponentSm(
              onPressed: (details) {
                if (tablesState.consumptionPoints[i][j]?.status ==
                    ConsumptionPointStatus.fill) {
                  _selectOptions(
                      context: context,
                      consumptionPoint: tablesState.consumptionPoints[i][j]!,
                      offset: details.globalPosition,
                      indexX: j,
                      indexY: i);
                } else {
                  _newOrder(context, tablesState.consumptionPoints[i][j]!);
                }
              },
              onLongPressed: (details) {
                if (tablesState.consumptionPoints[i][j]?.status ==
                    ConsumptionPointStatus.fill) {
                  _closeTable(
                      context: context,
                      consumptionPoint: tablesState.consumptionPoints[i][j]!,
                      offset: details.globalPosition,
                      indexX: j,
                      indexY: i);
                }
              },
              consumptionPoint: tablesState.consumptionPoints[i][j]!));
        }
      }
    }
    return IziCard(
      border: ru.isXs() ? false : true,
      elevation: ru.isXs() ? true : false,
      big: ru.isXs() ? false : true,
      padding:
          EdgeInsets.symmetric(horizontal: ru.isXs() ? 12 : 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                ru.isXs() ? MainAxisAlignment.center : MainAxisAlignment.end,
            children: [
              const IziListItemStatus(
                  listItemType: ListItemType.secondaryOutline,
                  listItemText: "",
                  listItemSize: ListItemSize.small),
              const SizedBox(
                width: 6,
              ),
              IziText.body(
                  color: IziColors.darkGrey85,
                  text: LocaleKeys.tables_body_available.tr(),
                  fontWeight: FontWeight.w400),
              const SizedBox(
                width: 16,
              ),
              const IziListItemStatus(
                  listItemType: ListItemType.unavailable,
                  listItemText: "",
                  listItemSize: ListItemSize.small),
              const SizedBox(
                width: 6,
              ),
              IziText.body(
                  color: IziColors.darkGrey85,
                  text: LocaleKeys.tables_body_fill.tr(),
                  fontWeight: FontWeight.w400),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: ru.isXs() ? 1 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio:
                (layout.maxWidth - 48) / (60 * (ru.isXs() ? 1 : 2)),
            children: list,
          ),
        ],
      ),
    );
  }

  _tableSelect(ResponsiveUtils ru, TablesState tablesState,
      BoxConstraints layout, BuildContext context) {
    List<Widget> list = [];
    for (int i = 0; i < tablesState.consumptionPoints.length; i++) {
      List<Widget> listRow = [];
      for (int j = 0; j < tablesState.consumptionPoints[i].length; j++) {
        var size = (layout.maxWidth -
                tablesState.consumptionPoints[i].length -
                47 -
                (ru.isXs() ? 0 : 6)) /
            tablesState.consumptionPoints[i].length;
        if (tablesState.consumptionPoints[i][j]?.loading == true) {}
        listRow.add(Row(
          children: [
            tablesState.consumptionPoints[i][j] != null
                ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: TableComponent(
                        size: size - 8,
                        onPressed: (details) {
                          if (tablesState.consumptionPoints[i][j]?.status ==
                              ConsumptionPointStatus.fill) {
                            _selectOptions(
                                context: context,
                                consumptionPoint:
                                    tablesState.consumptionPoints[i][j]!,
                                offset: details.globalPosition,
                                indexX: j,
                                indexY: i);
                          } else {
                            _newOrder(
                                context, tablesState.consumptionPoints[i][j]!);
                          }
                        },
                        onLongPressed: (details) {
                          if (tablesState.consumptionPoints[i][j]?.status ==
                              ConsumptionPointStatus.fill) {
                            _closeTable(
                                context: context,
                                consumptionPoint:
                                    tablesState.consumptionPoints[i][j]!,
                                offset: details.globalPosition,
                                indexX: j,
                                indexY: i);
                          }
                        },
                        consumptionPoint: tablesState.consumptionPoints[i][j]!),
                  )
                : SizedBox(
                    width: size,
                    height: size,
                  ),
            if (j < tablesState.consumptionPoints[i].length - 1)
              SizedBox(
                height: size,
                child: Container(
                  color: IziColors.lightGrey30,
                  width: 1,
                ),
              )
          ],
        ));
      }
      list.add(Row(children: listRow));
      if (i < tablesState.consumptionPoints.length - 1) {
        list.add(Container(
          color: IziColors.lightGrey30,
          height: 1,
        ));
      }
    }
    return IziCard(
      border: ru.isXs() ? false : true,
      elevation: ru.isXs() ? true : false,
      big: ru.isXs() ? false : true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const IziListItemStatus(
                  listItemType: ListItemType.secondaryOutline,
                  listItemText: "",
                  listItemSize: ListItemSize.small),
              const SizedBox(
                width: 6,
              ),
              IziText.body(
                  color: IziColors.darkGrey85,
                  text: LocaleKeys.tables_body_available.tr(),
                  fontWeight: FontWeight.w400),
              const SizedBox(
                width: 16,
              ),
              const IziListItemStatus(
                  listItemType: ListItemType.unavailable,
                  listItemText: "",
                  listItemSize: ListItemSize.small),
              const SizedBox(
                width: 6,
              ),
              IziText.body(
                  color: IziColors.darkGrey85,
                  text: LocaleKeys.tables_body_fill.tr(),
                  fontWeight: FontWeight.w400),
            ],
          ),
          ...list
        ],
      ),
    );
  }

  _roomSelect(
      ResponsiveUtils ru, TablesState tablesState, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IziText.body(
            color: IziColors.darkGrey85,
            text: LocaleKeys.tables_subtitles_spaces.tr(),
            fontWeight: FontWeight.w600),
        if (ru.lwSm())
          const SizedBox(
            height: 16,
          ),
        FlexContainer(
            flexDirection: FlexDirection.row,
            gapH: 16,
            gapV: 10,
            children: tablesState.rooms.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IziBtn(
                      buttonText: e.value.nombre,
                      buttonType: tablesState.roomSelected == e.key
                          ? ButtonType.primary
                          : ButtonType.terciary,
                      buttonSize:
                          ru.lwSm() ? ButtonSize.small : ButtonSize.medium,
                      buttonOnPressed: () {
                        context.read<TablesBloc>().changeRoom(
                            e.key, e.value.id, context.read<AuthBloc>().state);
                      }),
                ],
              );
            }).toList())
      ],
    );
  }

  _closeTable(
      {required BuildContext context,
      required ConsumptionPoint consumptionPoint,
      required Offset offset,
      required indexX,
      required indexY}) {
    return CustomAlerts.showTapMenu(
            offset,
            [
              TapMenuItem(
                  name: LocaleKeys.tables_buttons_closeTable.tr(),
                  value: 1,
                  color: IziColors.red,
                  fontWeight: FontWeight.w500),
            ],
            context)
        .then((value) async {
      switch (value) {
        case 1:
          CustomAlerts.defaultAlert(
              context: context,
              dismissible: false,
              child: WarningModal(
                onAccept: () async {
                  await context.read<TablesBloc>().changeTableStatus(
                      context.read<AuthBloc>().state, indexX, indexY);
                },
                title: LocaleKeys.tables_subtitles_areYouSureFreeTable
                    .tr(args: [consumptionPoint.nombre]),
              ));
          break;
      }
    });
  }

  _selectOptions(
      {required BuildContext context,
      required ConsumptionPoint consumptionPoint,
      required Offset offset,
      required indexX,
      required indexY}) async {
    return CustomAlerts.showTapMenu(
            offset,
            [
              TapMenuItem(
                  name: LocaleKeys.tables_buttons_modifyOrder.tr(), value: 1),
              TapMenuItem(
                  name: LocaleKeys.tables_buttons_printOrderDetail.tr(),
                  value: 2),
              TapMenuItem(
                  name: LocaleKeys.tables_buttons_completeOrderDetail.tr(),
                  value: 3),
              TapMenuItem(
                  name: LocaleKeys.tables_buttons_closeAndPay.tr(),
                  value: 4,
                  color: IziColors.dark,
                  fontWeight: FontWeight.w600)
            ],
            context)
        .then((value) async {
      switch (value) {
        case 1:
          _modifyOrder(context, indexX, indexY, consumptionPoint);
          break;
        case 2:
          context.read<TablesBloc>().downloadDetail(indexX, indexY);
          break;
        case 3:
          context
              .read<TablesBloc>()
              .getComanda(indexX, indexY)
              .then((Comanda? order) {
            if (order != null) {
              CustomAlerts.alertRight(
                  content: OrderDetails(
                    order: order,
                    consumptionPoint: consumptionPoint,
                    fromTables: true,
                  ),
                  context: context);
            }
          });
          break;
        case 4:
          GoRouter.of(context).pushNamed(RoutesKeys.payment,
              pathParameters: {"id": consumptionPoint.comandaId.toString()});
          break;
      }
    });
  }

  _modifyOrder(
      BuildContext context, indexX, indexY, ConsumptionPoint consumptionPoint) {
    context
        .read<TablesBloc>()
        .getComanda(indexX, indexY)
        .then((Comanda? order) {
      if (order != null) {
        GoRouter.of(context).goNamed(RoutesKeys.makeOrder, extra: {
          "tableId": consumptionPoint.id,
          "numberDiners": consumptionPoint.cantidadComensales,
          "fromTables": true,
          "order": order
        });
      }
    });
  }

  _newOrder(BuildContext context, ConsumptionPoint consumptionPoint) {
    CustomAlerts.defaultAlert(
            padding: EdgeInsets.zero,
            dismissible: true,
            context: context,
            child: const NumberDinersModal())
        .then((value) {
      if (value is num) {
        GoRouter.of(context).goNamed(RoutesKeys.makeOrder, extra: {
          "tableId": consumptionPoint.id,
          "numberDiners": value,
          "fromTables": true
        });
      }
    });
  }
}

enum AvailableOptions { modify, print, completeDetail, closeOrder }
