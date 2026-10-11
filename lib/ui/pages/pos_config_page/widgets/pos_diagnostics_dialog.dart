import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_collector.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_snapshot.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_heartbeat.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_telemetry_sink.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/telemetry/pos_telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/models/device.dart';

/// What this kiosk and its terminal recorded lately, for a technician in
/// front of the kiosk (or on a remote session) to read or copy.
///
/// The "Kiosco" tab shows the same health the kiosk reports to iZi's
/// monitoring ([KioskHealthSnapshot]), and how its heartbeat is doing.
class PosDiagnosticsDialog extends StatefulWidget {
  final Device? device;
  final KioskHealthCollector? collector;

  const PosDiagnosticsDialog({super.key, required this.device, this.collector});

  static Future<void> show(BuildContext context, Device? device) => showDialog(
        context: context,
        builder: (_) => PosDiagnosticsDialog(device: device),
      );

  @override
  State<PosDiagnosticsDialog> createState() => _PosDiagnosticsDialogState();
}

class _PosDiagnosticsDialogState extends State<PosDiagnosticsDialog> {
  final IzifyPosClient _client = IzifyPosClient();
  List<TelemetryEvent> _events = const [];
  KioskHealthSnapshot? _health;
  Map<String, dynamic>? _terminal;
  String? _terminalMessage;
  bool _loadingTerminal = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _events = Telemetry.recent(limit: 300);
      _loadingTerminal = true;
      _terminalMessage = null;
    });
    unawaited(_refreshHealth());
    Map<String, dynamic>? terminal;
    String? message;
    final session = await IzifyPosSession.current(widget.device);
    if (session == null) {
      message = LocaleKeys.posConfig_diagnostics_notPaired.tr();
    } else {
      try {
        terminal = await _client.diagnostics(session.address, token: session.token);
        if (terminal == null) message = LocaleKeys.posConfig_diagnostics_unsupported.tr();
      } on IzifyPosException catch (e) {
        message = LocaleKeys.posConfig_diagnostics_unreachable
            .tr(args: ['${e.message} (${posFailureCause(e)})']);
      }
    }
    if (!mounted) return;
    setState(() {
      _terminal = terminal;
      _terminalMessage = message;
      _loadingTerminal = false;
    });
  }

  Future<void> _refreshHealth() async {
    KioskHealthSnapshot? health;
    try {
      health = await (widget.collector ?? KioskHealthCollector.instance).collect();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _health = health);
  }

  /// The monitoring heartbeat's own state, the counters it has not
  /// delivered yet, and how the event upload is doing.
  Map<String, Object?> get _monitoring {
    final status = MonitoringHeartbeat.instance?.status.value;
    final events = MonitoringTelemetrySink.instance?.status.value;
    return {
      if (_health != null) 'health': _health!.toJson(),
      'counters': KioskCounters.instance.snapshot().toJson(),
      if (status != null)
        'heartbeat': {
          'running': status.running,
          'lastOkAt': status.lastOkAt?.toIso8601String(),
          'nextAt': status.nextAt?.toIso8601String(),
          'lastCause': status.lastCause,
          'failures': status.failures,
          'ackSeq': status.ackSeq,
          'intervalSec': status.interval.inSeconds,
        },
      if (events != null) 'events': events.toJson(),
    };
  }

  Map<String, Object?> get _report => {
        'generated': DateTime.now().toIso8601String(),
        'kiosk': {
          'context': Telemetry.instance.context,
          'state': kioskSnapshot(),
          'monitoring': _monitoring,
          'events': [for (final e in _events) e.toJson()],
        },
        'terminal': _terminal ?? _terminalMessage,
      };

  Future<void> _copy() async {
    await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(_report)));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(LocaleKeys.posConfig_diagnostics_copied.tr())));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: size.width * 0.9,
        height: size.height * 0.85,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: IziText.titleMedium(
                        color: context.iziColors.dark,
                        text: LocaleKeys.posConfig_diagnostics_title.tr(),
                      ),
                    ),
                    IconButton(
                      tooltip: LocaleKeys.posConfig_diagnostics_refresh.tr(),
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      tooltip: LocaleKeys.posConfig_diagnostics_copy.tr(),
                      onPressed: _copy,
                      icon: const Icon(Icons.copy),
                    ),
                    IconButton(
                      tooltip: LocaleKeys.posConfig_diagnostics_close.tr(),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              TabBar(tabs: [
                Tab(text: LocaleKeys.posConfig_diagnostics_kioskTab.tr()),
                Tab(text: LocaleKeys.posConfig_diagnostics_terminalTab.tr()),
              ]),
              Expanded(
                child: TabBarView(children: [
                  _kioskTab(context),
                  _terminalTab(context),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kioskTab(BuildContext context) {
    final state = {...Telemetry.instance.context, ...kioskSnapshot()};
    final health = _health;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SelectableText(
            state.entries.map((e) => '${e.key}: ${e.value}').join('   '),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ValueListenableBuilder<HeartbeatStatus>(
            valueListenable: MonitoringHeartbeat.instance?.status ??
                ValueNotifier(HeartbeatStatus.stopped),
            builder: (context, status, _) => SelectableText(
              describeHeartbeat(status),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (health != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(health.toJson()),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              maxLines: 12,
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: _events.isEmpty
              ? Center(child: Text(LocaleKeys.posConfig_diagnostics_empty.tr()))
              : _EventList(rows: [
                  for (final e in _events)
                    _Row(e.ts, e.level.name, e.summary),
                ]),
        ),
      ],
    );
  }

  Widget _terminalTab(BuildContext context) {
    if (_loadingTerminal) return const Center(child: CircularProgressIndicator());
    final terminal = _terminal;
    if (terminal == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_terminalMessage ?? '', textAlign: TextAlign.center),
        ),
      );
    }
    final events = terminal['events'] is List ? terminal['events'] as List : const [];
    final state = Map<String, dynamic>.of(terminal)..remove('events');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(state),
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            maxLines: 12,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _EventList(rows: [
            for (final e in events.whereType<Map>())
              _Row(
                DateTime.tryParse('${e['ts']}')?.toLocal(),
                '${e['level'] ?? ''}',
                [
                  e['type'],
                  e['chargeId'],
                  e['reference'],
                  if (e['data'] is Map)
                    (e['data'] as Map).entries.map((d) => '${d.key}=${d.value}').join(' '),
                ].whereType<Object>().where((v) => '$v'.isNotEmpty).join('  '),
              ),
          ]),
        ),
      ],
    );
  }
}

