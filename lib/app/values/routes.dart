import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_kiosco/data/repositories/auth/auth_repository_http.dart';
import 'package:izi_kiosco/data/repositories/business/business_repository_http.dart';
import 'package:izi_kiosco/data/repositories/comanda/comanda_repository_http.dart';
import 'package:izi_kiosco/data/repositories/pos/pos_repository_http.dart';
import 'package:izi_kiosco/data/repositories/socket/socket_repository_http.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/login/login_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/order_list/order_list_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/blocs/pos_configuration/pos_configuration_bloc.dart';
import 'package:izi_kiosco/domain/blocs/tables/tables_bloc.dart';
import 'package:izi_kiosco/domain/models/comanda.dart';
import 'package:izi_kiosco/ui/general/main_layout/main_layout.dart';
import 'package:izi_kiosco/ui/pages/configuration_pos_page/configuration_pos_page.dart';
import 'package:izi_kiosco/ui/pages/home_page/home_page.dart';
import 'package:izi_kiosco/ui/pages/login_page/login_page.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/make_order_page.dart';
import 'package:izi_kiosco/ui/pages/order_list_page/order_list_page.dart';
import 'package:izi_kiosco/ui/pages/payment_page/payment_page.dart';
import 'package:izi_kiosco/ui/pages/tables_page/tables_page.dart';
import 'package:izi_kiosco/ui/pages/user_information_page/user_information_page.dart';
import 'routes_keys.dart';

class Routes {
  static String getOnlyLink(String path) {
    List<String> pathList = path.split("?");
    return pathList.first;
  }

  static List<RouteBase> routes(GlobalKey<NavigatorState> globalKeyNavigator) {
    return [
      ShellRoute(
          parentNavigatorKey: globalKeyNavigator,
          builder: (context, state, child) {
            context
                .read<PageUtilsBloc>()
                .changeLocation(location: state.fullPath);
            var stateAuth = context.read<AuthBloc>().state;
            if (stateAuth.status == AuthStatus.init) {
              context.read<OrderListBloc>().resetStatus();
            }
            if (stateAuth.status == AuthStatus.okAuth &&
                state.fullPath == RoutesKeys.orderLink &&
                context.read<OrderListBloc>().state.status ==
                    OrderListStatus.init) {
              context
                  .read<OrderListBloc>()
                  .getOrders(authState: stateAuth, first: true);
            }
            if (stateAuth.status == AuthStatus.okAuth &&
                state.fullPath == RoutesKeys.tablesLink &&
                context.read<TablesBloc>().state.status == TablesStatus.init) {
              context.read<TablesBloc>().init(stateAuth);
            }
            return MainLayout(
                currentLocation: state.fullPath ?? "",
                hideDrawer: state.fullPath == RoutesKeys.loginLink ||
                    state.fullPath == RoutesKeys.paymentLink,
                hideBottomNav: state.fullPath == RoutesKeys.loginLink ||
                    state.fullPath == RoutesKeys.paymentLink,
                onPop: () {
                  if (state.fullPath == RoutesKeys.paymentLink) {
                    return RoutesKeys.order;
                  }
                  if (state.fullPath == RoutesKeys.order) {
                    return RoutesKeys.home;
                  }
                  return RoutesKeys.home;
                },
                child: child);
          },
          routes: [
            GoRoute(
              name: RoutesKeys.login,
              path: RoutesKeys.loginLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return NoTransitionPage(
                  child: BlocProvider(
                    create: (context) => LoginBloc(AuthRepositoryHttp()),
                    child: const LoginPage(),
                  ),
                );
              },
            ),
            GoRoute(
              name: RoutesKeys.home,
              path: RoutesKeys.homeLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return const NoTransitionPage(child: HomePage());
              },
            ),
            GoRoute(
              name: RoutesKeys.userInformation,
              path: RoutesKeys.userInformationLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return const NoTransitionPage(child: UserInformationPage());
              },
            ),
            GoRoute(
              name: RoutesKeys.order,
              path: RoutesKeys.orderLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return NoTransitionPage(child: OrderListPage());
              },
            ),
            GoRoute(
              name: RoutesKeys.configurationPos,
              path: RoutesKeys.configurationPosLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return NoTransitionPage(
                  child: BlocProvider(
                      create: (context) => PosConfigurationBloc(
                          PosRepositoryHttp(),
                          context
                                  .read<AuthBloc>()
                                  .state
                                  .currentPos
                                  ?.isPruebas ??
                              false),
                      child: const ConfigurationPosPage()),
                );
              },
            ),
            GoRoute(
              name: RoutesKeys.tables,
              path: RoutesKeys.tablesLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return const NoTransitionPage(child: TablesPage());
              },
            ),
            GoRoute(
              name: RoutesKeys.makeOrder,
              path: RoutesKeys.makeOrderLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                String? tableId;
                int? numberDiners;
                bool fromTables = false;
                Comanda? order;
                if (state.extra is Map) {
                  tableId = (state.extra as Map)["tableId"];
                  numberDiners = (state.extra as Map)["numberDiners"];
                  fromTables = (state.extra as Map)["fromTables"] ?? false;
                  order = (state.extra as Map)["order"];
                }
                return NoTransitionPage(
                    child: BlocProvider(
                        create: (context) => MakeOrderBloc(
                            ComandaRepositoryHttp(), BusinessRepositoryHttp(),
                            numberDiners: numberDiners,
                            tableId: tableId,
                            order: order)
                          ..init(context.read<AuthBloc>().state),
                        child: MakeOrderPage(
                          fromTables: fromTables,
                        )));
              },
            ),
          ]),
      GoRoute(
        name: RoutesKeys.payment,
        path: RoutesKeys.paymentLink,
        parentNavigatorKey: globalKeyNavigator,
        pageBuilder: (BuildContext context, GoRouterState state) {
          Comanda? order;
          int? orderId = int.tryParse(state.pathParameters["id"] ?? "");
          if (state.extra is Comanda) {
            order = state.extra as Comanda;
          }
          return NoTransitionPage(
              key: const ValueKey('payment_order'),
              child: BlocProvider(
                create: (context) => PaymentBloc(ComandaRepositoryHttp(),
                    BusinessRepositoryHttp(), SocketRepositoryHttp())
                  ..initOrder(
                      order: order,
                      orderId: orderId,
                      authState: context.read<AuthBloc>().state),
                child: Scaffold(
                    body: MainLayout(
                        currentLocation: state.fullPath ?? "",
                        hideDrawer: true,
                        hideBottomNav: true,
                        onPop: () {
                          return RoutesKeys.order;
                        },
                        child: PaymentPage())),
              ));
        },
      )
    ];
  }
}
