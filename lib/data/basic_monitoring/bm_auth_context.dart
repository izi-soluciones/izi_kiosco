import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

import 'bm_app_info.dart';
import 'bm_service.dart';

String _bmEnv(String key) {
  try {
    final value = dotenv.env[key];
    if (value != null && value.isNotEmpty) return value;
  } catch (_) {}
  return 'http://localhost:3000';
}

Future<BmContext?> bmContextFrom(AuthState state) async {
  final contribuyente = state.currentContribuyente?.id;
  final device = state.currentDevice;
  if (contribuyente == null || device == null) return null;
  String? apiUrl;
  try {
    apiUrl = dotenv.env['API_URL'];
  } catch (_) {}
  if (apiUrl == null || apiUrl.isEmpty) return null;
  final config = device.config;
  return BmContext(
    publicToken: config.publicToken,
    contribuyente: contribuyente,
    dispositivo: device.id,
    sucursal: state.currentSucursal?.id?.toString(),
    deviceName: device.nombre,
    flavor: bmFlavor,
    version: bmVersion,
    platform: bmPlatform,
    country: 'BO',
    provider: config.ipLinkser != null
        ? 'linkser'
        : config.ipAtc != null
            ? 'atc'
            : 'none',
    apiUrl: apiUrl,
    atcServerUrl: _bmEnv('ATC_SERVER_URL'),
  );
}

String? bmScreenOf(GoRouter router) {
  try {
    final route = router.routerDelegate.currentConfiguration.matches.last.route;
    return route is GoRoute ? route.name : null;
  } catch (_) {
    return null;
  }
}
