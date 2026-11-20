import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_auth_context.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/domain/strategies/taxes/impl/taxes_strategy_co.dart';
import 'package:shared_preferences/shared_preferences.dart';

AuthState _state({Map<String, dynamic> config = const {}, bool withDevice = true, bool withContribuyente = true}) {
  return AuthState.init().copyWith(
    taxesStrategy: TaxesStrategyCo(),
    currentContribuyente: withContribuyente ? Contribuyente.fromJson({'id': 7, 'modulos': {}}) : null,
    currentSucursal: Sucursal.fromJson({'id': 3}),
    currentDevice: withDevice
        ? Device.fromJson({'id': 9, 'sucursal': 3, 'nombre': 'totem 1', 'caja': 1, 'config': config})
        : null,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'pub-token'});
    dotenv.testLoad(fileInput: 'API_URL=https://api.test\nATC_SERVER_URL=http://pos:3000\n');
  });

  test('bmContextFrom arma el contexto con el token publico y las URLs del .env', () async {
    final ctx = await bmContextFrom(_state(config: {'ipAtc': '1.1.1.1'}));

    expect(ctx, isNotNull);
    expect(ctx!.publicToken, 'pub-token');
    expect(ctx.contribuyente, 7);
    expect(ctx.dispositivo, 9);
    expect(ctx.sucursal, '3');
    expect(ctx.deviceName, 'totem 1');
    expect(ctx.country, 'CO');
    expect(ctx.provider, 'atc');
    expect(ctx.apiUrl, 'https://api.test');
    expect(ctx.atcServerUrl, 'http://pos:3000');
  });

  test('con Linkser y ATC configurados el provider es linkser', () async {
    final ctx = await bmContextFrom(_state(config: {'ipAtc': '1.1.1.1', 'ipLinkser': '2.2.2.2'}));
    expect(ctx!.provider, 'linkser');
  });

  test('sin Linkser ni ATC el provider es none', () async {
    final ctx = await bmContextFrom(_state());
    expect(ctx!.provider, 'none');
  });

  test('sin ATC_SERVER_URL usa http://localhost:3000', () async {
    dotenv.testLoad(fileInput: 'API_URL=https://api.test\nATC_SERVER_URL=\n');
    expect((await bmContextFrom(_state()))!.atcServerUrl, 'http://localhost:3000');
    dotenv.testLoad(fileInput: 'API_URL=https://api.test\n');
    expect((await bmContextFrom(_state()))!.atcServerUrl, 'http://localhost:3000');
  });

  test('sin API_URL devuelve null', () async {
    dotenv.testLoad(fileInput: 'ATC_SERVER_URL=http://pos:3000\n');
    expect(await bmContextFrom(_state()), isNull);
  });

  test('sin dispositivo o sin contribuyente devuelve null', () async {
    expect(await bmContextFrom(_state(withDevice: false)), isNull);
    expect(await bmContextFrom(_state(withContribuyente: false)), isNull);
  });

  test('sin token publico lo deja en null', () async {
    SharedPreferences.setMockInitialValues({});
    expect((await bmContextFrom(_state()))!.publicToken, isNull);
  });
}
