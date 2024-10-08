import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'locale_keys/en.dart';

class Localization extends Translations {
  static Locale? get locale => Get.deviceLocale;

  static const fallbackLocale = Locale('en', 'US');

  @override
  Map<String, Map<String, String>> get keys => {
        'en': en,
      };
}
