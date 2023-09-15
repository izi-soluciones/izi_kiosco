import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart'
if (dart.library.html) 'package:flutter_web_plugins/url_strategy.dart' as web_url;
import 'package:izi_kiosco/app/my_app.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
void main()async {
  if(kIsWeb){
    web_url.usePathUrlStrategy();
  }
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: AssetsKeys.envProd);
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
        supportedLocales: const [Locale('es')],
        path: AssetsKeys.translations,
        fallbackLocale: const Locale('es'),
        child: MyApp()
    ),
  );
}
