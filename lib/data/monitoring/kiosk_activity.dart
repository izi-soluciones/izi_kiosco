import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/data/pos/card_charge_recovery.dart';

/// What the kiosk is doing right now, for the monitoring heartbeat
/// (contracts §4.1 `screen`, `mode`, `chargeInProgress`).
///
/// The router reports the screen, the payment page whether a card charge is
/// on its way, the login whether it failed. Remote commands (KIO-05) read
/// [busy] before doing anything that could interrupt a sale.
class KioskActivity {
  /// The route template on screen (`/home`, `/payment/:id`): never the
  /// concrete path, which carries ids.
  String? _screen;
  bool _authError = false;
  bool _paymentBusy = false;

  static KioskActivity _instance = KioskActivity();

  static KioskActivity get instance => _instance;

  /// Replaces the global instance (in tests).
  static void install(KioskActivity activity) => _instance = activity;

  String? get screen => _screen;

  void screenChanged(String? screen) {
    final value = screen?.trim();
    _screen = value == null || value.isEmpty ? null : value;
  }

  /// The login could not load the kiosk (the "reload" screen is up).
  void authErrorChanged(bool error) => _authError = error;

  /// The payment page started or finished waiting for a card charge.
  void paymentBusyChanged(bool busy) => _paymentBusy = busy;

  /// A card charge is on its way: the payment page is waiting for the
  /// terminal, or a charge cut off by a reload is still unsettled.
  bool get chargeInProgress => _paymentBusy || CardChargeRecovery.active.isNotEmpty;

  String get mode =>
      modeOf(screen: _screen, authError: _authError, chargeInProgress: chargeInProgress);

  /// A customer is in the middle of something: paying, or a charge is on
  /// its way.
  bool get busy => chargeInProgress || mode == KioskMode.paying;

  /// `idle|ordering|paying|config|login|error` for [screen].
  static String modeOf(
      {required String? screen, bool authError = false, bool chargeInProgress = false}) {
    if (authError) return KioskMode.error;
    if (chargeInProgress) return KioskMode.paying;
    switch (screen) {
      case RoutesKeys.paymentLink:
        return KioskMode.paying;
      case RoutesKeys.loginLink:
      case RoutesKeys.configBusinessLink:
      case RoutesKeys.kioskListLink:
      case RoutesKeys.kioskNewLink:
        return KioskMode.login;
      case RoutesKeys.posConfigLink:
      case RoutesKeys.configurationPosLink:
      case RoutesKeys.errorPaymentsLik:
        return KioskMode.config;
      case RoutesKeys.makeOrderLink:
      case RoutesKeys.makeOrderRetailLink:
      case RoutesKeys.orderLink:
      case RoutesKeys.tablesLink:
      case RoutesKeys.userInformationLink:
      case RoutesKeys.symbioticLink:
        return KioskMode.ordering;
    }
    return KioskMode.idle;
  }
}

/// The values of `state.mode`.
class KioskMode {
  const KioskMode._();

  static const String idle = 'idle';
  static const String ordering = 'ordering';
  static const String paying = 'paying';
  static const String config = 'config';
  static const String login = 'login';
  static const String error = 'error';
}
