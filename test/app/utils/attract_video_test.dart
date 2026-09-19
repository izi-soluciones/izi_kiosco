import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/utils/attract_video.dart';
import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/models/device.dart';

// Bug 86dw9yytb: al volver de un pedido completado el Home esperaba `tiempoVideo`
// segundos en la pantalla "escanea y paga aqui" antes de arrancar el video.

ConfigDevice configWith({int? tiempoVideo, String? video}) {
  return ConfigDevice.fromJson({
    if (tiempoVideo != null) "tiempoVideo": tiempoVideo,
    if (video != null) "video": video,
  });
}

void main() {
  group('AttractVideo.delay', () {
    test('primer arranque: espera tiempoVideo aunque el video este listo', () {
      expect(
          AttractVideo.delay(
              config: configWith(tiempoVideo: 8, video: 'https://x/v.mp4'),
              fromCompletedOrder: false,
              videoReady: true),
          const Duration(seconds: 8));
    });

    test('primer arranque sin tiempoVideo usa el valor por defecto', () {
      expect(
          AttractVideo.delay(
              config: configWith(), fromCompletedOrder: false, videoReady: false),
          Duration(seconds: AppConstants.timerVideo));
      expect(
          AttractVideo.delay(
              config: null, fromCompletedOrder: false, videoReady: false),
          Duration(seconds: AppConstants.timerVideo));
    });

    test('tiempoVideo = 0 sigue sin espera', () {
      expect(
          AttractVideo.delay(
              config: configWith(tiempoVideo: 0),
              fromCompletedOrder: false,
              videoReady: false),
          Duration.zero);
    });

    test('al volver de un pedido con el video listo va directo al video', () {
      expect(
          AttractVideo.delay(
              config: configWith(tiempoVideo: 8, video: 'https://x/v.mp4'),
              fromCompletedOrder: true,
              videoReady: true),
          Duration.zero);
    });

    test('al volver de un pedido sin video listo mantiene la espera', () {
      expect(
          AttractVideo.delay(
              config: configWith(tiempoVideo: 8),
              fromCompletedOrder: true,
              videoReady: false),
          const Duration(seconds: 8));
    });
  });

  group('AttractVideo.isVideoReady', () {
    test('en la app hace falta el archivo descargado', () {
      final config = configWith(video: 'https://x/v.mp4');
      expect(
          AttractVideo.isVideoReady(
              config: config, hasDownloadedVideo: false, isWeb: false),
          isFalse);
      expect(
          AttractVideo.isVideoReady(
              config: config, hasDownloadedVideo: true, isWeb: false),
          isTrue);
    });

    test('en web basta la URL configurada', () {
      expect(
          AttractVideo.isVideoReady(
              config: configWith(video: 'https://x/v.mp4'),
              hasDownloadedVideo: false,
              isWeb: true),
          isTrue);
      expect(
          AttractVideo.isVideoReady(
              config: configWith(), hasDownloadedVideo: false, isWeb: true),
          isFalse);
    });
  });

  group('AttractVideo.isFromCompletedOrder', () {
    test('reconoce el extra de pedido completado', () {
      expect(
          AttractVideo.isFromCompletedOrder(
              AttractVideo.extraFromCompletedOrder),
          isTrue);
    });

    test('cualquier otro extra es un arranque normal', () {
      expect(AttractVideo.isFromCompletedOrder(null), isFalse);
      expect(AttractVideo.isFromCompletedOrder({'tableId': 3}), isFalse);
      expect(AttractVideo.isFromCompletedOrder('fromCompletedOrder'), isFalse);
    });
  });
}
