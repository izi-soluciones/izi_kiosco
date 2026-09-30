import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/data/pos/izify_pos_client.dart';
import 'package:izi_kiosco/data/pos/izify_pos_session.dart';
import 'package:izi_kiosco/data/telemetry/pos_telemetry.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/models/device.dart';

/// What this kiosk and its terminal recorded lately, for a technician in
/// front of the kiosk (or on a remote session) to read or copy.
class PosDiagnosticsDialog extends StatefulWidget {
  final Device? device;

  const PosDiagnosticsDialog({super.key, required this.device});

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

  Map<String, Object?> get _report => {
        'generated': DateTime.now().toIso8601String(),
        'kiosk': {
          'context': Telemetry.instance.context,
          'state': kioskSnapshot(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            state.entries.map((e) => '${e.key}: ${e.value}').join('   '),
            style: const TextStyle(fontSize: 12),
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
