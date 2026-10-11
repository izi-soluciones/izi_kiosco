import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart'
if (dart.library.html) 'package:flutter_web_plugins/url_strategy.dart' as web_url;
import 'package:izi_kiosco/app/my_app.dart';
import 'package:izi_kiosco/app/utils/custom_asset_loader.dart';
import 'package:izi_kiosco/app/utils/kiosk_locale.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/data/monitoring/agent_link.dart';
import 'package:izi_kiosco/data/monitoring/command_result_outbox.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_commands.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_counters.dart';
import 'package:izi_kiosco/data/monitoring/kiosk_health_collector.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_commands.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_heartbeat.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_service.dart';
import 'package:izi_kiosco/data/monitoring/terminal_enrollment.dart';
import 'package:izi_kiosco/data/telemetry/kiosk_telemetry.dart';
import 'package:izi_kiosco/firebase_options.dart';

// El flavor se inyecta en build time: --dart-define=FLAVOR=stg
// Valores válidos: dev | local | stg | alpha | beta | prod | izify | pcbba
const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'local');

void main() async {
  if (kIsWeb) {
    web_url.usePathUrlStrategy();
  }
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await dotenv.load(fileName: AssetsKeys.envForFlavor(_flavor));
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
    webProvider: ReCaptchaV3Provider(dotenv.env["CAPTCHA_KEY"] ?? ""),
  );

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
    return true;
  };

  // Enrolls the kiosk in iZi's monitoring once it is logged in (MyApp), and
  // reports its health from then on.
  final monitoring = MonitoringService(flavor: _flavor);
  MonitoringService.install(monitoring);
  final counters = KioskCounters(store: PrefsCountersStore());
  KioskCounters.install(counters);
  // What the previous session left unsent (a reload, a crash, an outage)
  // comes back before anything is counted. Bounded: never holds up the start.
  await counters.restore().timeout(const Duration(seconds: 2), onTimeout: () {});
  // Remote commands from the support console, run between sales.
  final commands = KioskCommands(enrollment: monitoring);
  KioskCommands.install(commands);
  final runner = MonitoringCommandRunner(
      outbox: CommandResultOutbox(enrollment: monitoring), handlers: commands.handlers);
  MonitoringCommandRunner.install(runner);
  MonitoringHeartbeat.install(
      MonitoringHeartbeat(enrollment: monitoring, commands: runner, flavor: _flavor));
  // The terminal and the PC agent join the monitoring on their own, with a
  // code this kiosk asks for (the agent only exists next to the web kiosk).
  TerminalEnrollment.install(TerminalEnrollment(enrollment: monitoring));
  if (kIsWeb) {
    final agent = AgentLink(enrollment: monitoring);
    AgentLink.install(agent);
    KioskHealthCollector.instance.agent = agent.stateSection;
  }

  // Sentry wraps the error handler set above, so Crashlytics still gets its
  // errors on mobile.
  await KioskTelemetry.run(flavor: _flavor, appRunner: () => runApp(
    EasyLocalization(
      supportedLocales: KioskLocale.supported,
      path: AssetsKeys.translations,
      assetLoader: CustomAssetLoader(),
      fallbackLocale: KioskLocale.es,
      startLocale: KioskLocale.es,
      // La fuente de verdad es device.config.idiomaDefecto, que se aplica al
      // entrar a la bienvenida. Persistir la elección del comensal anterior la
      // pisaría en el siguiente arranque.
      saveLocale: false,
      child: MyApp(),
    ),
  ));
}
