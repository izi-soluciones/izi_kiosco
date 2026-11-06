import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/device.dart';

void main() {
  group('ConfigDevice printFallbackPdf', () {
    test('defaults to false when omitted or null', () {
      final configNull = ConfigDevice.fromJson(null);
      expect(configNull.printFallbackPdf, isFalse);

      final configEmpty = ConfigDevice.fromJson({});
      expect(configEmpty.printFallbackPdf, isFalse);
    });

    test('parses true when printFallbackPdf is true', () {
      final config = ConfigDevice.fromJson({'printFallbackPdf': true});
      expect(config.printFallbackPdf, isTrue);
    });

    test('parses false when printFallbackPdf is false or invalid type', () {
      final configFalse = ConfigDevice.fromJson({'printFallbackPdf': false});
      expect(configFalse.printFallbackPdf, isFalse);

      final configInvalid = ConfigDevice.fromJson({'printFallbackPdf': 'true'});
      expect(configInvalid.printFallbackPdf, isFalse);
    });
  });
}