/// One line on how the monitoring heartbeat is doing.
String describeHeartbeat(HeartbeatStatus status) {
  final time = DateFormat('HH:mm:ss');
  String at(DateTime? t) => t == null ? '-' : time.format(t.toLocal());
  if (!status.running) return LocaleKeys.posConfig_diagnostics_heartbeatStopped.tr();
  if (status.failures > 0) {
    return LocaleKeys.posConfig_diagnostics_heartbeatFailing
        .tr(args: [status.lastCause ?? '?', '${status.failures}', at(status.nextAt)]);
  }
  if (status.lastOkAt == null) {
    return LocaleKeys.posConfig_diagnostics_heartbeatPending.tr(args: [at(status.nextAt)]);
  }
  return LocaleKeys.posConfig_diagnostics_heartbeatOk
      .tr(args: [at(status.lastOkAt), at(status.nextAt)]);
}

class _Row {
  final DateTime? ts;
  final String level;
  final String text;

  const _Row(this.ts, this.level, this.text);
}

class _EventList extends StatelessWidget {
  final List<_Row> rows;

  const _EventList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('dd/MM HH:mm:ss');
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final row = rows[i];
        // The terminal sends its levels in capitals (ERROR, WARNING).
        final color = switch (row.level.toLowerCase()) {
          'error' => context.iziColors.red,
          'warning' || 'warn' => Colors.orange.shade800,
          _ => context.iziColors.dark,
        };
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SelectableText(
            '${row.ts == null ? '' : time.format(row.ts!.toLocal())}  ${row.text}',
            style: TextStyle(fontSize: 12, color: color),
          ),
        );
      },
    );
  }
}
