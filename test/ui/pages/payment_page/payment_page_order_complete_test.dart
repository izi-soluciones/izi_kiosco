import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_kiosco/app/utils/attract_video.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_order_complete.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Bug 86dw9yytb: "Realizar otra compra" tiene que avisarle al Home que viene de un
// pedido completado, para que vaya directo al video sin la espera del primer arranque.

class _TraduccionesDesdeDisco extends AssetLoader {
  const _TraduccionesDesdeDisco();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('assets/translations/es.json').readAsStringSync());
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('"Realizar otra compra" vuelve al Home marcado como pedido completado',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Object? extraRecibido = 'sin navegar';
    final router = GoRouter(initialLocation: '/payment', routes: [
      GoRoute(
          path: '/payment',
          builder: (context, state) => Scaffold(
              body: PaymentPageOrderComplete(state: PaymentState.init()))),
      GoRoute(
          path: RoutesKeys.homeLink,
          name: RoutesKeys.home,
          builder: (context, state) {
            extraRecibido = state.extra;
            return const Scaffold(body: Text('pantalla-inicio'));
          }),
    ]);

    await tester.pumpWidget(EasyLocalization(
      supportedLocales: const [Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'),
      assetLoader: const _TraduccionesDesdeDisco(),
      child: Builder(
          builder: (context) => MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining(RegExp('realizar otra compra', caseSensitive: false)));
    await tester.pumpAndSettle();

    expect(find.text('pantalla-inicio'), findsOneWidget);
    expect(AttractVideo.isFromCompletedOrder(extraRecibido), isTrue);
  });
}
