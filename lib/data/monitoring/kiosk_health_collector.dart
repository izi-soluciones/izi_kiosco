import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_activity.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_snapshot.dart';
import 'package:izi_kiosco/data/monitoring/pos_link_health.dart';
import 'package:izi_kiosco/data/pos/card_charge_recovery.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/telemetry/platform_signals.dart';
import 'package:izi_kiosco/data/utils/token_utils.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/pos_config/pos_config_bloc.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
import 'package:izi_kiosco/domain/models/device.dart';

/// A section of the heartbeat `state` another part of the kiosk fills, or
/// null while it has nothing to say.
typedef KioskStateSection = Map<String, Object?>? Function();

/// Gathers the [KioskHealthSnapshot] from where the kiosk already keeps it:
/// the login ([AuthBloc]: device and its terminal settings), the POS
/// configuration ([PosConfigBloc]: pairing and the terminal's last report),
/// the health loops ([PosLinkHealth]), the screen and payment page
/// ([KioskActivity]) and the local transactions list.
///
/// Reads only: it never calls the terminal or the network.
class KioskHealthCollector {
  AuthState Function()? _auth;
  PosConfigState Function()? _posConfig;

  final KioskActivity Function() _activity;
  final PosLinkHealth Function() _link;
  final Future<IzifyPosSession?> Function(Device? device) _session;
  final Future<IzifyPosAddress?> Function(Device? device) _configuredAddress;
  final Future<String?> Function() _posName;
  final Future<int> Function() _pendingCardErrors;
  final String? Function() _visibility;
  final bool? Function() _online;
  final DateTime Function() _now;

  /// `state.printer`, filled by the printing (KIO-04).
  KioskStateSection printer = _nothing;

  /// `state.agent`, filled by the PC agent link (KIO-05).
  KioskStateSection agent = _nothing;

  /// Events still to upload (`state.telemetryBacklog`), filled by the event
  /// upload (KIO-03).
  int? Function() telemetryBacklog = _unknown;

  KioskHealthCollector({
    KioskActivity Function()? activity,
    PosLinkHealth Function()? link,
    Future<IzifyPosSession?> Function(Device? device)? session,
    Future<IzifyPosAddress?> Function(Device? device)? configuredAddress,
    Future<String?> Function()? posName,
    Future<int> Function()? pendingCardErrors,
    String? Function()? visibility,
    bool? Function()? online,
    DateTime Function()? now,
  })  : _activity = activity ?? (() => KioskActivity.instance),
        _link = link ?? (() => PosLinkHealth.instance),
        _session = session ?? IzifyPosSession.current,
        _configuredAddress = configuredAddress ?? IzifyPosSession.configuredAddress,
        _posName = posName ?? TokenUtils.getPosName,
        _pendingCardErrors = pendingCardErrors ?? countPendingCardErrors,
        _visibility = visibility ?? currentPageVisibility,
        _online = online ?? currentOnline,
        _now = now ?? DateTime.now;

  static KioskHealthCollector _instance = KioskHealthCollector();

  static KioskHealthCollector get instance => _instance;

  /// Replaces the global instance (in tests).
  static void install(KioskHealthCollector collector) => _instance = collector;

  /// Where the login and the POS configuration live (set up by `MyApp`).
  void attach({required AuthBloc auth, PosConfigBloc? posConfig}) {
    _auth = () => auth.state;
    if (posConfig != null) _posConfig = () => posConfig.state;
  }

  /// For tests: the states themselves.
  void attachStates(
      {required AuthState Function() auth, PosConfigState Function()? posConfig}) {
    _auth = auth;
    _posConfig = posConfig;
  }

  /// The kiosk now. Never throws: what cannot be read is left unknown.
  Future<KioskHealthSnapshot> collect() async {
    final activity = _activity();
    final link = _safe(() => _link().view(), PosLinkView.none);
    final auth = _safe(() => _auth?.call(), null);
    final posConfig = _safe(() => _posConfig?.call(), null);
    final device = auth?.currentDevice;

    var pos = const PosHealthSnapshot(
        provider: PosProvider.none, status: PosLinkStatus.notConfigured);
    try {
      pos = await _pos(device, link, posConfig);
    } catch (_) {}

    var pendingCardErrors = 0;
    try {
      pendingCardErrors = await _pendingCardErrors();
    } catch (_) {}

    return KioskHealthSnapshot(
      takenAt: _now(),
      screen: activity.screen,
      mode: activity.mode,
      online: _safe(_online, null),
      visibility: _safe(_visibility, null),
      chargeInProgress: activity.chargeInProgress,
      pos: pos,
      pendingCardErrors: pendingCardErrors,
      telemetryBacklog: _safe(telemetryBacklog, null),
      printer: _safe(printer, null),
      agent: _safe(agent, null),
    );
  }

  Future<PosHealthSnapshot> _pos(
      Device? device, PosLinkView link, PosConfigState? posConfig) async {
    // Same order as the payment page: an Izify POS first, then Linkser, then ATC.
    final session = await _session(device);
    final izifyAddress = session?.address ?? await _configuredAddress(device);
    if (izifyAddress != null) {
      return PosHealthSnapshot.build(
        provider: PosProvider.izify,
        paired: session != null,
        link: link,
        address: izifyAddress.hostPort,
        name: await _posName(),
        problem: posConfig?.notReadyReason,
        terminal: posConfig?.health,
      );
    }
    final config = device?.config;
    final linkser = _present(config?.ipLinkser);
    if (linkser != null) {
      return PosHealthSnapshot.build(
          provider: PosProvider.linkser, paired: true, link: link, address: linkser);
    }
    final atc = _present(config?.ipAtc);
    if (atc != null) {
      return PosHealthSnapshot.build(
          provider: PosProvider.atc, paired: true, link: link, address: atc);
    }
    return PosHealthSnapshot.build(provider: PosProvider.none, paired: false, link: link);
  }

  /// The rows of the transactions list that need a person (see
  /// [isPendingCardError]).
  static Future<int> countPendingCardErrors() async {
    var count = 0;
    for (final row in await LocalStorageCardErrors.getErrors()) {
      try {
        final json = jsonDecode(row);
        if (json is Map && isPendingCardError(CardPayment.fromJsonStorage(json))) count++;
      } catch (_) {
        // Unreadable rows are not counted.
      }
    }
    return count;
  }

  /// An unconfirmed charge (the card may have been charged), one a reload
  /// cut off that no page is waiting for, or one charged and not registered
  /// in iZi. Declined and registered charges need nobody.
  static bool isPendingCardError(CardPayment cp) {
    if (cp.inProgress) return !CardChargeRecovery.active.contains(cp.reference);
    return cp.chargedNotRegistered || cp.retryStatus == CardPaymentStatus.pending;
  }

  /// `visible` / `hidden`: the page's visibility on web, the app's
  /// lifecycle elsewhere.
  static String? currentPageVisibility() {
    final web = currentVisibility();
    if (web != null) return web == 'visible' ? 'visible' : 'hidden';
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle == null) return null;
    return lifecycle == AppLifecycleState.resumed ? 'visible' : 'hidden';
  }

  static String? _present(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static T _safe<T>(T Function() read, T fallback) {
    try {
      return read();
    } catch (_) {
      return fallback;
    }
  }

  static Map<String, Object?>? _nothing() => null;

  static int? _unknown() => null;
}
