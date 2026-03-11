import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Global font service to manage app-wide font family based on locale
class FontService extends GetxService {
  static FontService get to => Get.find<FontService>();
  
  /// English font family
  static const String englishFont = 'Roboto';
  
  /// Persian font family
  static const String persianFont = 'Vazir';
  
  /// Current font family based on locale
  String get currentFont {
    final locale = Get.locale;
    if (locale?.languageCode == 'fa') {
      return persianFont;
    }
    return englishFont;
  }
  
  /// Get font family for a specific locale
  static String getFontForLocale(Locale? locale) {
    if (locale?.languageCode == 'fa') {
      return persianFont;
    }
    return englishFont;
  }
}
