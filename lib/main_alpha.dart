import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart'
if (dart.library.html) 'package:flutter_web_plugins/url_strategy.dart' as web_url;
import 'package:izi_kiosco/app/my_app.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/firebase_options.dart';
void main()async {
  if(kIsWeb){
    web_url.usePathUrlStrategy();
  }
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: AssetsKeys.envAlpha);
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
    return true;
  };
  runApp(
    EasyLocalization(
        supportedLocales: const [Locale('es')],
        path: AssetsKeys.translations,
        fallbackLocale: const Locale('es'),
        child: MyApp()
    ),
  );
}
