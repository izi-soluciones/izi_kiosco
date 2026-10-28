import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/device.dart';

void main() {
  group('ConfigDevice tipoConsumo', () {
    test('por defecto tipoConsumo es ambos cuando no está en el json', () {
      final config = ConfigDevice.fromJson({});
      expect(config.tipoConsumo, 'ambos');
      expect(config.isAmbos, isTrue);
      expect(config.isSoloLlevar, isFalse);
      expect(config.isSoloLocal, isFalse);
    });

    test('configurado como solo_llevar activa isSoloLlevar', () {
      final config = ConfigDevice.fromJson({'tipoConsumo': 'solo_llevar'});
      expect(config.tipoConsumo, 'solo_llevar');
      expect(config.isSoloLlevar, isTrue);
      expect(config.isSoloLocal, isFalse);
      expect(config.isAmbos, isFalse);
    });

    test('configurado como solo para llevar activa isSoloLlevar', () {
      final config = ConfigDevice.fromJson({'tipoConsumo': 'solo para llevar'});
      expect(config.isSoloLlevar, isTrue);
      expect(config.isSoloLocal, isFalse);
      expect(config.isAmbos, isFalse);
    });

    test('configurado como solo_local activa isSoloLocal', () {
      final config = ConfigDevice.fromJson({'tipoConsumo': 'solo_local'});
      expect(config.tipoConsumo, 'solo_local');
      expect(config.isSoloLocal, isTrue);
      expect(config.isSoloLlevar, isFalse);
      expect(config.isAmbos, isFalse);
    });

    test('configurado como solo para consumo en local activa isSoloLocal', () {
      final config = ConfigDevice.fromJson({'tipoConsumo': 'solo para consumo en local'});
      expect(config.isSoloLocal, isTrue);
      expect(config.isSoloLlevar, isFalse);
      expect(config.isAmbos, isFalse);
    });

    test('configurado como ambos activa isAmbos', () {
      final config = ConfigDevice.fromJson({'tipoConsumo': 'ambos'});
      expect(config.tipoConsumo, 'ambos');
      expect(config.isAmbos, isTrue);
      expect(config.isSoloLlevar, isFalse);
      expect(config.isSoloLocal, isFalse);
    });
  });
}

