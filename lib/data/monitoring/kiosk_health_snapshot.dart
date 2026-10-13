import 'package:izi_kiosco/data/monitoring/pos_link_health.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/telemetry/telemetry_redactor.dart';

/// Which card terminal integration the kiosk charges with (`state.pos.provider`).
class PosProvider {
  const PosProvider._();

  static const String izify = 'izify';
  static const String atc = 'atc';
  static const String linkser = 'linkser';
  static const String none = 'none';
}

/// The values of `state.pos.status`.
class PosLinkStatus {
  const PosLinkStatus._();

  static const String ok = 'ok';
  static const String degraded = 'degraded';
  static const String down = 'down';
  static const String unpaired = 'unpaired';
  static const String notConfigured = 'not_configured';

  /// Failures in a row that make the link `down`.
  static const int downAfterFailures = 3;

  /// The rules of contracts §4.1, in order:
  /// - `not_configured`: the kiosk charges with no terminal;
  /// - `unpaired`: it should, but holds no pairing with it;
  /// - `down`: [downAfterFailures] checks or more failed in a row;
  /// - `ok`: the last check got an answer, the terminal can charge and no
  ///   check failed within [PosLinkHealth.degradedWindow];
  /// - `degraded`: anything else — it answered but cannot charge, it failed
  ///   lately, the last one or two checks failed, or nothing was checked yet.
  static String of(
      {required String provider, required bool paired, required PosLinkView link}) {
    if (provider == PosProvider.none) return notConfigured;
    if (!paired) return unpaired;
    if (link.consecutiveFailures >= downAfterFailures) return down;
    if (link.lastOk == true && link.notReadyReason == null && !link.failedRecently) return ok;
    return degraded;
  }
}

/// `state.pos` of the kiosk heartbeat (contracts §4.1).
class PosHealthSnapshot {
  final String provider;
  final String status;
  final String? address;
  final String? name;
  final DateTime? lastOkAt;
  final int? latencyMsP50;
  final int consecutiveFailures;
  final String? lastCause;
  final bool ready;
  final String? notReadyReason;

  /// The Izify POS's own report; null for ATC and Linkser, which say
  /// nothing about themselves.
  final IzifyPosHealth? terminal;

  const PosHealthSnapshot(
      {required this.provider,
      required this.status,
      this.address,
      this.name,
      this.lastOkAt,
      this.latencyMsP50,
      this.consecutiveFailures = 0,
      this.lastCause,
      this.ready = false,
      this.notReadyReason,
      this.terminal});

  /// What the health loops know about the terminal of [provider].
  ///
  /// [paired]: the kiosk holds a pairing (Izify POS; ATC and Linkser have
  /// none to lose). [problem] is what the POS configuration screen shows
  /// when the terminal did not answer. [terminal] is the last report of the
  /// Izify POS when [link] has none.
  static PosHealthSnapshot build({
    required String provider,
    required bool paired,
    required PosLinkView link,
    String? address,
    String? name,
    String? problem,
    IzifyPosHealth? terminal,
  }) {
    if (provider == PosProvider.none) {
      return const PosHealthSnapshot(
          provider: PosProvider.none, status: PosLinkStatus.notConfigured);
    }
    final report = provider == PosProvider.izify ? (link.terminal ?? terminal) : null;
    // A terminal that says it is not paired with anyone has no pairing to use.
    final hasPairing = paired && report?.paired != false;
    final status = PosLinkStatus.of(provider: provider, paired: hasPairing, link: link);
    final answered = link.lastOk == true;
    final notReadyReason = answered
        ? link.notReadyReason
        : (problem ?? (link.lastOk == false ? 'El datáfono no responde.' : null));
    return PosHealthSnapshot(
      provider: provider,
      status: status,
      address: address ?? link.address,
      name: provider == PosProvider.izify ? (report?.name ?? name) : null,
      lastOkAt: link.lastOkAt,
      latencyMsP50: link.latencyMsP50,
      consecutiveFailures: link.consecutiveFailures,
      lastCause: answered ? null : link.lastCause,
      ready: hasPairing && answered && link.notReadyReason == null,
      notReadyReason: notReadyReason,
      terminal: report,
    );
  }

  Map<String, Object?> toJson() => {
        'provider': provider,
        'status': status,
        'address': address,
        'name': name,
        'lastOkAt': lastOkAt?.toUtc().toIso8601String(),
        'latencyMsP50': latencyMsP50,
        'consecutiveFailures': consecutiveFailures,
        'lastCause': lastCause,
        'ready': ready,
        'notReadyReason': notReadyReason,
        if (terminal != null) 'terminal': terminalJson(terminal!),
      };

  /// `state.pos.terminal`: what the Izify POS says about itself.
  static Map<String, Object?> terminalJson(IzifyPosHealth health) => {
        'battery': health.batteryLevel,
        'hasPaper': health.hasPaper,
        'isOnline': health.isOnline,
        'ecopayConnected': health.ecopayConnected,
        'appVersion': health.appVersion,
        'ecopayVersion': health.ecopayVersion,
        'terminalType': health.terminalType,
      };
}

/// The kiosk's `state` in its monitoring heartbeat (contracts §4.1), also
/// shown on the "Kiosco" tab of the diagnostics dialog.
class KioskHealthSnapshot {
  final DateTime takenAt;

  /// The route template on screen (`/home`, `/payment/:id`).
  final String? screen;
  final String mode;
  final bool? online;

  /// `visible` or `hidden`.
  final String? visibility;
  final bool chargeInProgress;
  final PosHealthSnapshot pos;

  /// Card charges in the local transactions list that someone has to look
  /// at: unconfirmed, cut off by a reload, or charged and not registered.
  final int pendingCardErrors;

  /// Events not yet uploaded (KIO-03); null while the kiosk does not upload.
  final int? telemetryBacklog;

  /// `state.printer` (KIO-04) and `state.agent` (KIO-05); left out while
  /// unknown.
  final Map<String, Object?>? printer;
  final Map<String, Object?>? agent;

  const KioskHealthSnapshot(
      {required this.takenAt,
      required this.screen,
      required this.mode,
      required this.online,
      required this.visibility,
      required this.chargeInProgress,
      required this.pos,
      required this.pendingCardErrors,
      this.telemetryBacklog,
      this.printer,
      this.agent});

  /// Passed through [TelemetryRedactor] like everything the kiosk sends.
  Map<String, Object?> toJson() => TelemetryRedactor.redact({
        'screen': screen,
        'mode': mode,
        'online': online,
        'visibility': visibility,
        'chargeInProgress': chargeInProgress,
        'pos': pos.toJson(),
        if (printer != null) 'printer': printer,
        'pendingCardErrors': pendingCardErrors,
        'telemetryBacklog': telemetryBacklog,
        if (agent != null) 'agent': agent,
      });
}
