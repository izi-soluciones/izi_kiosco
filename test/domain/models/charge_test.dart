import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/models/charge.dart';

void main() {
  group('Charge.fromJson', () {
    test('absolute qr string is stored as a URL', () {
      final c = Charge.fromJson({'qr': 'https://pay.izi/abc', 'uuid': 'u1', 'id': 7});
      expect(c.qrUrl, 'https://pay.izi/abc');
      expect(c.qrBase64, isNull);
      expect(c.uuid, 'u1');
      expect(c.id, 7);
    });

    test('non-absolute qr string is treated as base64 (last comma segment)', () {
      final c = Charge.fromJson({'qr': 'header,PAYLOAD64'});
      expect(c.qrUrl, isNull);
      expect(c.qrBase64, 'PAYLOAD64');
    });

    test('defaults uuid and id when missing', () {
      final c = Charge.fromJson({});
      expect(c.uuid, '');
      expect(c.id, 0);
      expect(c.qrUrl, isNull);
      expect(c.qrBase64, isNull);
    });

    test('extracts nested integration token / handles', () {
      final c = Charge.fromJson({
        'uuid': 'u1',
        'custom': {
          'datosIntegracion': {
            'token': 'tk',
            'cobroKeyValue': 'kv',
            'cobroHandle': 'h1',
          }
        }
      });
      expect(c.token, 'tk');
      expect(c.cobroKeyValue, 'kv');
      expect(c.cobroHandle, 'h1');
    });

    test('nested token is null when structure is not a map', () {
      final c = Charge.fromJson({'uuid': 'u1', 'custom': 'nope'});
      expect(c.token, isNull);
    });
  });

  group('Charge.fromJsonAttempt', () {
    test('forces the passed uuid and sets intentoPago from id', () {
      final c = Charge.fromJsonAttempt({'id': 55}, 'my-uuid');
      expect(c.uuid, 'my-uuid');
      expect(c.id, 55);
      expect(c.intentoPago, 55);
    });
  });

  group('Charge equality/copyWith', () {
    test('copyWith overrides selected fields, keeps the rest', () {
      const c = Charge(qrUrl: 'a', uuid: 'u', qrBase64: null, token: 't', id: 1);
      final c2 = c.copyWith(uuid: 'u2');
      expect(c2.uuid, 'u2');
      expect(c2.qrUrl, 'a');
      expect(c2.token, 't');
    });
    test('value equality via Equatable props', () {
      const a = Charge(qrUrl: 'a', uuid: 'u', qrBase64: null, token: null, id: 1);
      const b = Charge(qrUrl: 'a', uuid: 'u', qrBase64: null, token: null, id: 1);
      expect(a, equals(b));
    });
  });
}
