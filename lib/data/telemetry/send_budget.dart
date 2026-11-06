/// Caps what one kiosk sends to Sentry, so the free plan lasts the month.
///
/// Sentry drops everything past the monthly quota for every kiosk, so one
/// terminal switched off in one store must not use it up:
/// - issues (Sentry errors, 5,000 a month shared by all the apps): at most
///   [maxIssuesPerDay] a day, and [maxPerIssuePerDay] of the same kind;
/// - logs: at most [maxLogsPerTypePerHour] of each event type an hour.
/// What is not sent is still kept on the device.
class SendBudget {
  final int maxIssuesPerDay;
  final int maxPerIssuePerDay;
  final int maxLogsPerTypePerHour;
  final DateTime Function() _now;

  SendBudget({
    this.maxIssuesPerDay = 20,
    this.maxPerIssuePerDay = 3,
    this.maxLogsPerTypePerHour = 60,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  String? _day;
  int _issuesToday = 0;
  final Map<String, int> _perIssue = {};

  String? _hour;
  final Map<String, int> _perType = {};

  bool allowIssue(String key) {
    final now = _now();
    final day = '${now.year}-${now.month}-${now.day}';
    if (day != _day) {
      _day = day;
      _issuesToday = 0;
      _perIssue.clear();
    }
    final count = _perIssue[key] ?? 0;
    if (_issuesToday >= maxIssuesPerDay || count >= maxPerIssuePerDay) {
      return false;
    }
    _issuesToday++;
    _perIssue[key] = count + 1;
    return true;
  }

  bool allowLog(String type) {
    final now = _now();
    final hour = '${now.year}-${now.month}-${now.day}-${now.hour}';
    if (hour != _hour) {
      _hour = hour;
      _perType.clear();
    }
    final count = _perType[type] ?? 0;
    if (count >= maxLogsPerTypePerHour) return false;
    _perType[type] = count + 1;
    return true;
  }
}
