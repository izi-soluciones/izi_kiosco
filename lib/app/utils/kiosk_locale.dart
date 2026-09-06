import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:izi_kiosco/domain/models/device.dart';

class KioskLocale {
  KioskLocale._();

  static const Locale es = Locale('es');
  static const Locale en = Locale('en');

  static const List<Locale> supported = [es, en];

  static const Map<String, String> names = {
    'es': 'Español',
    'en': 'English',
  };

  static String nameOf(Locale locale) =>
      names[locale.languageCode] ?? locale.languageCode.toUpperCase();

  static Locale? parse(String? value) {
    if (value == null) {
      return null;
    }
    var code = value.trim().toLowerCase().split(RegExp(r'[_-]')).first;
    for (var locale in supported) {
      if (locale.languageCode == code) {
        return locale;
      }
    }
    return null;
  }

  static Locale defaultFor(ConfigDevice? config) {
    return parse(config?.idiomaDefecto) ?? es;
  }

  static bool canSwitch(ConfigDevice? config) {
    return config?.permiteCambioIdioma == true;
  }

  static Future<void> apply(BuildContext context, Locale locale) async {
    if (context.locale == locale) {
      return;
    }
    await context.setLocale(locale);
  }

  // Cada comensal empieza en el idioma del dispositivo: si no se reinicia al
  // volver a la bienvenida, el siguiente hereda el que dejó el anterior.
  static Future<void> reset(BuildContext context, ConfigDevice? config) {
    return apply(context, defaultFor(config));
  }
}
