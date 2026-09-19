import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_discovery.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/pos_config/pos_config_bloc.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/pos/izify_pos_discovery_test.dart' show FakeBrowser;
import '../../../helpers/fake_izify_pos.dart';
import '../../../helpers/mocks.dart';

/// AuthBloc whose device settings the test loads when it wants.
class _Auth extends AuthBloc {
  _Auth() : super(MockAuthRepository(), MockBusinessRepository());

  void load(Device? device) => emit(state.copyWith(currentDevice: device));
}

const _kioskId = 'KIOSKO-TEST';

Device _device({String? ipEcopay, String? pin = '4826'}) => Device.fromJson({
      'id': 7,
      'sucursal': 1,
      'nombre': _kioskId,
      'caja': 1,
      'config': {
        if (ipEcopay != null) 'ipEcopay': ipEcopay,
        if (pin != null) 'pin': pin,
        'ecopayConfig': {
          'mqttClientId': 'CAJA1000999',
          'mqttUserName': '1000999',
          'mqttPassword': 'PWD999',
          'commerceId': '22000999',
          'cajaId': '1',
        },
      },
    });

void main() {
  late FakeBrowser browser;
  late _Auth auth;
  final servers = <FakeIzifyPos>[];
  final blocs = <PosConfigBloc>[];

  setUp(() {
    browser = FakeBrowser();
    auth = _Auth();
  });

  tearDown(() async {
    for (final b in blocs) {
      await b.close();
    }
    blocs.clear();
    for (final s in servers) {
      await s.close();
    }
    servers.clear();
    await auth.close();
  });

  Future<FakeIzifyPos> terminal({String name = 'izify-POS-48151'}) async {
    final pos = await FakeIzifyPos.start()..name = name;
    servers.add(pos);
    return pos;
  }

  /// A terminal already paired with this kiosk, as the kiosk left it.
  Future<FakeIzifyPos> pairedTerminal({bool rememberName = true}) async {
    final pos = await terminal();
    pos
      ..pairedKioskId = _kioskId
      ..token = 'tok-paired'
      ..ecopay = {'mqttUserName': '1000999'};
    SharedPreferences.setMockInitialValues({
      'posIp': pos.hostPort,
      'posToken': 'tok-paired',
      'posBackendIp': pos.hostPort,
      if (rememberName) 'posName': pos.name,
    });
    return pos;
  }

  /// The same terminal, after the router gave it a new address.
  Future<FakeIzifyPos> move(FakeIzifyPos pos) async {
    final moved = await terminal(name: pos.name);
    moved
      ..pairedKioskId = pos.pairedKioskId
      ..token = pos.token
      ..ecopay = pos.ecopay;
    await pos.close();
    servers.remove(pos);
    return moved;
  }

  void advertise(FakeIzifyPos pos) => browser.byType['_izifypos._tcp'] = [
        ...?browser.byType['_izifypos._tcp'],
        BrowsedService(pos.name, '127.0.0.1', pos.port),
      ];

  PosConfigBloc start() {
    final bloc = PosConfigBloc(
      auth,
      discovery: IzifyPosDiscovery(browser: browser, subnetHosts: () async => const []),
      rediscoveryTimeout: const Duration(seconds: 3),
    );
    blocs.add(bloc);
    return bloc;
  }

  Future<PosConfigState> settled(PosConfigBloc bloc,
      bool Function(PosConfigState) done) async {
    if (done(bloc.state)) return bloc.state;
    return bloc.stream.firstWhere(done).timeout(const Duration(seconds: 10));
  }

  bool healthy(PosConfigState s) => s.isHealthy == true && s.health != null;

  test('startup: a terminal still paired with the kiosk is just verified', () async {
    final pos = await pairedTerminal();
    auth.load(_device(ipEcopay: pos.hostPort));

    final state = await settled(start(), healthy);

    expect(state.pairedDevice!.port, pos.port);
    expect(state.notReadyReason, isNull);
    expect(pos.pairRequests, 0);
  });

  test('startup: a terminal that forgot the kiosk is paired again', () async {
    final pos = await pairedTerminal();
    pos
      ..pairedKioskId = null
      ..token = null; // "Desvincular dispositivo", reinstall or data cleared.
    auth.load(_device(ipEcopay: pos.hostPort));

    final state = await settled(start(), healthy);

    expect(pos.pairRequests, 1);
    expect(pos.pairedKioskId, _kioskId);
    expect(await TokenUtils.getPosToken(), pos.token);
    expect(state.health!.paired, isTrue);
  });

  test('startup: a token the terminal no longer accepts is replaced', () async {
    final pos = await pairedTerminal();
    pos.token = 'tok-rotated-elsewhere';
    auth.load(_device(ipEcopay: pos.hostPort));

    await settled(start(), healthy);

    expect(pos.pairRequests, 1);
    expect(await TokenUtils.getPosToken(), pos.token);
    expect(pos.token, isNot('tok-rotated-elsewhere'));
  });

  test('startup before the device settings load: pairs again once they arrive', () async {
    final pos = await pairedTerminal();
    pos
      ..pairedKioskId = null
      ..token = null;

    final bloc = start();
    final waiting = await settled(bloc, (s) => s.notReadyReason != null);
    expect(waiting.isHealthy, isFalse);
    expect(pos.pairRequests, 0);

    auth.load(_device(ipEcopay: pos.hostPort));
    await settled(bloc, healthy);

    expect(pos.pairRequests, 1);
    expect(pos.pairedKioskId, _kioskId);
  });

  test('startup: follows its terminal to a new IP, found by name, keeping the pairing', () async {
    final old = await pairedTerminal();
    final oldPort = old.port;
    final pos = await move(old);
    advertise(pos);
    // The backend still holds the old address.
    auth.load(_device(ipEcopay: '127.0.0.1:$oldPort'));

    final state = await settled(start(), healthy);

    expect(state.pairedDevice!.port, pos.port);
    expect(await TokenUtils.getPosIp(), pos.hostPort);
    expect(pos.pairRequests, 0, reason: 'same terminal, token still valid');
  });

  test('a kiosk paired before 1.26 (no stored name) finds its terminal by the paired-kiosk hash', () async {
    final old = await pairedTerminal(rememberName: false);
    final pos = await move(old);
    // Another store terminal, paired with another kiosk, answers first.
    final other = await terminal(name: 'izify-POS-77777');
    other.pairedKioskId = 'KIOSKO-2';
    advertise(other);
    advertise(pos);
    auth.load(_device(ipEcopay: old.hostPort));

    final state = await settled(start(), healthy);

    expect(state.pairedDevice!.port, pos.port);
    expect(await TokenUtils.getPosName(), pos.name);
  });

  test('another terminal on the LAN is never taken for this kiosk\'s', () async {
    final old = await pairedTerminal();
    await old.close();
    servers.remove(old);
    final other = await terminal(name: 'izify-POS-77777');
    other.pairedKioskId = 'KIOSKO-2';
    advertise(other);
    auth.load(_device(ipEcopay: old.hostPort));

    final bloc = start();
    final state = await settled(bloc, (s) => s.notReadyReason != null && !s.notReadyReason!.contains('Buscándolo'));

    expect(state.isHealthy, isFalse);
    expect(state.pairedDevice!.port, old.port);
    expect(other.pairRequests, 0);
  });

  test('a terminal now paired with another kiosk is reported, not silently used', () async {
    final pos = await pairedTerminal();
    pos
      ..pairedKioskId = 'KIOSKO-2'
      ..token = 'tok-kiosko-2';
    auth.load(_device(ipEcopay: pos.hostPort));

    final state = await settled(start(), (s) => s.notReadyReason != null);

    expect(state.isHealthy, isFalse);
    expect(state.notReadyReason, contains('otro'));
    expect(pos.pairedKioskId, 'KIOSKO-2');
  });

  test('the stale backend address does not pull the kiosk away from where it found the terminal', () async {
    final old = await pairedTerminal();
    final oldAddress = old.hostPort;
    final pos = await move(old);
    SharedPreferences.setMockInitialValues({
      'posIp': pos.hostPort, // Moved there on a previous run.
      'posToken': 'tok-paired',
      'posBackendIp': oldAddress,
      'posName': pos.name,
    });
    auth.load(_device(ipEcopay: oldAddress));

    final state = await settled(start(), healthy);

    expect(state.pairedDevice!.port, pos.port);
    expect(pos.pairRequests, 0);
  });

  test('a new backend address is followed', () async {
    final pos = await pairedTerminal();
    final replacement = await terminal(name: 'izify-POS-55555');
    auth.load(_device(ipEcopay: replacement.hostPort));

    final state = await settled(start(), (s) => healthy(s) && s.pairedDevice!.port == replacement.port);

    expect(replacement.pairedKioskId, _kioskId);
    expect(await TokenUtils.getPosBackendIp(), replacement.hostPort);
    expect(pos.pairRequests, 0);
    expect(state.health!.name, 'izify-POS-55555');
  });

  test('periodic checks look for the terminal after it stops answering twice', () async {
    final old = await pairedTerminal();
    auth.load(_device(ipEcopay: old.hostPort));
    final bloc = start();
    await settled(bloc, healthy);

    final pos = await move(old);
    advertise(pos);
    await bloc.checkHealth();
    expect(bloc.state.isHealthy, isFalse);
    expect(bloc.state.pairedDevice!.port, isNot(pos.port));
    unawaited(bloc.checkHealth());

    final state = await settled(bloc, (s) => healthy(s) && s.pairedDevice!.port == pos.port);
    expect(state.notReadyReason, isNull);
  });

  test('the technician list tells free terminals from taken ones', () async {
    final mine = await pairedTerminal();
    final free = await terminal(name: 'izify-POS-22222');
    final taken = await terminal(name: 'izify-POS-33333');
    taken.pairedKioskId = 'KIOSKO-2';
    advertise(mine);
    advertise(free);
    advertise(taken);
    auth.load(_device(ipEcopay: mine.hostPort));
    final bloc = start();
    await settled(bloc, healthy);

    await bloc.beginDiscovery();
    final state = await settled(bloc, (s) => s.discoveredDevices.length == 3);
    await bloc.endDiscovery();

    PosPairing pairingOf(FakeIzifyPos p) =>
        state.discoveredDevices.firstWhere((d) => d.port == p.port).pairing;
    expect(pairingOf(mine), PosPairing.thisKiosk);
    expect(pairingOf(free), PosPairing.free);
    expect(pairingOf(taken), PosPairing.otherKiosk);
    expect(state.discoveredDevices.first.version, '1.26-ecopay');
  });

  test('a terminal unpaired on purpose is not taken back automatically', () async {
    final pos = await pairedTerminal();
    pos
      ..pairedKioskId = null
      ..token = null
      ..unpairedByUser = true; // "Desvincular dispositivo" on the terminal.
    auth.load(_device(ipEcopay: pos.hostPort));

    final state = await settled(start(), (s) => s.notReadyReason != null);

    expect(state.notReadyReason, contains('desvinculado'));
    expect(pos.pairRequests, 0);
  });

  test('another terminal answering at the stored address is not paired; ours is found by name', () async {
    final old = await pairedTerminal();
    final oldPort = old.port;
    final ours = await move(old);
    advertise(ours);
    // A free terminal took our terminal's old address.
    final intruder = await FakeIzifyPos.start(port: oldPort)..name = 'izify-POS-99999';
    servers.add(intruder);
    auth.load(_device(ipEcopay: '127.0.0.1:$oldPort'));

    final state = await settled(start(), (s) => healthy(s) && s.pairedDevice!.port == ours.port);

    expect(intruder.pairRequests, 0);
    expect(ours.pairRequests, 0);
    expect(state.health!.name, ours.name);
  });

  test('an unpair while the kiosk is searching for its terminal is not undone', () async {
    final old = await pairedTerminal();
    final pos = await move(old);
    advertise(pos);
    browser.delay = const Duration(milliseconds: 800);
    auth.load(_device(ipEcopay: old.hostPort));

    final bloc = start();
    await settled(bloc, (s) => s.notReadyReason?.contains('Buscándolo') ?? false);
    await bloc.unpair();
    await Future<void>.delayed(const Duration(seconds: 2));

    expect(bloc.state.pairedDevice, isNull);
    expect(await TokenUtils.getPosIp(), isNull);
    expect(await TokenUtils.getPosToken(), isNull);
    expect(pos.pairRequests, 0);
  });

  test('a kiosk renamed in the backend keeps its terminal while the token works', () async {
    final pos = await pairedTerminal();
    pos.pairedKioskId = 'OLD NAME'; // Paired under the device's former name.
    auth.load(_device(ipEcopay: pos.hostPort));

    final state = await settled(start(), healthy);

    expect(state.notReadyReason, isNull);
    expect(pos.pairRequests, 0);
  });

  test('pairing with another terminal releases the previous one', () async {
    final first = await pairedTerminal();
    auth.load(_device(ipEcopay: first.hostPort));
    final bloc = start();
    await settled(bloc, healthy);

    final second = await terminal(name: 'izify-POS-22222');
    await bloc.pairDevice(PosDevice(name: second.name, ip: '127.0.0.1', port: second.port));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(second.pairedKioskId, _kioskId);
    expect(first.pairedKioskId, isNull, reason: 'the old terminal must not keep naming this kiosk');
    expect(await TokenUtils.getPosName(), 'izify-POS-22222');
  });
}
