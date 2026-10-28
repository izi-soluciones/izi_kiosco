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
      expect(config.tipoConsumo, 'solo_llevar');
      expect(config.isSoloLlevar, isTrue);
      expect(config.isSoloLocal, isFalse);
      expect(config.isAmbos, isFalse);
    });

    test('normaliza mayúsculas y espacios en variantes de llevar', () {
      final variantes = [
        'Solo_Llevar',
        '  Solo para llevar  ',
        'SOLO_LLEVAR',
        'Llevar ',
      ];
      for (final v in variantes) {
        final config = ConfigDevice.fromJson({'tipoConsumo': v});
        expect(config.tipoConsumo, 'solo_llevar', reason: 'Fallo con: $v');
        expect(config.isSoloLlevar, isTrue, reason: 'Fallo con: $v');
        expect(config.isSoloLocal, isFalse, reason: 'Fallo con: $v');
        expect(config.isAmbos, isFalse, reason: 'Fallo con: $v');
      }
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
      expect(config.tipoConsumo, 'solo_local');
      expect(config.isSoloLocal, isTrue);
      expect(config.isSoloLlevar, isFalse);
      expect(config.isAmbos, isFalse);
    });

    test('normaliza mayúsculas y espacios en variantes de local', () {
      final variantes = [
        'Solo_Local',
        '  Solo para consumo en local  ',
        'SOLO_LOCAL',
        'Local ',
      ];
      for (final v in variantes) {
        final config = ConfigDevice.fromJson({'tipoConsumo': v});
        expect(config.tipoConsumo, 'solo_local', reason: 'Fallo con: $v');
        expect(config.isSoloLocal, isTrue, reason: 'Fallo con: $v');
        expect(config.isSoloLlevar, isFalse, reason: 'Fallo con: $v');
        expect(config.isAmbos, isFalse, reason: 'Fallo con: $v');
      }
    });

    test('configurado como ambos activa isAmbos', () {
      final config = ConfigDevice.fromJson({'tipoConsumo': 'ambos'});
      expect(config.tipoConsumo, 'ambos');
      expect(config.isAmbos, isTrue);
      expect(config.isSoloLlevar, isFalse);
      expect(config.isSoloLocal, isFalse);
    });

    test('normaliza mayúsculas y espacios en ambos', () {
      final config = ConfigDevice.fromJson({'tipoConsumo': '  Ambos  '});
      expect(config.tipoConsumo, 'ambos');
      expect(config.isAmbos, isTrue);
      expect(config.isSoloLlevar, isFalse);
      expect(config.isSoloLocal, isFalse);
    });

    test('valor desconocido cae por defecto en ambos', () {
      final config = ConfigDevice.fromJson({'tipoConsumo': 'valor_inexistente'});
      expect(config.tipoConsumo, 'ambos');
      expect(config.isAmbos, isTrue);
      expect(config.isSoloLlevar, isFalse);
      expect(config.isSoloLocal, isFalse);
    });
  });
}
