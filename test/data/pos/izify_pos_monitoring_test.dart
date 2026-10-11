import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';

void main() {
  const address = IzifyPosAddress('192.168.1.50');

  IzifyPosClient answering(http.Response Function(http.Request request) reply,
          {List<http.Request>? into}) =>
      IzifyPosClient(httpClient: MockClient((request) async {
        into?.add(request);
        return reply(request);
      }));

  group('GET /monitoring/status', () {
    test('reads the enrollment, with the pairing token', () async {
      final requests = <http.Request>[];
      final client = answering(
          (_) => http.Response(
              jsonEncode({
                'enrolled': false,
                'reenrollRequired': true,
                'installationId': 'u',
                'deviceId': 'd1',
                'applianceId': 'a1',
                'apiHost': null,
              }),
              200),
          into: requests);
      final status = await client.monitoringStatus(address, token: 'tok');
      expect(status!.enrolled, isFalse);
      expect(status.reenrollRequired, isTrue);
      expect(status.applianceId, 'a1');
      expect(requests.single.url.toString(), 'http://192.168.1.50:8081/monitoring/status');
      expect(requests.single.headers['Authorization'], 'Bearer tok');
    });

    test('an older PayPOS (404) has no monitoring: null', () async {
      final client = answering((_) => http.Response('Not Found', 404));
      expect(await client.monitoringStatus(address, token: 'tok'), isNull);
    });

    test('a rejected token or no answer is an exception', () async {
      final rejected = answering((_) => http.Response(
          jsonEncode({'success': false, 'code': 'UNAUTHORIZED', 'message': 'x'}), 401));
      expect(() => rejected.monitoringStatus(address, token: 'tok'),
          throwsA(isA<IzifyPosException>().having((e) => e.statusCode, 'status', 401)));
      final down = IzifyPosClient(
          httpClient: MockClient((_) async => throw http.ClientException('Connection refused')));
      expect(() => down.monitoringStatus(address, token: 'tok'),
          throwsA(isA<IzifyPosException>().having((e) => e.code, 'code', 'UNREACHABLE')));
    });
  });

  group('POST /monitoring/enroll', () {
    test('sends the code and the gateway; done when it says enrolled', () async {
      final requests = <http.Request>[];
      final client = answering(
          (_) => http.Response(jsonEncode({'enrolled': true, 'deviceId': 't1'}), 200),
          into: requests);
      await client.monitoringEnroll(address,
          token: 'tok', code: 'K7Q-4MZ-9TD', apiBaseUrl: 'https://api.example.test/');
      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer tok');
      expect(jsonDecode(request.body), {'code': 'K7Q-4MZ-9TD', 'apiBaseUrl': 'https://api.example.test/'});
    });

    test("the terminal's refusals come with its code", () async {
      for (final (status, code) in [
        (409, 'BUSY'),
        (400, 'ENROLLMENT_CODE_INVALID'),
        (400, 'API_NOT_ALLOWED'),
        (502, 'ENROLL_FAILED'),
      ]) {
        final client = answering((_) => http.Response(
            jsonEncode({'success': false, 'code': code, 'message': 'm'}), status));
        await expectLater(
            client.monitoringEnroll(address, token: 't', code: 'c', apiBaseUrl: 'https://a/'),
            throwsA(isA<IzifyPosException>()
                .having((e) => e.code, 'code', code)
                .having((e) => e.statusCode, 'status', status)));
      }
    });

    test('a terminal without the route is UNSUPPORTED', () async {
      final client = answering((_) => http.Response('', 404));
      await expectLater(
          client.monitoringEnroll(address, token: 't', code: 'c', apiBaseUrl: 'https://a/'),
          throwsA(isA<IzifyPosException>().having((e) => e.code, 'code', 'UNSUPPORTED')));
    });
  });
}
