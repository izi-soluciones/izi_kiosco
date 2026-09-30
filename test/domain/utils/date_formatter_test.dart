import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/utils/date_formatter.dart';

void main() {
  // Use fixed field values; visual/data/dateHour/hour read local Y/M/D/H/M
  // fields directly so they are timezone-independent.
  final date = DateTime(2024, 3, 5, 9, 7);

  group('DateFormatter.dateFormat', () {
    test('visual -> DD/MM/YYYY with zero padding', () {
      expect(date.dateFormat(DateFormatterType.visual), '05/03/2024');
    });
    test('data -> YYYY-MM-DD with zero padding', () {
      expect(date.dateFormat(DateFormatterType.data), '2024-03-05');
    });
    test('dateHour -> DD/MM/YYYY HH:MM', () {
      expect(date.dateFormat(DateFormatterType.dateHour), '05/03/2024 09:07');
    });
    test('hour -> HH:MM', () {
      expect(date.dateFormat(DateFormatterType.hour), '09:07');
    });
    test('dataWithHour -> ISO8601 in UTC', () {
      final utc = DateTime.utc(2024, 3, 5, 14, 30);
      expect(utc.dateFormat(DateFormatterType.dataWithHour),
          '2024-03-05T14:30:00.000Z');
    });
  });

  group('DateFormatter.changeFormatter', () {
    test('converts ISO date to visual', () {
      expect(
        DateFormatter.changeFormatter('2024-03-05', DateFormatterType.visual),
        '05/03/2024',
      );
    });
    test('converts visual date to ISO-style with dashes swapped', () {
      expect(
        DateFormatter.changeFormatter('05/03/2024', DateFormatterType.data),
        '2024-03-05',
      );
    });
    test('returns original string when it does not split into 3 parts', () {
      expect(
        DateFormatter.changeFormatter('abc', DateFormatterType.visual),
        'abc',
      );
    });
    test('returns empty string for unsupported format types', () {
      expect(
        DateFormatter.changeFormatter('05/03/2024', DateFormatterType.hour),
        '',
      );
    });
  });

  group('DateFormatter.getDateFactorChart', () {
    test('computes ms difference divided by the interval', () {
      final init = DateTime.utc(2024, 1, 1);
      final end = DateTime.utc(2024, 1, 2);
      expect(
        DateFormatter.getDateFactorChart(init: init, end: end, interval: 1000),
        86400.0,
      );
    });
    test('is zero when init and end are equal', () {
      final d = DateTime.utc(2024, 1, 1);
      expect(
        DateFormatter.getDateFactorChart(init: d, end: d, interval: 1000),
        0.0,
      );
    });
  });
}
