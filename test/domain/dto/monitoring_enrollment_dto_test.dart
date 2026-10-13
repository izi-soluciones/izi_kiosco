import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/dto/monitoring_enrollment_dto.dart';

const _installation = '0b6f1c6e-3d2a-4c1e-9a5b-2f7d8e9c0a1b';

void main() {
  group('MonitoringEnrollmentDto', () {
    test('cuts the names to what izi-ms-monitoreo accepts', () {
      final body = MonitoringEnrollmentDto(
        installationId: _installation,
        app: MonitoringApp(version: '9' * 80, flavor: 'f' * 70, platform: 'p' * 65),
        deviceName: '  ${'K' * 150}  ',
        contribuyenteNombre: 'R' * 250,
        sucursalNombre: 'S' * 201,
        pais: 'P' * 300,
      ).toJson();

      expect(body['deviceName'], 'K' * MonitoringEnrollmentDto.maxDeviceNameLength);
      final business = body['business'] as Map<String, dynamic>;
      expect(business.containsKey('pais'), isFalse, reason: 'not a country code');
      for (final field in ['contribuyenteNombre', 'sucursalNombre']) {
        expect((business[field] as String).length, MonitoringEnrollmentDto.maxBusinessFieldLength,
            reason: field);
      }
      final app = body['app'] as Map<String, dynamic>;
      for (final field in ['version', 'flavor', 'platform']) {
        expect((app[field] as String).length, MonitoringApp.maxFieldLength, reason: field);
      }
      expect(MonitoringEnrollmentDto.maxDeviceNameLength, 100);
      expect(MonitoringEnrollmentDto.maxBusinessFieldLength, 200);
      expect(MonitoringApp.maxFieldLength, 64);
    });

    test('never splits an emoji at the cut', () {
      // 99 letters and an emoji (2 UTF-16 units) over the 100 limit.
      final name = '${'a' * 99}😀 tail';
      final body = MonitoringEnrollmentDto(
        installationId: _installation,
        app: const MonitoringApp(version: '1', flavor: 'local', platform: 'web'),
        deviceName: name,
        contribuyenteNombre: '${'b' * 199}🇧🇴',
      ).toJson();

      final deviceName = body['deviceName'] as String;
      expect(deviceName, 'a' * 99);
      expect(deviceName.length, lessThanOrEqualTo(100));
      final contribuyente = body['business']['contribuyenteNombre'] as String;
      expect(contribuyente.length, lessThanOrEqualTo(200));
      expect(contribuyente, 'b' * 199);

      // The emoji fits whole when the cut falls right after it.
      expect(MonitoringEnrollmentDto.fitText('${'a' * 98}😀xyz', 100), '${'a' * 98}😀');
      for (final cut in [1, 2, 3, 50, 99, 100]) {
        final fitted = MonitoringEnrollmentDto.fitText('😀' * 60, cut);
        if (fitted == null) continue;
        expect(fitted.length, lessThanOrEqualTo(cut));
        expect(fitted.runes.every((r) => r == 0x1F600), isTrue, reason: 'cut $cut');
      }
    });

    test('trims the values and leaves out the blank ones', () {
      final body = const MonitoringEnrollmentDto(
        installationId: _installation,
        app: MonitoringApp(version: ' 2.3.1+45 ', flavor: ' ', platform: 'web'),
        deviceName: '  KIOSKO-01 ',
        contribuyenteNombre: '   ',
        sucursalNombre: ' Casa Matriz',
        pais: null,
      ).toJson();

      expect(body['deviceName'], 'KIOSKO-01');
      expect(body['business'], {'sucursalNombre': 'Casa Matriz'});
      expect(body['app'], {'version': '2.3.1+45', 'platform': 'web'});
    });

    test('pais goes as an ISO 3166-1 alpha-2 code, or not at all', () {
      Object? pais(String? value) => (MonitoringEnrollmentDto(
            installationId: _installation,
            app: const MonitoringApp(version: '1', flavor: 'izify', platform: 'web'),
            pais: value,
          ).toJson()['business'] as Map?)?['pais'];

      expect(pais('BO'), 'BO');
      expect(pais(' co '), 'CO');
      for (final other in [null, '', 'Bolivia', 'BOL', '59', 'B']) {
        expect(pais(other), isNull, reason: '$other');
      }
    });

    test('short values go as they are', () {
      final body = const MonitoringEnrollmentDto(
        installationId: _installation,
        app: MonitoringApp(version: null, flavor: 'izify', platform: 'web'),
        deviceName: 'KIOSKO-01',
      ).toJson();
      expect(body, {
        'schema': 1,
        'installationId': _installation,
        'kind': 'kiosk',
        'app': {'flavor': 'izify', 'platform': 'web'},
        'deviceName': 'KIOSKO-01',
      });
    });
  });
}
