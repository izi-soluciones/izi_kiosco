import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_discovery.dart';
import 'package:nsd/nsd.dart' as nsd;

import '../../helpers/fake_izify_pos.dart';

/// mDNS answers set by each test, per service type.
class FakeBrowser implements MdnsBrowser {
  final Map<String, List<BrowsedService>> byType = {};
  final List<String> browsed = [];

  /// How long mDNS takes to answer.
  Duration delay = Duration.zero;

  @override
  Stream<List<BrowsedService>> browse(String type) {
    browsed.add(type);
    return Stream.fromFuture(Future.delayed(delay, () => byType[type] ?? const []));
  }
}

void main() {
  late FakeBrowser browser;
  final servers = <FakeIzifyPos>[];

  setUp(() => browser = FakeBrowser());
  tearDown(() async {
    for (final s in servers) {
      await s.close();
    }
    servers.clear();
  });

  Future<FakeIzifyPos> terminal({String name = 'izify-POS-11111'}) async {
    final pos = await FakeIzifyPos.start()..name = name;
    servers.add(pos);
    return pos;
  }

  IzifyPosDiscovery discovery({List<String> sweep = const [], int sweepPort = 8081}) =>
      IzifyPosDiscovery(browser: browser, subnetHosts: () async => sweep, sweepPort: sweepPort);

  test('finds a terminal advertised as _izifypos._tcp and confirms it by /health', () async {
    final pos = await terminal();
    browser.byType['_izifypos._tcp'] = [BrowsedService('izify-POS-11111', '127.0.0.1', pos.port)];

    final found = await discovery().scan(timeout: const Duration(seconds: 2), stopWhen: (_) => true);

    expect(found, hasLength(1));
    expect(found.single.name, 'izify-POS-11111');
    expect(found.single.address, IzifyPosAddress('127.0.0.1', pos.port));
    expect(found.single.health.paired, isFalse);
  });

  test('finds an older terminal on _http._tcp and ignores other HTTP services', () async {
    final pos = await terminal();
    final printer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    printer.listen((req) {
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'status': 'OK'}));
      req.response.close();
    });
    addTearDown(() => printer.close(force: true));
    browser.byType['_http._tcp'] = [
      BrowsedService('izify-POS-11111', '127.0.0.1', pos.port),
      // Same answer shape but not advertised as a terminal: never probed.
      BrowsedService('HP LaserJet', '127.0.0.1', printer.port),
    ];

    final found = await discovery().scan(timeout: const Duration(seconds: 5));

    expect(browser.browsed, containsAllInOrder(['_izifypos._tcp', '_http._tcp']));
    expect(found.map((p) => p.address.port), [pos.port]);
  });

  test('an HTTP server that is not PayPOS is not listed', () async {
    final other = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    other.listen((req) {
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'status': 'OK'}));
      req.response.close();
    });
    addTearDown(() => other.close(force: true));
    browser.byType['_izifypos._tcp'] = [BrowsedService('izify-POS-99999', '127.0.0.1', other.port)];

    final found = await discovery().scan(timeout: const Duration(seconds: 2));

    expect(found, isEmpty);
  });

  test('a terminal reached at two addresses is listed once, at its LAN one', () async {
    final pos = await terminal();
    final twin = await terminal(); // Same name: the same PayPOS seen twice.
    browser.byType['_izifypos._tcp'] = [
      BrowsedService('izify-POS-11111', '127.0.0.1', pos.port),
      BrowsedService('izify-POS-11111', '127.0.0.1', twin.port),
    ];

    final found = await discovery().scan(timeout: const Duration(seconds: 2));

    expect(found, hasLength(1));
  });

  test('sweeps the subnet when mDNS finds nothing (multicast blocked)', () async {
    final pos = await terminal();

    final found = await discovery(sweep: ['127.0.0.1'], sweepPort: pos.port)
        .scan(timeout: const Duration(seconds: 8), stopWhen: (_) => true);

    expect(found.single.name, 'izify-POS-11111');
  });

  test('subnetOf lists the other hosts of a private /24, nearest first', () {
    final hosts = IzifyPosDiscovery.subnetOf('192.168.0.13');
    expect(hosts, hasLength(253));
    expect(hosts.take(3), ['192.168.0.12', '192.168.0.14', '192.168.0.11']);
    expect(hosts, isNot(contains('192.168.0.13')));
    expect(hosts, isNot(contains('192.168.0.0')));
    expect(hosts, isNot(contains('192.168.0.255')));
    expect(IzifyPosDiscovery.subnetOf('10.1.2.3'), hasLength(253));
    expect(IzifyPosDiscovery.subnetOf('172.20.0.5'), hasLength(253));
    // Public and malformed addresses are never swept.
    expect(IzifyPosDiscovery.subnetOf('8.8.8.8'), isEmpty);
    expect(IzifyPosDiscovery.subnetOf('172.32.0.1'), isEmpty);
    expect(IzifyPosDiscovery.subnetOf('fe80::1'), isEmpty);
  });

  test('uses the resolved IPv4, not the reverse-DNS host name Android reports', () {
    final resolved = nsd.Service(
      name: 'izify-POS-11111',
      host: 'Android-3.local',
      port: 8081,
      addresses: [InternetAddress('192.168.0.18')],
    );
    expect(NsdMdnsBrowser.ipOf(resolved), '192.168.0.18');
    expect(NsdMdnsBrowser.ipOf(const nsd.Service(name: 'x', host: '192.168.0.20', port: 8081)), '192.168.0.20');
    expect(NsdMdnsBrowser.ipOf(const nsd.Service(name: 'x', host: 'Android-3.local', port: 8081)), isNull);
  });

  test('client health reports the terminal identity from PayPOS 1.26', () async {
    final pos = await terminal(name: 'izify-POS-22222');
    pos.pairedKioskId = 'Kiosko 1 El Gaucho';

    final health = await IzifyPosClient().health(IzifyPosAddress('127.0.0.1', pos.port));

    expect(health.name, 'izify-POS-22222');
    expect(health.isIzifyPos, isTrue);
    // Same value PayPOS computes (SignatureUtilsTest pins it on that side).
    expect(IzifyPosClient.kioskHash('Kiosko 1 El Gaucho'), 'ce1e0c09550d3e32');
    expect(health.pairedKioskHash, 'ce1e0c09550d3e32');
  });
}
