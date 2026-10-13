/// A one-time code the monitoring service issued for this kiosk's appliance
/// (contracts §3.2), for its terminal or its PC agent to enroll with.
///
/// It is as good as a password for half an hour: never log it.
class MonitoringEnrollmentCode {
  /// The pieces a kiosk may ask a code for.
  static const String forTerminal = 'terminal';
  static const String forAgent = 'agent';

  final String code;
  final DateTime? expiresAt;

  const MonitoringEnrollmentCode({required this.code, this.expiresAt});

  /// Null without a code.
  static MonitoringEnrollmentCode? tryParse(Object? json) {
    if (json is! Map) return null;
    final code = json['code'];
    if (code is! String || code.trim().isEmpty) return null;
    return MonitoringEnrollmentCode(
        code: code.trim(), expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}'));
  }
}

/// What the monitoring service answers a diagnostics upload (contracts §12.5).
class MonitoringDiagnosticReceipt {
  final String? id;
  final int? size;

  const MonitoringDiagnosticReceipt({this.id, this.size});

  static MonitoringDiagnosticReceipt parse(Object? json) {
    if (json is! Map) return const MonitoringDiagnosticReceipt();
    final id = json['id'];
    final size = json['size'];
    return MonitoringDiagnosticReceipt(
        id: id is String && id.isNotEmpty ? id : null,
        size: size is num && size.isFinite ? size.toInt() : null);
  }
}
