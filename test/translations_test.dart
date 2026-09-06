import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/app/utils/kiosk_locale.dart';

Map<String, String> flatten(Map<String, dynamic> node, [String prefix = '']) {
  var out = <String, String>{};
  node.forEach((key, value) {
    var path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      out.addAll(flatten(value, path));
    } else {
      out[path] = value.toString();
    }
  });
  return out;
}

Map<String, String> load(String languageCode) {
  var file = File('assets/translations/$languageCode.json');
  expect(file.existsSync(), isTrue,
      reason: 'falta assets/translations/$languageCode.json');
  return flatten(json.decode(file.readAsStringSync()) as Map<String, dynamic>);
}

void main() {
  test('cada idioma soportado tiene su archivo de traducciones', () {
    for (var locale in KioskLocale.supported) {
      expect(load(locale.languageCode), isNotEmpty);
    }
  });

  test('es y en tienen exactamente las mismas claves', () {
    var es = load('es');
    var en = load('en');
    expect(en.keys.toSet().difference(es.keys.toSet()), isEmpty,
        reason: 'claves que sobran en en.json');
    expect(es.keys.toSet().difference(en.keys.toSet()), isEmpty,
        reason: 'claves sin traducir en en.json');
  });

  test('los placeholders coinciden entre idiomas', () {
    var es = load('es');
    var en = load('en');
    for (var key in es.keys) {
      expect('{}'.allMatches(en[key]!).length,
          '{}'.allMatches(es[key]!).length,
          reason: 'placeholders {} descuadrados en $key');
      expect(en[key]!.contains('{{brand_name}}'),
          es[key]!.contains('{{brand_name}}'),
          reason: '{{brand_name}} descuadrado en $key');
    }
  });

  test('ninguna traduccion quedo vacia si el original tiene texto', () {
    var es = load('es');
    var en = load('en');
    for (var key in es.keys) {
      if (es[key]!.trim().isNotEmpty) {
        expect(en[key]!.trim(), isNotEmpty, reason: '$key sin traducir');
      }
    }
  });
}
