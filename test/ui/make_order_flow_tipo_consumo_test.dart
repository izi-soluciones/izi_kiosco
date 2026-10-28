import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/theme.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/category_order.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/repositories/auth_repository.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/make_order_page.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/views/make_order_type.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {}

class _FakeBusinessRepository extends Fake implements BusinessRepository {}

class _FakeComandaRepository extends Fake implements ComandaRepository {}

class _TestMakeOrderBloc extends MakeOrderBloc {
  _TestMakeOrderBloc()
      : super(_FakeComandaRepository(), _FakeBusinessRepository());

  void seed(MakeOrderState state) => emit(state);
}

Device _deviceWithTipoConsumo(String tipoConsumo) {
  return Device(
    id: 1,
    sucursal: 1,
    nombre: 'Kiosco',
    caja: 1,
    config: ConfigDevice.fromJson({'tipoConsumo': tipoConsumo, 'isRetail': false}),
    enUso: false,
    catalogo: null,
    activo: true,
  );
}

Finder findKioskOption(String key) {
  return find.byWidgetPredicate((w) =>
      w is Text && (w.data?.replaceAll('\u200B', '') == key.tr()));
}

void main() {
  group('MakeOrderPage skipOrderType', () {
    testWidgets('con skipOrderType: true inicia directamente en la página 1', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final onError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.exceptionAsString().contains('overflowed')) {
          onError?.call(details);
        }
      };

      final bloc = _TestMakeOrderBloc();
      addTearDown(bloc.close);
      final item = Item.fromJson({
        "id": "i1",
        "nombre": "Pizza",
        "precioUnitario": 20,
        "activo": true,
        "categoria": {"id": "c1", "nombre": "Comidas"},
      });
      bloc.seed(bloc.state.copyWith(
        step: 1,
        categories: [CategoryOrder(nombre: "Comidas", id: "c1", items: [item])],
      ));

      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (_) =>
                  AuthBloc(_FakeAuthRepository(), _FakeBusinessRepository())),
          BlocProvider(create: (_) => PageUtilsBloc(_FakeBusinessRepository())),
          BlocProvider<MakeOrderBloc>.value(value: bloc),
        ],
        child: MaterialApp(
          theme: iziThemeData(),
          home: const Scaffold(
            body: MakeOrderPage(
              fromTables: false,
              isRetail: false,
              skipOrderType: true,
            ),
          ),
        ),
      ));
      await tester.pump();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.initialPage, 1);
      FlutterError.onError = onError;
    });

    testWidgets('con skipOrderType: false e isRetail: false inicia en la página 0', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final onError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.exceptionAsString().contains('overflowed')) {
          onError?.call(details);
        }
      };

      final bloc = _TestMakeOrderBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (_) =>
                  AuthBloc(_FakeAuthRepository(), _FakeBusinessRepository())),
          BlocProvider(create: (_) => PageUtilsBloc(_FakeBusinessRepository())),
          BlocProvider<MakeOrderBloc>.value(value: bloc),
        ],
        child: MaterialApp(
          theme: iziThemeData(),
          home: const Scaffold(
            body: MakeOrderPage(
              fromTables: false,
              isRetail: false,
              skipOrderType: false,
            ),
          ),
        ),
      ));
      await tester.pump();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.initialPage, 0);
      FlutterError.onError = onError;
    });
  });

  group('MakeOrderType opciones activas', () {
    testWidgets('si está configurado solo_llevar no muestra la opción comer aquí y muestra llevar', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final onError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.exceptionAsString().contains('overflowed')) {
          onError?.call(details);
        }
      };

      final authBloc = AuthBloc(_FakeAuthRepository(), _FakeBusinessRepository());
      addTearDown(authBloc.close);
      authBloc.emit(authBloc.state.copyWith(
        currentDevice: _deviceWithTipoConsumo('solo_llevar'),
      ));

      final makeOrderBloc = _TestMakeOrderBloc();
      addTearDown(makeOrderBloc.close);

      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<MakeOrderBloc>.value(value: makeOrderBloc),
          BlocProvider(create: (_) => PageUtilsBloc(_FakeBusinessRepository())),
        ],
        child: MaterialApp(
          theme: iziThemeData(),
          home: Scaffold(
            body: MakeOrderType(state: makeOrderBloc.state),
          ),
        ),
      ));
      await tester.pump();

      expect(findKioskOption(LocaleKeys.makeOrder_body_eatHere), findsNothing);
      expect(find.byIcon(IziIcons.hereOrder), findsNothing);
      expect(findKioskOption(LocaleKeys.makeOrder_body_takeAway), findsOneWidget);
      expect(find.byIcon(IziIcons.takeAwayOrder), findsOneWidget);
      FlutterError.onError = onError;
    });

    testWidgets('si está configurado solo_local no muestra la opción para llevar y muestra comer aquí', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final onError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.exceptionAsString().contains('overflowed')) {
          onError?.call(details);
        }
      };

      final authBloc = AuthBloc(_FakeAuthRepository(), _FakeBusinessRepository());
      addTearDown(authBloc.close);
      authBloc.emit(authBloc.state.copyWith(
        currentDevice: _deviceWithTipoConsumo('solo_local'),
      ));

      final makeOrderBloc = _TestMakeOrderBloc();
      addTearDown(makeOrderBloc.close);

      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<MakeOrderBloc>.value(value: makeOrderBloc),
          BlocProvider(create: (_) => PageUtilsBloc(_FakeBusinessRepository())),
        ],
        child: MaterialApp(
          theme: iziThemeData(),
          home: Scaffold(
            body: MakeOrderType(state: makeOrderBloc.state),
          ),
        ),
      ));
      await tester.pump();

      expect(findKioskOption(LocaleKeys.makeOrder_body_takeAway), findsNothing);
      expect(find.byIcon(IziIcons.takeAwayOrder), findsNothing);
      expect(findKioskOption(LocaleKeys.makeOrder_body_eatHere), findsOneWidget);
      expect(find.byIcon(IziIcons.hereOrder), findsOneWidget);
      FlutterError.onError = onError;
    });

    testWidgets('si está configurado ambos muestra comer aquí y para llevar', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final onError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.exceptionAsString().contains('overflowed')) {
          onError?.call(details);
        }
      };

      final authBloc = AuthBloc(_FakeAuthRepository(), _FakeBusinessRepository());
      addTearDown(authBloc.close);
      authBloc.emit(authBloc.state.copyWith(
        currentDevice: _deviceWithTipoConsumo('ambos'),
      ));

      final makeOrderBloc = _TestMakeOrderBloc();
      addTearDown(makeOrderBloc.close);

      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<MakeOrderBloc>.value(value: makeOrderBloc),
          BlocProvider(create: (_) => PageUtilsBloc(_FakeBusinessRepository())),
        ],
        child: MaterialApp(
          theme: iziThemeData(),
          home: Scaffold(
            body: MakeOrderType(state: makeOrderBloc.state),
          ),
        ),
      ));
      await tester.pump();

      expect(findKioskOption(LocaleKeys.makeOrder_body_eatHere), findsOneWidget);
      expect(find.byIcon(IziIcons.hereOrder), findsOneWidget);
      expect(findKioskOption(LocaleKeys.makeOrder_body_takeAway), findsOneWidget);
      expect(find.byIcon(IziIcons.takeAwayOrder), findsOneWidget);
      FlutterError.onError = onError;
    });
  });
}
