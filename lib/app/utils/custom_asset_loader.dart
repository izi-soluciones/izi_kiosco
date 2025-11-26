import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:izi_kiosco/app/values/env_keys.dart';

class CustomAssetLoader extends RootBundleAssetLoader {
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    var jsonString = await rootBundle.loadString("$path/$locale.json");
    final brandName = dotenv.env[EnvKeys.brandName] ?? "iZi"; // Default to iZi if not found
    jsonString = jsonString.replaceAll("{{brand_name}}", brandName);
    return json.decode(jsonString);
  }
}
