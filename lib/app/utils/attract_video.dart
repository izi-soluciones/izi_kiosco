import 'package:izi_kiosco/app/values/app_constants.dart';
import 'package:izi_kiosco/domain/models/device.dart';

/// Video de atraccion del Home.
///
/// En el primer arranque el Home muestra la pantalla estatica durante
/// `tiempoVideo` segundos antes del video. Al volver de un pedido completado
/// se salta esa espera si el video ya esta listo.
class AttractVideo {
  AttractVideo._();

  static const String fromCompletedOrderKey = 'fromCompletedOrder';

  /// `extra` para navegar al Home despues de un pedido completado.
  static const Map<String, bool> extraFromCompletedOrder = {
    fromCompletedOrderKey: true
  };

  static bool isFromCompletedOrder(Object? extra) {
    return extra is Map && extra[fromCompletedOrderKey] == true;
  }

  /// En web el video se reproduce desde la URL configurada; en la app, desde
  /// el archivo que descarga el AuthBloc.
  static bool isVideoReady(
      {required ConfigDevice? config,
      required bool hasDownloadedVideo,
      required bool isWeb}) {
    return isWeb ? config?.video != null : hasDownloadedVideo;
  }

  static Duration delay(
      {required ConfigDevice? config,
      required bool fromCompletedOrder,
      required bool videoReady}) {
    if (fromCompletedOrder && videoReady) {
      return Duration.zero;
    }
    return Duration(seconds: config?.timeVideo ?? AppConstants.timerVideo);
  }
}
