import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/strategies/taxes/impl/taxes_strategy_co.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy_factory.dart';

// BKB-008: la línea tiene que dar lo mismo que el backbone, o el total del kiosco no cuadra con la factura.

ParametrosFacturacionItem _conIva(num rate) => ParametrosFacturacionItem.fromJson({
      "CO": {
        "impuestosIn": false,
        "impuestos": [
          {"id": "01", "codigo": "01", "nombre": "IVA", "rate": rate, "isAmount": false}
        ]
      }
    });

void main() {
  group('TaxesStrategyCo.getTotalItem', () {
    test('en pesos el 5 sube: 1050 con IVA 19% da 1250', () {
      expect(TaxesStrategyCo().getTotalItem(_conIva(19), 1, 1050), 1250);
    });

    test('en pesos 1024 + 194,56 de IVA da 1219', () {
      expect(TaxesStrategyCo().getTotalItem(_conIva(19), 1, 1024), 1219);
    });

    test('en USD la línea lleva 2 decimales: 10,60 con IVA 19% da 12,61', () {
      expect(TaxesStrategyCo(decimalesMoneda: 2).getTotalItem(_conIva(19), 1, 10.60), 12.61);
    });

    test('en USD una línea sin IVA de 10,50 queda en 10,50', () {
      expect(TaxesStrategyCo(decimalesMoneda: 2).getTotalItem(_conIva(0), 1, 10.50), 10.50);
    });
  });

  test('la fábrica da 2 decimales solo si la moneda de la factura no es la de impuesto', () {
    int decimalesDe(Map<String, dynamic> config) =>
        (TaxesStrategyFactory.taxes(Contribuyente.fromJson({"config": {"paisId": "CO", ...config}})) as TaxesStrategyCo)
            .decimalesMoneda;

    expect(decimalesDe({"monedaInventario": 151, "monedaImpuesto": 31}), 2);
    expect(decimalesDe({"monedaInventario": 31, "monedaImpuesto": 31}), 0);
    expect(decimalesDe({}), 0);
  });
}
