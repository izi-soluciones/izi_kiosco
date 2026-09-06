import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/utils/kiosk_locale.dart';
import 'package:izi_kiosco/domain/models/device.dart';

ConfigDevice configWith({dynamic idioma, dynamic permite}) {
  return ConfigDevice.fromJson({
    if (idioma != null) "idiomaDefecto": idioma,
    if (permite != null) "permiteCambioIdioma": permite,
  });
}

void main() {
  group('KioskLocale.parse', () {
    test('acepta los idiomas soportados', () {
      expect(KioskLocale.parse('es'), KioskLocale.es);
      expect(KioskLocale.parse('en'), KioskLocale.en);
    });

    test('normaliza mayusculas, espacios y variantes regionales', () {
      expect(KioskLocale.parse(' EN '), KioskLocale.en);
      expect(KioskLocale.parse('en_US'), KioskLocale.en);
      expect(KioskLocale.parse('es-BO'), KioskLocale.es);
    });

    test('devuelve null para lo no soportado', () {
      expect(KioskLocale.parse(null), isNull);
      expect(KioskLocale.parse('pt'), isNull);
      expect(KioskLocale.parse(''), isNull);
    });
  });

  group('KioskLocale.defaultFor', () {
    test('usa el idioma configurado en base de datos', () {
      expect(KioskLocale.defaultFor(configWith(idioma: 'en')), KioskLocale.en);
      expect(KioskLocale.defaultFor(configWith(idioma: 'es')), KioskLocale.es);
    });

    test('cae a espanol si el campo falta o es invalido', () {
      expect(KioskLocale.defaultFor(null), KioskLocale.es);
      expect(KioskLocale.defaultFor(configWith()), KioskLocale.es);
      expect(KioskLocale.defaultFor(configWith(idioma: 'pt')), KioskLocale.es);
      expect(KioskLocale.defaultFor(configWith(idioma: 123)), KioskLocale.es);
      expect(KioskLocale.defaultFor(configWith(idioma: '')), KioskLocale.es);
    });

    test('el idioma del kiosco no depende del locale del sistema', () {
      expect(KioskLocale.defaultFor(null), KioskLocale.es);
    });
  });

  group('KioskLocale.canSwitch', () {
    test('solo con el flag explicito en true', () {
      expect(KioskLocale.canSwitch(configWith(permite: true)), isTrue);
      expect(KioskLocale.canSwitch(configWith(permite: false)), isFalse);
      expect(KioskLocale.canSwitch(configWith()), isFalse);
      expect(KioskLocale.canSwitch(null), isFalse);
    });

    test('un valor no booleano no habilita el selector', () {
      expect(KioskLocale.canSwitch(configWith(permite: "true")), isFalse);
    });
  });

  test('cada idioma soportado tiene nombre en su propio idioma', () {
    for (var locale in KioskLocale.supported) {
      expect(KioskLocale.nameOf(locale), isNotEmpty);
    }
    expect(KioskLocale.nameOf(KioskLocale.es), 'Español');
    expect(KioskLocale.nameOf(KioskLocale.en), 'English');
    expect(KioskLocale.nameOf(const Locale('pt')), 'PT');
  });
}
