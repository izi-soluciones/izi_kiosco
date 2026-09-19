import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:nsd/nsd.dart' as nsd;

/// An Izify terminal found on the LAN, confirmed by its own `/health`.
class DiscoveredPos {
  final String name;
  final IzifyPosAddress address;
  final IzifyPosHealth health;

  const DiscoveredPos(this.name, this.address, this.health);
}

/// A service seen by mDNS: its instance name and where it answered.
class BrowsedService {
  final String name;
  final String host;
  final int port;

  const BrowsedService(this.name, this.host, this.port);
}

/// Browses one mDNS service type. Swappable so discovery can be tested
/// without a network.
abstract class MdnsBrowser {
  /// Emits the services currently visible for [type]. Closing the
  /// subscription stops browsing.
  Stream<List<BrowsedService>> browse(String type);
}

/// Lists the addresses to sweep when mDNS finds nothing.
typedef SubnetHosts = Future<List<String>> Function();

/// Finds Izify terminals (PayPOS) on the LAN.
///
/// Three sources, merged and each confirmed with `GET /health`:
/// 1. mDNS `_izifypos._tcp`, which only PayPOS 1.26+ advertises.
/// 2. mDNS `_http._tcp` filtered by the `izify-POS-` prefix, for older PayPOS.
///    Started a moment later: Android resolves one service at a time, and the
///    generic type also lists every printer and router on the network.
/// 3. A sweep of the kiosk's own /24 on port 8081, for networks that drop
///    multicast (guest Wi-Fi, "AP isolation", some mesh routers).
class IzifyPosDiscovery {
  static const String serviceType = '_izifypos._tcp';
  static const String legacyServiceType = '_http._tcp';
  static const String namePrefix = 'izify-POS-';
  static const Duration legacyDelay = Duration(milliseconds: 2500);
  static const Duration sweepDelay = Duration(seconds: 4);
  static const Duration sweepProbeTimeout = Duration(milliseconds: 900);
  static const int sweepConcurrency = 32;

  final IzifyPosClient _client;
  final MdnsBrowser? _browser;
  final SubnetHosts _subnetHosts;
  final Duration _probeTimeout;
  final int _sweepPort;

  IzifyPosDiscovery({
    IzifyPosClient? client,
    MdnsBrowser? browser,
    SubnetHosts? subnetHosts,
    Duration probeTimeout = sweepProbeTimeout,
    int sweepPort = IzifyPosAddress.defaultPort,
  })  : _client = client ?? IzifyPosClient(),
        _browser = browser ?? (kIsWeb ? null : NsdMdnsBrowser()),
        _subnetHosts = subnetHosts ?? localSubnetHosts,
        _probeTimeout = probeTimeout,
        _sweepPort = sweepPort;

