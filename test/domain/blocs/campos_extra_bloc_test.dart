import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/models/campos_extra.dart';
import 'package:izi_kiosco/domain/repositories/business_repository.dart';
import 'package:izi_kiosco/domain/repositories/comanda_repository.dart';

class _FakeComandaRepository implements ComandaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeBusinessRepository implements BusinessRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('MakeOrderBloc CamposExtra Validation Tests', () {
    late MakeOrderBloc bloc;

    setUp(() {
      bloc = MakeOrderBloc(_FakeComandaRepository(), _FakeBusinessRepository());
    });

    tearDown(() {
      bloc.close();
    });

    test('validateCamposExtra should fail if required text field is empty', () {
      final campo = CamposExtra(
        id: 1,
        contribuyente: 1,
        nombre: "Número de mesa",
        tipoCampo: "text",
        visibleFactura: false,
        visibleReporte: false,
        isObligatorio: true,
        creado: DateTime.now(),
        tipoModulo: "dispositivos",
        valor: "",
      );

      bloc.emit(bloc.state.copyWith(camposExtra: [campo]));

      expect(bloc.hasMissingRequiredCamposExtra(), true);
      expect(bloc.validateCamposExtra(), 'El campo "Número de mesa" es obligatorio');
    });

    test('validateCamposExtra should succeed when required field is filled', () {
      final campo = CamposExtra(
        id: 1,
        contribuyente: 1,
        nombre: "Número de mesa",
        tipoCampo: "text",
        visibleFactura: false,
        visibleReporte: false,
        isObligatorio: true,
        creado: DateTime.now(),
        tipoModulo: "dispositivos",
        valor: "Mesa 4",
      );

      bloc.emit(bloc.state.copyWith(camposExtra: [campo]));

      expect(bloc.hasMissingRequiredCamposExtra(), false);
      expect(bloc.validateCamposExtra(), null);
    });

    test('validateCamposExtra should validate number format for number field', () {
      final campo = CamposExtra(
        id: 2,
        contribuyente: 1,
        nombre: "Número de mesa",
        tipoCampo: "number",
        visibleFactura: false,
        visibleReporte: false,
        isObligatorio: false,
        creado: DateTime.now(),
        tipoModulo: "dispositivos",
        valor: "abc",
      );

      bloc.emit(bloc.state.copyWith(camposExtra: [campo]));

      expect(bloc.validateCamposExtra(), 'El campo "Número de mesa" debe ser un número válido');

      bloc.updateCampoExtra(2, "42");
      expect(bloc.validateCamposExtra(), null);
    });

    test('validateCamposExtra should validate select options', () {
      final campo = CamposExtra(
        id: 3,
        contribuyente: 1,
        nombre: "Ubicación",
        tipoCampo: "select",
        visibleFactura: false,
        visibleReporte: false,
        isObligatorio: false,
        creado: DateTime.now(),
        tipoModulo: "dispositivos",
        values: ["Terraza", "Salón"],
        valor: "Piscina",
      );

      bloc.emit(bloc.state.copyWith(camposExtra: [campo]));

      expect(bloc.validateCamposExtra(), 'Seleccione una opción válida para "Ubicación"');

      bloc.updateCampoExtra(3, "Terraza");
      expect(bloc.validateCamposExtra(), null);
    });

    test('Optional fields empty do not block validation', () {
      final campo = CamposExtra(
        id: 4,
        contribuyente: 1,
        nombre: "Comentarios",
        tipoCampo: "text",
        visibleFactura: false,
        visibleReporte: false,
        isObligatorio: false,
        creado: DateTime.now(),
        tipoModulo: "dispositivos",
        valor: null,
      );

      bloc.emit(bloc.state.copyWith(camposExtra: [campo]));

      expect(bloc.hasMissingRequiredCamposExtra(), false);
      expect(bloc.validateCamposExtra(), null);
    });

    test('updateCampoExtra with null should clear value', () {
      final campo = CamposExtra(
        id: 1,
        contribuyente: 1,
        nombre: "Zona",
        tipoCampo: "select",
        visibleFactura: false,
        visibleReporte: false,
        isObligatorio: false,
        creado: DateTime.now(),
        tipoModulo: "dispositivos",
        values: ["Terraza", "Salón"],
        valor: "Terraza",
      );

      bloc.emit(bloc.state.copyWith(camposExtra: [campo]));
      expect(bloc.state.camposExtra.first.valor, "Terraza");

      bloc.updateCampoExtra(1, null);
      expect(bloc.state.camposExtra.first.valor, null);
    });

    test('validateCamposExtra and hasMissingRequiredCamposExtra should return null and false when camposExtra is empty', () {
      bloc.emit(bloc.state.copyWith(camposExtra: []));

      expect(bloc.hasMissingRequiredCamposExtra(), false);
      expect(bloc.validateCamposExtra(), null);
    });
  });
}
