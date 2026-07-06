import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/item.dart';
import 'package:izi_kiosco/domain/strategies/taxes/impl/taxes_strategy_bo.dart';
import 'package:izi_kiosco/domain/strategies/taxes/impl/taxes_strategy_co.dart';
import 'package:izi_kiosco/domain/strategies/taxes/impl/taxes_strategy_default.dart';
import 'package:izi_kiosco/domain/strategies/taxes/taxes_strategy_factory.dart';

Contribuyente _contribuyente({
  bool? usaSiat,
  bool? habilitadoFacturacion,
  dynamic config,
}) =>
    Contribuyente(
      usaSiat: usaSiat,
      habilitadoFacturacion: habilitadoFacturacion,
      config: config,
      actividadesEconomicas: null,
      autorizadosAPI: null,
    );

ParametrosFacturacionItem _params({
  required List<Map> impuestos,
  bool impuestosIn = false,
}) =>
    ParametrosFacturacionItem.fromJson({
      'CO': {'impuestos': impuestos, 'impuestosIn': impuestosIn},
    });

void main() {
  group('TaxesStrategyFactory', () {
    test('null contribuyente -> default strategy', () {
      expect(TaxesStrategyFactory.taxes(null), isA<TaxesStrategyDefault>());
    });
    test('usaSiat true -> Bolivia strategy', () {
      expect(TaxesStrategyFactory.taxes(_contribuyente(usaSiat: true)),
          isA<TaxesStrategyBo>());
    });
    test('facturacion + paisId BO -> Bolivia strategy', () {
      expect(
        TaxesStrategyFactory.taxes(_contribuyente(
            habilitadoFacturacion: true, config: {'paisId': 'BO'})),
        isA<TaxesStrategyBo>(),
      );
    });
    test('config paisId CO -> Colombia strategy', () {
      expect(
        TaxesStrategyFactory.taxes(_contribuyente(config: {'paisId': 'CO'})),
        isA<TaxesStrategyCo>(),
      );
    });
    test('unrecognized config -> default strategy', () {
      expect(
        TaxesStrategyFactory.taxes(_contribuyente(config: {'paisId': 'PE'})),
        isA<TaxesStrategyDefault>(),
      );
    });
  });

  group('TaxesStrategyDefault', () {
    final strategy = TaxesStrategyDefault();
    test('getTotalItem is quantity * price', () {
      expect(strategy.getTotalItem(_params(impuestos: []), 3, 10), 30);
    });
    test('verifyParameters always null', () {
      expect(strategy.verifyParameters(null, null, null, null), isNull);
    });
    test('metadata', () {
      expect(strategy.decimals, 2);
      expect(strategy.showQR, isTrue);
      expect(strategy.showBreB, isFalse);
      expect(strategy.brandName, 'iZi');
      expect(strategy.countryCode, isNull);
    });
  });

  group('TaxesStrategyBo', () {
    final strategy = TaxesStrategyBo();
    test('getTotalItem is quantity * price', () {
      expect(strategy.getTotalItem(_params(impuestos: []), 2, 25), 50);
    });
    test('verifyParameters requires an economic activity', () {
      expect(strategy.verifyParameters(null, null, null, null),
          PaymentStatus.errorActivity);
      expect(strategy.verifyParameters(null, null, null, '620100'), isNull);
    });
    test('metadata', () {
      expect(strategy.countryCode, 'BO');
      expect(strategy.showQR, isTrue);
    });
  });

  group('TaxesStrategyCo', () {
    final strategy = TaxesStrategyCo();

    test('no taxes -> returns quantity * price', () {
      expect(strategy.getTotalItem(_params(impuestos: []), 2, 50), 100);
    });

    test('adds a percentage tax (excluded)', () {
      final params = _params(impuestos: [
        {'rate': 19, 'isAmount': false, 'monto': 0, 'id': '1', 'codigo': '01'}
      ]);
      // base 100 + 19% = 119
      expect(strategy.getTotalItem(params, 1, 100), 119);
    });

    test('adds a fixed amount tax', () {
      final params = _params(impuestos: [
        {'isAmount': true, 'monto': 5, 'rate': 0, 'id': '1', 'codigo': '02'}
      ]);
      // base 100 + fixed 5 = 105
      expect(strategy.getTotalItem(params, 1, 100), 105);
    });

    test('metadata', () {
      expect(strategy.decimals, 0);
      expect(strategy.showQR, isFalse);
      expect(strategy.showBreB, isTrue);
      expect(strategy.brandName, 'IZIFY');
      expect(strategy.countryCode, 'CO');
    });

    test('verifyParameters always null', () {
      expect(strategy.verifyParameters(null, null, null, null), isNull);
    });
  });
}
