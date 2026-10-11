// Runs the kiosk's event upload (MonitoringTelemetrySink and its HTTP
// repository) against a REAL izi-ms-monitoreo, with this test standing in
// for the gateway: it rewrites `/monitoreo/*` to `/api/v1/*` and adds the
// gateway key, as izi-ms-auth does.
//
//   MONITOREO_URL=http://127.0.0.1:7110 MONITOREO_GATEWAY_KEY=<GATEWAY_KEY of that ms> \
//     fvm flutter test test/live/monitoring_events_live_test.dart
//
// Skipped unless MONITOREO_URL is set. Only against a local service: it
// enrolls a throwaway kiosk.
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_repository_http.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_store.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_telemetry_sink.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_buffer.dart';
import 'package:izi_kiosco/domain/dto/monitoring_events_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/monitoring/monitoring_service_test.dart' show FakeTimers;
import '../helpers/mocks.dart';

void main() {
  final url = Platform.environment['MONITOREO_URL'];
  final gatewayKey = Platform.environment['MONITOREO_GATEWAY_KEY'] ?? '';
  final skip = url == null ? 'set MONITOREO_URL to run against a real izi-ms-monitoreo' : null;

  /// The gateway's part: route rewrite and key.
  Dio gateway() => Dio(BaseOptions(baseUrl: url ?? '', validateStatus: (_) => true))
    ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      options.path = options.path.replaceFirst('/monitoreo/', '/api/v1/');
      options.headers['X-Gateway-Key'] = gatewayKey;
      handler.next(options);
    }));

  /// A throwaway kiosk, enrolled as the gateway would forward it.
  Future<({String installationId, String token, String deviceId})> enroll() async {
    final installationId = MonitoringStore.newUuidV4();
    final response = await gateway().post('/monitoreo/kiosco/enrolamiento',
        data: {
          'schema': 1,
          'installationId': installationId,
          'kind': 'kiosk',
          'app': {'version': '0.0.0+live', 'flavor': 'local', 'platform': 'web'},
          'deviceName': 'KIO-03-LIVE',
        },
        options: Options(headers: {'izi-contribuyente': '999001', 'izi-sucursal': '1', 'izi-dispositivo': '1'}));
    expect(response.statusCode, anyOf(200, 201), reason: jsonEncode(response.data));
    final body = response.data as Map;
    return (
      installationId: installationId,
      token: body['deviceToken'] as String,
      deviceId: body['deviceId'] as String,
    );
  }

  test('uploads in batches, is acknowledged, and a cleared buffer is a new stream', () async {
    final kiosk = await enroll();
    SharedPreferences.setMockInitialValues({
      'monitoring.installationId': kiosk.installationId,
      'monitoring.deviceToken': kiosk.token,
      'monitoring.deviceId': kiosk.deviceId,
      'monitoring.contribuyenteId': 5,
      'monitoring.dispositivoId': 7,
    });
    final enrollment = MonitoringService(store: MonitoringStore(), timer: FakeTimers().call);
    await enrollment.start(const MonitoringContext(contribuyenteId: 5, dispositivoId: 7));
    final repository = MonitoringRepositoryHttp(dioClient: MockDioClient(), ingestDio: gateway());
    final streamStore = MemoryEventStreamStore();

    Future<MonitoringTelemetrySink> session(TelemetryBuffer buffer) async {
      final sink = MonitoringTelemetrySink(
          enrollment: enrollment,
          repository: repository,
          buffer: buffer,
          store: streamStore,
          chargeInProgress: () => false,
          online: () => true,
          timer: FakeTimers().call);
      await sink.restore();
      Telemetry.install(Telemetry(buffer: buffer, sinks: [sink]));
      return sink;
    }

    final store = MemoryTelemetryStore();
    final buffer = TelemetryBuffer(store: store, saveDelay: Duration.zero);
    final sink = await session(buffer);
    for (var i = 0; i < 250; i++) {
      Telemetry.event('live.e', level: i.isEven ? TelemetryLevel.info : TelemetryLevel.warning,
          chargeId: 'CHG-$i', data: {'i': i, 'token': 'never-sent'});
    }
    await sink.upload();
    expect(sink.status.value.lastCause, isNull);
    expect(sink.state!.ackSeq, 200);
    await sink.upload();
    expect(sink.state!.ackSeq, buffer.lastSeq);
    expect(sink.backlog(), 0);
    final firstStream = sink.state!.stream;

    // Sending the same batch again is harmless (idempotent by seq).
    final again = await repository.uploadEvents(
        MonitoringEventsDto(
            installationId: kiosk.installationId,
            stream: firstStream,
            events: buffer.events.take(MonitoringEventsDto.maxEvents).toList()),
        deviceToken: kiosk.token);
    expect(again.ackSeq, buffer.lastSeq);

    // The storage is cleared, the place survives: a new stream from seq 1.
    final cleared = TelemetryBuffer(saveDelay: Duration.zero);
    final next = await session(cleared);
    expect(next.state!.stream, isNot(firstStream));
    Telemetry.event('live.after_clear');
    await next.upload();
    expect(next.status.value.lastCause, isNull);
    expect(next.state!.ackSeq, cleared.lastSeq);
    expect(cleared.events.first.seq, 1);
    Telemetry.install(Telemetry());
  }, skip: skip);
}
