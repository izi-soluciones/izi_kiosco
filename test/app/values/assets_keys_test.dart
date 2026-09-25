import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/utils/kiosk_locale.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';

void main() {
  group('AssetsKeys.homeTitleForLocale', () {
    test('cada idioma soportado tiene su svg de titulo en disco', () {
      for (var locale in KioskLocale.supported) {
        for (var retail in [true, false]) {
          var path = AssetsKeys.homeTitleForLocale(locale.languageCode,
              retail: retail);
          expect(File(path).existsSync(), isTrue,
              reason: 'falta $path para ${locale.languageCode} (retail: $retail)');
        }
      }
    });

    test('devuelve el svg de retail solo cuando corresponde', () {
      expect(AssetsKeys.homeTitleForLocale('es', retail: false),
          AssetsKeys.homeTitleSvg);
      expect(AssetsKeys.homeTitleForLocale('es', retail: true),
          AssetsKeys.homeTitleRetailSvg);
      expect(AssetsKeys.homeTitleForLocale('en', retail: false),
          AssetsKeys.homeTitleSvgEn);
      expect(AssetsKeys.homeTitleForLocale('en', retail: true),
          AssetsKeys.homeTitleRetailSvgEn);
    });

    test('un idioma sin svg propio cae al espanol', () {
      expect(AssetsKeys.homeTitleForLocale('pt', retail: false),
          AssetsKeys.homeTitleSvg);
      expect(AssetsKeys.homeTitleForLocale('pt', retail: true),
          AssetsKeys.homeTitleRetailSvg);
    });
  });
}
