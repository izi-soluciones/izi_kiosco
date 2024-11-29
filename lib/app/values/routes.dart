import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_kiosco/data/repositories/auth/auth_repository_http.dart';
import 'package:izi_kiosco/data/repositories/business/business_repository_http.dart';
import 'package:izi_kiosco/data/repositories/comanda/comanda_repository_http.dart';
import 'package:izi_kiosco/data/repositories/socket/socket_repository_http.dart';
import 'package:izi_kiosco/domain/blocs/add_kiosk/add_kiosk_bloc.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/login/login_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order_retail/make_order_retail_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/payment_obj.dart';
import 'package:izi_kiosco/ui/general/main_layout/main_layout.dart';
import 'package:izi_kiosco/ui/pages/add_kiosk_page/add_kiosk_page.dart';
import 'package:izi_kiosco/ui/pages/error_payment_page/error_payment_page.dart';
import 'package:izi_kiosco/ui/pages/home_page/home_page.dart';
import 'package:izi_kiosco/ui/pages/kiosk_list_page/kiosk_list_page.dart';
import 'package:izi_kiosco/ui/pages/login_page/login_page.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/make_order_page.dart';
import 'package:izi_kiosco/ui/pages/make_order_retail_page/make_order_retail_page.dart';
import 'package:izi_kiosco/ui/pages/payment_page/payment_page.dart';
import 'package:izi_kiosco/ui/pages/select_business_page/select_business_page.dart';
import 'routes_keys.dart';

class Routes {
  static String getOnlyLink(String path) {
    List<String> pathList = path.split("?");
    return pathList.first;
  }

  static List<RouteBase> routes() {
    return [
      GoRoute(
        name: RoutesKeys.login,
        path: RoutesKeys.loginLink,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage(
            child: BlocProvider(
              create: (context) => LoginBloc(AuthRepositoryHttp()),
              child: MainLayout(
                  currentLocation: state.fullPath ?? "",
                  hideDrawer: true,
                  hideBottomNav: true,
                  onPop: null,
                  child: const LoginPage()),
            ),
          );
        },
      ),
      GoRoute(
        name: RoutesKeys.kioskList,
        path: RoutesKeys.kioskListLink,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage(
            child: MainLayout(
                currentLocation: state.fullPath ?? "",
                hideDrawer: true,
                hideBottomNav: true,
                onPop: null,
                child: const KioskListPage()),
          );
        },
      ),
      GoRoute(
        name: RoutesKeys.kioskNew,
        path: RoutesKeys.kioskNewLink,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage(
            child: MainLayout(
                currentLocation: state.fullPath ?? "",
                hideDrawer: true,
                hideBottomNav: true,
                onPop: null,
                child: BlocProvider(
                    create: (context) => AddKioskBloc(
                        AuthRepositoryHttp(), BusinessRepositoryHttp()),
                    child: const AddKioskPage())),
          );
        },
      ),
      GoRoute(
        name: RoutesKeys.configBusiness,
        path: RoutesKeys.configBusinessLink,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return NoTransitionPage(
            child: MainLayout(
                currentLocation: state.fullPath ?? "",
                hideDrawer: true,
                hideBottomNav: true,
                onPop: null,
                child: const SelectBusinessPage()),
          );
        },
      ),
      ShellRoute(
          builder: (context, state, child) {
            return MainLayout(
              currentLocation: state.fullPath ?? "",
              hideDrawer: true,
              hideBottomNav: true,
              onPop: () {
                return RoutesKeys.home;
              },
              child: child,
            );
          },
          routes: [
            GoRoute(
              name: RoutesKeys.home,
              path: RoutesKeys.homeLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return const NoTransitionPage(
                    child: HomePage());
              },
            ),
            GoRoute(
              name: RoutesKeys.errorPayments,
              path: RoutesKeys.errorPaymentsLik,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return const NoTransitionPage(
                    child: ErrorPaymentPage());
              },
            ),
            GoRoute(
              name: RoutesKeys.makeOrderRetail,
              path: RoutesKeys.makeOrderRetailLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                return NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => MakeOrderRetailBloc(
                          ComandaRepositoryHttp(), BusinessRepositoryHttp())
                        ..init(context.read<AuthBloc>().state),
                      child: const MakeOrderRetailPage(),
                    ));
              },
            ),
            GoRoute(
              name: RoutesKeys.makeOrder,
              path: RoutesKeys.makeOrderLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                String? tableId;
                int? numberDiners;
                bool fromTables = false;
                if (state.extra is Map) {
                  tableId = (state.extra as Map)["tableId"];
                  numberDiners = (state.extra as Map)["numberDiners"];
                  fromTables = (state.extra as Map)["fromTables"] ?? false;
                }
                return NoTransitionPage(
                    child: BlocProvider(
                  create: (context) => MakeOrderBloc(
                      ComandaRepositoryHttp(), BusinessRepositoryHttp(),
                      numberDiners: numberDiners,
                      tableId: tableId,)
                    ..init(context.read<AuthBloc>().state),
                  child: MakeOrderPage(fromTables: fromTables),
                ));
              },
            ),
            GoRoute(
              name: RoutesKeys.payment,
              path: RoutesKeys.paymentLink,
              pageBuilder: (BuildContext context, GoRouterState state) {
                if (state.extra is PaymentObj) {
                  PaymentObj paymentObj = state.extra as PaymentObj;
                  return NoTransitionPage(
                    child: BlocProvider(
                      create: (context) => PaymentBloc(ComandaRepositoryHttp(),
                          BusinessRepositoryHttp(), SocketRepositoryHttp())
                        ..initOrder(
                            paymentObj: paymentObj,
                            authState: context.read<AuthBloc>().state),
                      child: Scaffold(
                          body: PaymentPage()),
                    ),
                  );
                }
                return const NoTransitionPage(
                  child: Scaffold()
                );
              },
            )
          ]),
    ];
  }
}