  /// Emits the growing list of terminals found, until cancelled.
  ///
  /// [sweep] also probes every address of the local /24 when mDNS has not
  /// found anything after [sweepDelay].
  Stream<List<DiscoveredPos>> watch({bool sweep = true}) {
    late final StreamController<List<DiscoveredPos>> out;
    final found = <IzifyPosAddress, DiscoveredPos>{};
    final probing = <IzifyPosAddress>{};
    final subscriptions = <StreamSubscription>[];
    final timers = <Timer>[];
    var closed = false;

    Future<void> confirm(IzifyPosAddress address, {String? advertisedName, Duration? timeout}) async {
      if (closed || found.containsKey(address) || !probing.add(address)) return;
      try {
        final health = await _client.health(address, timeout: timeout ?? IzifyPosClient.healthTimeout);
        if (closed || !health.isIzifyPos) return;
        // One terminal reached two ways (loopback and LAN, or mDNS and the
        // sweep) is listed once, at the address other devices can use.
        final twin = health.name == null
            ? null
            : found.values.where((p) => p.health.name == health.name).firstOrNull;
        if (twin != null) {
          if (address.host == '127.0.0.1') return;
          found.remove(twin.address);
        }
        found[address] = DiscoveredPos(health.name ?? advertisedName ?? 'POS (${address.host})', address, health);
        out.add(List.unmodifiable(found.values));
      } catch (_) {
        // Not a terminal, or it went away: nothing to list.
      } finally {
        probing.remove(address);
      }
    }

    void listen(String type) {
      final browser = _browser;
      if (browser == null || closed) return;
      subscriptions.add(browser.browse(type).listen((services) {
        for (final s in services) {
          if (type == legacyServiceType && !s.name.startsWith(namePrefix)) continue;
          confirm(IzifyPosAddress(s.host, s.port), advertisedName: s.name);
        }
      }, onError: (_) {}));
    }

    // Only when mDNS came back empty: then multicast is likely blocked, and
    // every terminal on the LAN has to be found this way.
    Future<void> sweepSubnet() async {
      if (closed || found.isNotEmpty) return;
      final hosts = await _subnetHosts();
      for (var i = 0; i < hosts.length && !closed; i += sweepConcurrency) {
        final batch = hosts.skip(i).take(sweepConcurrency);
        await Future.wait(batch.map((h) => confirm(IzifyPosAddress(h, _sweepPort), timeout: _probeTimeout)));
      }
    }

    out = StreamController<List<DiscoveredPos>>(
      onListen: () {
        // A PayPOS on this same device (development, all-in-one hardware).
        confirm(const IzifyPosAddress('127.0.0.1'));
        listen(serviceType);
        timers.add(Timer(legacyDelay, () => listen(legacyServiceType)));
        if (sweep) timers.add(Timer(sweepDelay, sweepSubnet));
      },
      onCancel: () async {
        closed = true;
        for (final t in timers) {
          t.cancel();
        }
        for (final s in subscriptions) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }

  /// Looks for terminals for up to [timeout] and returns what it found,
  /// earlier when [stopWhen] accepts one of them.
  Future<List<DiscoveredPos>> scan({
    Duration timeout = const Duration(seconds: 12),
    bool Function(DiscoveredPos)? stopWhen,
  }) async {
    var latest = const <DiscoveredPos>[];
    final done = Completer<void>();
    final sub = watch().listen((list) {
      latest = list;
      if (stopWhen != null && list.any(stopWhen) && !done.isCompleted) done.complete();
    });
    await Future.any([done.future, Future<void>.delayed(timeout)]);
    await sub.cancel();
    return latest;
  }

  /// Every other address of the /24 of each private IPv4 of this device.
  static Future<List<String>> localSubnetHosts() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final hosts = <String>[];
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          hosts.addAll(subnetOf(address.address));
        }
      }
      return hosts;
    } catch (_) {
      return const [];
    }
  }

  /// The other hosts of [ip]'s /24, nearest first; empty unless [ip] is a
  /// private (RFC 1918) address, so a kiosk on a public network never sweeps.
  @visibleForTesting
  static List<String> subnetOf(String ip) {
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null)) return const [];
    final a = parts[0]!, b = parts[1]!, own = parts[3]!;
    final private = a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
    if (!private) return const [];
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
    final others = [for (var i = 1; i < 255; i++) if (i != own) i]
      ..sort((x, y) => (x - own).abs().compareTo((y - own).abs()));
    return [for (final i in others) '$prefix.$i'];
  }
}

/// [MdnsBrowser] over the `nsd` plugin (Android NsdManager / Apple Bonjour).
class NsdMdnsBrowser implements MdnsBrowser {
  @override
  Stream<List<BrowsedService>> browse(String type) {
    nsd.Discovery? discovery;
    late final StreamController<List<BrowsedService>> out;

    void publish() {
      final services = discovery?.services ?? const <nsd.Service>[];
      out.add([
        for (final s in services)
          if (s.name != null && s.port != null && ipOf(s) != null)
            BrowsedService(s.name!, ipOf(s)!, s.port!),
      ]);
    }

    out = StreamController<List<BrowsedService>>(
      onListen: () async {
        try {
          discovery = await nsd.startDiscovery(type);
          if (out.isClosed) {
            await nsd.stopDiscovery(discovery!);
            return;
          }
          discovery!.addListener(publish);
          publish();
        } catch (e) {
          if (!out.isClosed) out.addError(e);
        }
      },
      onCancel: () async {
        final d = discovery;
        discovery = null;
        if (d != null) {
          d.removeListener(publish);
          try {
            await nsd.stopDiscovery(d);
          } catch (_) {}
        }
        await out.close();
      },
    );
    return out.stream;
  }

  /// The IPv4 the service resolved to. On Android `host` is a reverse-DNS
  /// name (e.g. `Android-3.local`) that the kiosk usually cannot resolve;
  /// the address itself is in `addresses`.
  @visibleForTesting
  static String? ipOf(nsd.Service s) {
    final addresses = s.addresses ?? const <InternetAddress>[];
    for (final a in addresses) {
      if (a.type == InternetAddressType.IPv4) return a.address;
    }
    final host = s.host;
    if (host != null && InternetAddress.tryParse(host)?.type == InternetAddressType.IPv4) return host;
    return null;
  }
}
