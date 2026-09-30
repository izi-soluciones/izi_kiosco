import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';

Contribuyente _cuenta(dynamic config) =>
    Contribuyente(config: config, actividadesEconomicas: null, autorizadosAPI: null);

void main() {
  group('prefijo del teléfono según el país de la cuenta', () {
    test('una cuenta de Colombia arranca en +57', () {
      expect(PaymentState.phonePrefixFor(_cuenta({'paisId': 'CO'})), '+57');
    });

    test('una cuenta de Bolivia arranca en +591', () {
      expect(PaymentState.phonePrefixFor(_cuenta({'paisId': 'BO'})), '+591');
    });

    test('sin país en la cuenta se usa el del build', () {
      final delBuild = PaymentState.init().phonePrefix;
      expect(PaymentState.phonePrefixFor(null), delBuild);
      expect(PaymentState.phonePrefixFor(_cuenta({})), delBuild);
      expect(PaymentState.phonePrefixFor(_cuenta('no es un mapa')), delBuild);
    });
  });
}
