import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';

import 'bm_app_info.dart';
import 'bm_service.dart';

Future<BmContext?> bmContextFrom(AuthState state) async {
  final contribuyente = state.currentContribuyente?.id;
  final device = state.currentDevice;
  final apiUrl = dotenv.env['API_URL'];
  if (contribuyente == null || device == null || apiUrl == null || apiUrl.isEmpty) return null;
  final atcServerUrl = dotenv.env['ATC_SERVER_URL'];
  final config = device.config;
  return BmContext(
    publicToken: await TokenUtils.getToken(),
    contribuyente: contribuyente,
    dispositivo: device.id,
    sucursal: state.currentSucursal?.id?.toString(),
    deviceName: device.nombre,
    flavor: bmFlavor,
    version: bmVersion,
    platform: bmPlatform,
    country: state.taxesStrategy.countryCode,
    provider: config.ipLinkser != null ? 'linkser' : config.ipAtc != null ? 'atc' : 'none',
    apiUrl: apiUrl,
    atcServerUrl: atcServerUrl == null || atcServerUrl.isEmpty ? 'http://localhost:3000' : atcServerUrl,
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
