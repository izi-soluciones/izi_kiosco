import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/basic_monitoring/bm_auth_context.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/models/contribuyente.dart';
import 'package:izi_kiosco/domain/models/device.dart';

Map _deviceJson(dynamic config) => {
      'id': 7,
      'sucursal': 3,
      'nombre': 'Kiosco 1',
      'caja': 1,
      'config': config,
    };

Device _device({String? token, String? ipAtc, String? ipLinkser}) => Device(
      id: 7,
      sucursal: 3,
      nombre: 'Kiosco 1',
      caja: 1,
      enUso: false,
      activo: true,
      config: ConfigDevice(
        actividadEconomica: null,
        almacen: null,
        isRetail: false,
        demo: false,
        ipAtc: ipAtc,
        ipLinkser: ipLinkser,
        publicToken: token,
      ),
    );

AuthState _state({Device? device, int? contribuyente = 5}) => AuthState.init().copyWith(
      status: AuthStatus.okAuth,
      currentContribuyente: contribuyente == null ? null : Contribuyente(id: contribuyente, actividadesEconomicas: [], autorizadosAPI: []),
      currentSucursal: Sucursal(id: 3),
      currentDevice: device,
    );

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=https://api.test\nATC_SERVER_URL=http://localhost:3000');
  });

  test('Device.fromJson con config.token número, mapa, vacío o ausente da publicToken null y no lanza', () {
    for (final config in [
      {'token': 5},
      {'token': {'a': 1}},
      {'token': ''},
      <String, dynamic>{},
      null,
    ]) {
      expect(Device.fromJson(_deviceJson(config)).config.publicToken, isNull);
    }
    expect(Device.fromJson(_deviceJson({'token': 'izk_abc'})).config.publicToken, 'izk_abc');
  });

  test('bmContextFrom con token lo devuelve, y con Linkser y ATC configurados da provider linkser', () async {
    final ctx = await bmContextFrom(
        _state(device: _device(token: 'izk_abc', ipAtc: '1.1.1.1', ipLinkser: '2.2.2.2')));
    expect(ctx!.publicToken, 'izk_abc');
    expect(ctx.provider, 'linkser');
    expect(ctx.contribuyente, 5);
    expect(ctx.dispositivo, 7);
    expect(ctx.sucursal, '3');
    expect(ctx.deviceName, 'Kiosco 1');
    expect(ctx.country, 'BO');
    expect(ctx.flavor, 'bk');
    expect(ctx.apiUrl, 'https://api.test');
    expect(ctx.atcServerUrl, 'http://localhost:3000');
  });

  test('bmContextFrom: provider atc, none, y null si falta contribuyente, dispositivo o API_URL', () async {
    expect((await bmContextFrom(_state(device: _device(ipAtc: '1.1.1.1'))))!.provider, 'atc');
    expect((await bmContextFrom(_state(device: _device())))!.provider, 'none');
    expect(await bmContextFrom(_state(device: _device(), contribuyente: null)), isNull);
    expect(await bmContextFrom(_state()), isNull);
    dotenv.testLoad(fileInput: 'API_URL=');
    expect(await bmContextFrom(_state(device: _device())), isNull);
  });

  test('bmContextFrom: sin ATC_SERVER_URL usa http://localhost:3000', () async {
    dotenv.testLoad(fileInput: 'API_URL=https://api.test');
    expect((await bmContextFrom(_state(device: _device())))!.atcServerUrl, 'http://localhost:3000');
  });
}
