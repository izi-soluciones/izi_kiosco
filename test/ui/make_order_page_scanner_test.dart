import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/models/category_order.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/repositories/auth_repository.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';
import 'package:izi_kiosco/ui/pages/make_order_page/make_order_page.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {}

class _FakeBusinessRepository extends Fake implements BusinessRepository {}

class _FakeComandaRepository extends Fake implements ComandaRepository {}

class _TestMakeOrderBloc extends MakeOrderBloc {
  _TestMakeOrderBloc()
      : super(_FakeComandaRepository(), _FakeBusinessRepository());

  void seed(MakeOrderState state) => emit(state);
}

Future<void> _scan(WidgetTester tester, String code) async {
  for (final char in code.split('')) {
    await tester.sendKeyEvent(LogicalKeyboardKey(char.codeUnitAt(0)));
  }
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();
}

int _selectedCount(MakeOrderBloc bloc) =>
    bloc.state.itemsSelected.fold(0, (sum, cat) => sum + cat.items.length);

void main() {
  for (final size in const [Size(1080, 1920), Size(1920, 1080)]) {
    testWidgets(
        'el lector sigue escaneando tras "Empezar de nuevo" (${size.width.toInt()}x${size.height.toInt()})',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Sin traducciones cargadas los botones muestran la clave en mayúsculas y
      // desbordan: ruido de layout ajeno al foco del lector.
      final onError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.exceptionAsString().contains('overflowed')) {
          onError?.call(details);
        }
      };

      final item = Item.fromJson({
        "id": "i1",
        "nombre": "Galleta",
        "codigoBarras": "123",
        "precioUnitario": 10,
        "activo": true,
        "categoria": {"id": "c1", "nombre": "Snacks"},
      });
      final bloc = _TestMakeOrderBloc();
      addTearDown(bloc.close);
      bloc.seed(bloc.state.copyWith(
          step: 1,
          categories: [CategoryOrder(nombre: "Snacks", id: "c1", items: [item])]));

      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (_) =>
                  AuthBloc(_FakeAuthRepository(), _FakeBusinessRepository())),
          BlocProvider(create: (_) => PageUtilsBloc(_FakeBusinessRepository())),
          BlocProvider<MakeOrderBloc>.value(value: bloc),
        ],
        child: const MaterialApp(
            home: Scaffold(
                body: MakeOrderPage(fromTables: false, isRetail: true))),
      ));
      await tester.pump();

      await _scan(tester, "123");
      expect(_selectedCount(bloc), 1);

      await tester.tap(find.byWidgetPredicate((w) =>
          w is IziBtn &&
          w.buttonText == LocaleKeys.makeOrder_buttons_initAgain.tr()));
      await tester.pump();
      expect(_selectedCount(bloc), 0);

      await _scan(tester, "123");
      expect(_selectedCount(bloc), 1);

      FlutterError.onError = onError;
    });
  }
}
