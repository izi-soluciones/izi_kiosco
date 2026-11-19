import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';

/// One line on the POS configuration screen: whether this kiosk is enrolled
/// in iZi's monitoring, under which device id, and a way to enroll again.
class MonitoringStatusTile extends StatelessWidget {
  final MonitoringService? service;

  const MonitoringStatusTile({super.key, this.service});

  @override
  Widget build(BuildContext context) {
    final monitoring = service ?? MonitoringService.instance;
    return ValueListenableBuilder<MonitoringStatus>(
      valueListenable: monitoring.status,
      builder: (context, status, _) {
        final (icon, color) = switch (status.state) {
          MonitoringState.enrolled => (Icons.cloud_done_outlined, Colors.green.shade700),
          MonitoringState.error => (Icons.cloud_off_outlined, context.iziColors.red),
          MonitoringState.pending => (Icons.cloud_sync_outlined, Colors.orange.shade800),
          MonitoringState.stopped => (Icons.cloud_outlined, context.iziColors.darkGrey),
        };
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: IziText.body(
                    color: context.iziColors.dark,
                    fontWeight: FontWeight.normal,
                    maxLines: 2,
                    text: describe(status),
                  ),
                ),
                const SizedBox(width: 8),
                status.enrolling
                    ? const SizedBox(
                        width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton.icon(
                        onPressed: status.state == MonitoringState.stopped
                            ? null
                            : () => monitoring.retryNow(),
                        icon: Icon(Icons.refresh, color: context.iziColors.primary),
                        label: IziText.body(
                          color: context.iziColors.primary,
                          fontWeight: FontWeight.w600,
                          text: LocaleKeys.posConfig_monitoring_retry.tr(),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// `Monitoreo: Enrolado · Dispositivo 65f0…`
  static String describe(MonitoringStatus status) {
    final state = status.enrolling
        ? LocaleKeys.posConfig_monitoring_enrolling.tr()
        : switch (status.state) {
            MonitoringState.enrolled => LocaleKeys.posConfig_monitoring_enrolled.tr(),
            MonitoringState.pending => LocaleKeys.posConfig_monitoring_pending.tr(),
            MonitoringState.error =>
              LocaleKeys.posConfig_monitoring_error.tr(args: [status.lastCause ?? '?']),
            MonitoringState.stopped => LocaleKeys.posConfig_monitoring_stopped.tr(),
          };
    final next = status.nextAttemptAt;
    return [
      '${LocaleKeys.posConfig_monitoring_title.tr()}: $state',
      if (status.deviceId != null)
        LocaleKeys.posConfig_monitoring_device.tr(args: [status.deviceId!]),
      if (status.state == MonitoringState.error && next != null && !status.enrolling)
        LocaleKeys.posConfig_monitoring_nextAttempt
            .tr(args: [DateFormat('HH:mm:ss').format(next.toLocal())]),
    ].join(' · ');
  }
}
