import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/make_order/make_order_bloc.dart';
import 'package:izi_kiosco/domain/blocs/make_order_retail/make_order_retail_bloc.dart';
import 'package:izi_kiosco/domain/models/campos_extra.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/dto/new_sale_link_dto.dart';
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

  group('NewSaleLinkDto CamposExtra Tests', () {
    test('toJson should include non-empty camposExtra', () {
      final campoConValor = CamposExtra(
        id: 10,
        contribuyente: 28,
        nombre: 'Teléfono',
        tipoCampo: 'text',
        visibleFactura: true,
        visibleReporte: true,
        valor: '70012345',
        isObligatorio: true,
        creado: DateTime.now(),
        tipoModulo: 'dispositivos',
      );
      final campoVacio = CamposExtra(
        id: 11,
        contribuyente: 28,
        nombre: 'Notas',
        tipoCampo: 'text',
        visibleFactura: false,
        visibleReporte: false,
        valor: '',
        isObligatorio: false,
        creado: DateTime.now(),
        tipoModulo: 'dispositivos',
      );

      final dto = NewSaleLinkDto(
        dispositivo: 84,
        listaItems: [
          Item.fromJson({'id': '69c407c122b879079df2b001', 'nombre': 'Test', 'cantidad': 2}),
        ],
        camposExtra: [campoConValor, campoVacio],
      );

      final json = dto.toJson();
      expect(json['camposExtra'], isNotNull);
      expect((json['camposExtra'] as List).length, 1);
      expect(json['camposExtra'][0]['nombre'], 'Teléfono');
      expect(json['camposExtra'][0]['valor'], '70012345');
    });

    test('toJson should not include camposExtra if null or empty', () {
      final dto = NewSaleLinkDto(
        dispositivo: 84,
        listaItems: [
          Item.fromJson({'id': '69c407c122b879079df2b001', 'nombre': 'Test', 'cantidad': 1}),
        ],
      );

      final json = dto.toJson();
      expect(json.containsKey('camposExtra'), isFalse);
    });
  });

  group('MakeOrderRetailBloc CamposExtra Tests', () {
    late MakeOrderRetailBloc retailBloc;

    setUp(() {
      retailBloc = MakeOrderRetailBloc(_FakeComandaRepository(), _FakeBusinessRepository());
    });

    tearDown(() {
      retailBloc.close();
    });

    test('retailBloc validateCamposExtra should fail if required field is empty', () {
      final campo = CamposExtra(
        id: 101,
        contribuyente: 28,
        nombre: 'Canal de ventas',
        tipoCampo: 'select',
        visibleFactura: true,
        visibleReporte: true,
        isObligatorio: true,
        creado: DateTime.now(),
        tipoModulo: 'venta',
        values: ['Presencial', 'Online'],
        valor: null,
      );

      retailBloc.emit(retailBloc.state.copyWith(camposExtra: [campo]));

      expect(retailBloc.hasMissingRequiredCamposExtra(), true);
      expect(retailBloc.validateCamposExtra(), 'El campo "Canal de ventas" es obligatorio');

      retailBloc.updateCampoExtra(101, 'Presencial');
      expect(retailBloc.hasMissingRequiredCamposExtra(), false);
      expect(retailBloc.validateCamposExtra(), null);
    });

    test('retailBloc validateCamposExtra validates number format', () {
      final campo = CamposExtra(
        id: 102,
        contribuyente: 28,
        nombre: 'Teléfono',
        tipoCampo: 'number',
        visibleFactura: true,
        visibleReporte: true,
        isObligatorio: false,
        creado: DateTime.now(),
        tipoModulo: 'venta',
        valor: 'no_es_numero',
      );

      retailBloc.emit(retailBloc.state.copyWith(camposExtra: [campo]));

      expect(retailBloc.validateCamposExtra(), 'El campo "Teléfono" debe ser un número válido');

      retailBloc.updateCampoExtra(102, '70012345');
      expect(retailBloc.validateCamposExtra(), null);
    });
  });

  group('CamposExtra Module Segregation Tests (Retail vs Restaurant)', () {
    final campos = [
      CamposExtra(
        id: 1,
        contribuyente: 28,
        nombre: 'Número de mesa',
        tipoCampo: 'text',
        visibleFactura: false,
        visibleReporte: false,
        isObligatorio: true,
        creado: DateTime.now(),
        tipoModulo: 'comanda',
      ),
      CamposExtra(
        id: 2,
        contribuyente: 28,
        nombre: 'Turno de venta',
        tipoCampo: 'select',
        visibleFactura: true,
        visibleReporte: true,
        isObligatorio: false,
        creado: DateTime.now(),
        tipoModulo: 'venta',
      ),
      CamposExtra(
        id: 3,
        contribuyente: 28,
        nombre: 'Dirección de entrega',
        tipoCampo: 'text',
        visibleFactura: true,
        visibleReporte: true,
        isObligatorio: false,
        creado: DateTime.now(),
        tipoModulo: 'dispositivos',
      ),
    ];

    List<CamposExtra> filterForDevice(List<CamposExtra> list, bool isRetail) {
      return list.where((c) {
        if (isRetail) {
          final nombre = c.nombre.trim().toLowerCase();
          if (nombre.contains('mesa') || nombre.contains('table')) {
            return false;
          }
          return c.tipoModulo == 'dispositivos' ||
              c.tipoModulo == 'venta' ||
              c.tipoModulo == null ||
              c.tipoModulo == '';
        } else {
          return c.tipoModulo == 'dispositivos' ||
              c.tipoModulo == 'comanda' ||
              c.tipoModulo == null ||
              c.tipoModulo == '';
        }
      }).toList();
    }

    test('Retail kiosk includes dispositivos and venta, excludes mesa / comanda', () {
      final result = filterForDevice(campos, true);
      final names = result.map((c) => c.nombre).toList();

      expect(names.contains('Turno de venta'), true);
      expect(names.contains('Dirección de entrega'), true);
      expect(names.contains('Número de mesa'), false);
    });

    test('Restaurant kiosk includes dispositivos and comanda, excludes venta', () {
      final result = filterForDevice(campos, false);
      final names = result.map((c) => c.nombre).toList();

      expect(names.contains('Número de mesa'), true);
      expect(names.contains('Dirección de entrega'), true);
      expect(names.contains('Turno de venta'), false);
    });
  });
}
