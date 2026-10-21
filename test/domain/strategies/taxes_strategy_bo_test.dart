import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/strategies/taxes/impl/taxes_strategy_bo.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy_factory.dart';

void main() {
  group('TaxesStrategyBo.verifyParameters', () {
    final strategy = TaxesStrategyBo();
    final dummyDevice = Device.fromJson({
      "id": 1,
      "sucursal": 1,
      "nombre": "kiosco-retail",
      "caja": 1,
      "config": {"isRetail": true, "almacen": "alm-1"}
    });

    test('con facturación y sin actividad económica da errorActivity', () {
      final contribuyente = Contribuyente.fromJson({
        "modulos": {
          "facturacion": {"enabled": true}
        }
      });
      final status = strategy.verifyParameters(
          contribuyente, null, dummyDevice, null);

      expect(status, PaymentStatus.errorActivity);
    });

    test('sin facturación y sin actividad económica pasa la validación', () {
      final contribuyente = Contribuyente.fromJson({
        "modulos": {
          "facturacion": {"enabled": false}
        }
      });
      final status = strategy.verifyParameters(
          contribuyente, null, dummyDevice, null);

      expect(status, isNull);
    });

    test('con facturación y con actividad económica pasa la validación', () {
      final contribuyente = Contribuyente.fromJson({
        "modulos": {
          "facturacion": {"enabled": true}
        }
      });
      final status = strategy.verifyParameters(
          contribuyente, null, dummyDevice, '620000');

      expect(status, isNull);
    });
  });

  group('TaxesStrategyFactory para Bolivia', () {
    test('contribuyente en Bolivia sin facturación usa TaxesStrategyBo', () {
      final contribuyente = Contribuyente.fromJson({
        "habilitadoFacturacion": false,
        "config": {"paisId": "BO"}
      });

      final strategy = TaxesStrategyFactory.taxes(contribuyente);
      expect(strategy, isA<TaxesStrategyBo>());
      expect(strategy.countryCode, 'BO');
    });

    test('contribuyente en Bolivia con facturación usa TaxesStrategyBo', () {
      final contribuyente = Contribuyente.fromJson({
        "habilitadoFacturacion": true,
        "config": {"paisId": "BO"}
      });

      final strategy = TaxesStrategyFactory.taxes(contribuyente);
      expect(strategy, isA<TaxesStrategyBo>());
      expect(strategy.countryCode, 'BO');
    });
  });
}
