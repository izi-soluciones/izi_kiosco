// Runs the kiosk's discovery over the real nsd plugin on an Android device on
// the same LAN as an Izify terminal (PayPOS 1.26+), with the subnet sweep off
// so only mDNS can find it:
//
//   fvm flutter test integration_test/pos_discovery_live_test.dart -d <device>
//
// Proves the multicast permission, the dedicated service type and the IPv4
// taken from the resolved addresses (not the reverse-DNS host name).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:izi_kiosco/data/pos/izify_pos_discovery.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('finds an Izify terminal on the LAN by mDNS alone', (tester) async {
    final discovery = IzifyPosDiscovery(subnetHosts: () async => const []);
    final found = await tester.runAsync(() => discovery.scan(
          timeout: const Duration(seconds: 20),
          stopWhen: (p) => p.address.host != '127.0.0.1',
        ));
    final remote = found!.where((p) => p.address.host != '127.0.0.1').toList();
    // ignore: avoid_print
    print('DISCOVERED: ${[for (final p in found) '${p.name} @ ${p.address} v${p.health.appVersion}']}');
    expect(remote, isNotEmpty, reason: 'no terminal answered over mDNS');
    expect(remote.first.name, startsWith('izify-POS-'));
    expect(RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(remote.first.address.host), isTrue);
  });
}
