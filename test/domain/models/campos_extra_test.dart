import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/campos_extra.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';

void main() {
  group('CamposExtra Model Tests', () {
    test('Should parse text field properly', () {
      final json = {
        "id": 1,
        "contribuyente": 10,
        "nombre": "Número de mesa",
        "tipoCampo": "text",
        "isObligatorio": true,
        "tipoModulo": "dispositivos",
        "valor": "Mesa 5"
      };

      final campo = CamposExtra.fromJson(json);
      expect(campo.id, 1);
      expect(campo.nombre, "Número de mesa");
      expect(campo.tipoCampo, "text");
      expect(campo.isObligatorio, true);
      expect(campo.tipoModulo, "dispositivos");
      expect(campo.valor, "Mesa 5");
    });

    test('Should parse number field properly', () {
      final json = {
        "id": 2,
        "contribuyente": 10,
        "nombre": "Mesa",
        "tipoCampo": "number",
        "isObligatorio": true,
        "tipoModulo": "dispositivos",
        "valor": "12"
      };

      final campo = CamposExtra.fromJson(json);
      expect(campo.id, 2);
      expect(campo.tipoCampo, "number");
      expect(campo.isObligatorio, true);
      expect(campo.valor, "12");
    });

    test('Should parse select field and split values', () {
      final json = {
        "id": 3,
        "contribuyente": 10,
        "nombre": "Zona",
        "tipoCampo": "select",
        "isObligatorio": false,
        "tipoModulo": "dispositivos",
        "valor": "Terraza, Interior, Balcón"
      };

      final campo = CamposExtra.fromJson(json);
      expect(campo.id, 3);
      expect(campo.tipoCampo, "select");
      expect(campo.isObligatorio, false);
      expect(campo.values, ["Terraza", "Interior", "Balcón"]);
      expect(campo.valor, null);
    });

    test('Should parse fixed content field properly', () {
      final json = {
        "id": 4,
        "contribuyente": 10,
        "nombre": "Mensaje de bienvenida",
        "tipoCampo": "fijo",
        "isObligatorio": false,
        "tipoModulo": "dispositivos",
        "valor": "Bienvenidos a iZi"
      };

      final campo = CamposExtra.fromJson(json);
      expect(campo.id, 4);
      expect(campo.tipoCampo, "fijo");
      expect(campo.valor, "Bienvenidos a iZi");
    });

    test('Should parse in Contribuyente.fromJson', () {
      final contribJson = {
        "id": 100,
        "nombre": "Restaurante Demo",
        "camposExtra": [
          {
            "id": 10,
            "nombre": "Número de mesa",
            "tipoCampo": "text",
            "isObligatorio": true,
            "tipoModulo": "dispositivos"
          },
          {
            "id": 11,
            "nombre": "Observaciones factura",
            "tipoCampo": "text",
            "isObligatorio": false,
            "tipoModulo": "comanda"
          }
        ]
      };

      final contrib = Contribuyente.fromJson(contribJson);
      expect(contrib.camposExtra?.length, 2);
      expect(contrib.camposExtra?.first.nombre, "Número de mesa");
      expect(contrib.camposExtra?.first.tipoModulo, "dispositivos");
    });

    test('copyWith should allow setting a new value and clearing to null', () {
      final campo = CamposExtra(
        id: 5,
        contribuyente: 1,
        nombre: "Mesa",
        tipoCampo: "text",
        visibleFactura: false,
        visibleReporte: false,
        isObligatorio: false,
        creado: DateTime.now(),
        tipoModulo: "dispositivos",
        valor: "Mesa 1",
      );

      final sameVal = campo.copyWith();
      expect(sameVal.valor, "Mesa 1");

      final changedVal = campo.copyWith(valor: () => "Mesa 2");
      expect(changedVal.valor, "Mesa 2");

      final clearedVal = campo.copyWith(valor: () => null);
      expect(clearedVal.valor, null);
    });
  });
}
