import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/theme.dart';
import 'package:izi_kiosco/app/utils/app_behavior.dart';
import 'package:izi_kiosco/app/utils/go_router_refresh_stream.dart';
import 'package:izi_kiosco/app/values/routes.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/data/repositories/auth/auth_repository_http.dart';
import 'package:izi_kiosco/data/repositories/business/business_repository_http.dart';
import 'package:izi_kiosco/data/repositories/comanda/comanda_repository_http.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/pages/splash_page/splash_page.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class MyApp extends StatelessWidget {
  late final route = GoRouter(
    routes: Routes.routes(),
    initialLocation: RoutesKeys.homeLink,
    refreshListenable: GoRouterRefreshStream(_auth.stream, _auth.state),
    redirect: (context, GoRouterState state) {
      final location = state.fullPath;
      if (_auth.state.status == AuthStatus.okAuth &&
          _auth.state.currentSucursal != null &&
          _auth.state.currentDevice != null &&
          (location == RoutesKeys.loginLink ||
              location == RoutesKeys.configBusinessLink ||
          location == RoutesKeys.kioskListLink)) {
        return RoutesKeys.homeLink;
      }

      if (_auth.state.status == AuthStatus.firstContribuyente &&
          (location == RoutesKeys.loginLink)) {
        return RoutesKeys.configBusinessLink;
      }
      if (_auth.state.status == AuthStatus.noAuth &&
          location != RoutesKeys.loginLink) {
        return RoutesKeys.loginLink;
      }
      if (_auth.state.status == AuthStatus.okAuth &&
          (_auth.state.currentSucursal == null ||
              _auth.state.currentDevice == null) &&
          location != RoutesKeys.configBusinessLink &&
          location != RoutesKeys.kioskListLink &&
          location != RoutesKeys.kioskNewLink) {
        return RoutesKeys.configBusinessLink;
      }
      return null;
    },
  );

  final AuthBloc _auth =
      AuthBloc(AuthRepositoryHttp(), BusinessRepositoryHttp());

  MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => _auth..verify(),
        ),
        BlocProvider(
          create: (context) => PageUtilsBloc(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        scrollBehavior: AppBehavior().copyWith(
            dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
            overscroll: false),
        debugShowCheckedModeBanner: false,
        debugShowMaterialGrid: false,
        routerConfig: route,
        title: "iZi Kiosco",
        theme: iziThemeData(),
        builder: (context, child) {
          final ru = ResponsiveUtils(context);
          return BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (previous, current) {
              return previous.status != current.status;
            },
            builder: (context, state) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                    child: state.status == AuthStatus.init ||
                            state.status == AuthStatus.waitingChange
                        ? SplashPage()
                        : MultiBlocProvider(providers: [
                            BlocProvider(
                                create: (context) => MakeOrderBloc(
                                    ComandaRepositoryHttp(),
                                    BusinessRepositoryHttp())),
                          ], child: BlocBuilder<PageUtilsBloc, PageUtilsState>(
                        buildWhen: (previous, current) {
                          return previous.snackBarState !=
                              current.snackBarState;
                        }, builder: (context, state) {
                      return Stack(
                        children: [
                          child ?? const Scaffold(),
                          Positioned.fill(
                            child: Column(
                              children: [
                                if(ru.gtXs())
                                  Material(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    child: AnimatedSwitcher(
                                      duration:
                                      const Duration(milliseconds: 200),
                                      reverseDuration:
                                      const Duration(milliseconds: 200),
                                      transitionBuilder:
                                          (child, animation) =>
                                          SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, -1),
                                              end: const Offset(0, 0),
                                            ).animate(animation),
                                            child: child,
                                          ),
                                      child: state.snackBarState?IziSnackBar(
                                        snackBarPosition:
                                        SnackBarPosition.bottom,
                                        snackBarInfo: state.snackBar,
                                        onClickClose: () {
                                          context
                                              .read<PageUtilsBloc>()
                                              .hideSnackBar();
                                        },
                                        active: state.snackBarState,
                                      ):const SizedBox.shrink(),
                                    ),
                                  ),
                                Expanded(child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  reverseDuration: const Duration(milliseconds:200),
                                  transitionBuilder: (child,animation)=>SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 1),
                                      end: const Offset(0, 0),
                                    ).animate(animation),
                                    child: child,
                                  ),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: (){
                                      context.read<PageUtilsBloc>().hideSnackBar();
                                    },
                                    child: state.snackBarState?
                                    Container()
                                        :const SizedBox.shrink(),
                                  ),
                                )),

                                if(ru.isXs())
                                  Material(
                                    color: Colors.transparent,
                                    elevation: 0,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      height: state.snackBarState?50:0,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        reverseDuration: const Duration(milliseconds:200),
                                        transitionBuilder: (child,animation)=>SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 1),
                                            end: const Offset(0, 0),
                                          ).animate(animation),
                                          child: child,
                                        ),
                                        child: state.snackBarState?
                                        IziSnackBar(
                                          snackBarPosition: SnackBarPosition.bottom,
                                          snackBarInfo: state.snackBar,
                                          active:state.snackBarState,
                                          onClickClose: (){
                                            context.read<PageUtilsBloc>().hideSnackBar();
                                          },
                                        )
                                            :const SizedBox.shrink(),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ],
                      );

                    }))),
              );
            },
          );
        },
      ),
    );
  }
}
