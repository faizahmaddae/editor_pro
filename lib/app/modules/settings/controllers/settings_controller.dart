import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';

class SettingsController extends GetxController {
  final _storage = GetStorage();
  
  // Keys for storage
  static const String _languageKey = 'language';
  static const String _exportQualityKey = 'export_quality';
  static const String _saveToGalleryKey = 'save_to_gallery';
  static const String _showGridKey = 'show_grid';
  static const String _editorDarkModeKey = 'editor_dark_mode';
  static const String _enableZoomKey = 'enable_zoom';
  static const String _outputFormatKey = 'output_format';
  static const String _maxOutputSizeKey = 'max_output_size';
  static const String _backgroundGenerationKey = 'background_generation';
  static const String _isolateGenerationKey = 'isolate_generation';
  
  // Observable states
  final currentLocale = const Locale('en', 'US').obs;
  final exportQuality = 90.obs;
  final saveToGallery = true.obs;
  final showGrid = true.obs;
  final isDarkMode = true.obs;
  final isEditorDarkMode = true.obs;
  final enableZoom = false.obs;
  
  // Image Generation Settings
  final outputFormat = 'jpg'.obs;
  final maxOutputSize = 2000.obs;
  final enableBackgroundGeneration = true.obs;
  final enableIsolateGeneration = true.obs;
  
  // App info (loaded dynamically)
  final appVersion = ''.obs;
  final appName = ''.obs;
  
  // Available languages
  List<Map<String, dynamic>> get languages => [
    {'name': LocaleKeys.settings_lang_english.tr, 'locale': const Locale('en', 'US'), 'nativeName': 'English'},
    {'name': LocaleKeys.settings_lang_persian.tr, 'locale': const Locale('fa', 'IR'), 'nativeName': 'فارسی'},
  ];
  
  // Quality values (labels are resolved via locale keys in the view)
  static const qualityValues = [60, 75, 90, 100];
  
  // Format values
  static const formatValues = ['jpg', 'png'];
  
  // Size values
  static const sizeValues = [1000, 2000, 4000, 0];

  /// Locale key for quality label by value
  String qualityLabelKey(int value) {
    switch (value) {
      case 60:  return LocaleKeys.settings_quality_low.tr;
      case 75:  return LocaleKeys.settings_quality_medium.tr;
      case 90:  return LocaleKeys.settings_quality_high.tr;
      case 100: return LocaleKeys.settings_quality_max.tr;
      default:  return '$value%';
    }
  }

  /// Locale key for format label/description by value
  String formatLabel(String value) {
    return value == 'png'
        ? LocaleKeys.settings_format_png.tr
        : LocaleKeys.settings_format_jpeg.tr;
  }

  String formatDesc(String value) {
    return value == 'png'
        ? LocaleKeys.settings_format_png_desc.tr
        : LocaleKeys.settings_format_jpeg_desc.tr;
  }

  /// Locale key for size label/description by value
  String sizeLabel(int value) {
    switch (value) {
      case 1000: return LocaleKeys.settings_size_small.tr;
      case 2000: return LocaleKeys.settings_size_balanced.tr;
      case 4000: return LocaleKeys.settings_size_high.tr;
      case 0:    return LocaleKeys.settings_size_original.tr;
      default:   return '${value}px';
    }
  }

  String sizeDesc(int value) {
    switch (value) {
      case 1000: return LocaleKeys.settings_size_small_desc.tr;
      case 2000: return LocaleKeys.settings_size_balanced_desc.tr;
      case 4000: return LocaleKeys.settings_size_high_desc.tr;
      case 0:    return LocaleKeys.settings_size_original_desc.tr;
      default:   return '';
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appName.value = info.appName;
      appVersion.value = '${info.version} (${info.buildNumber})';
    } catch (_) {
      // Native plugin not registered yet (e.g. after hot restart).
      // Falls back to defaults shown in the view.
    }
  }

  void _loadSettings() {
    // Load language
    final savedLang = _storage.read<String>(_languageKey);
    if (savedLang != null) {
      if (savedLang == 'fa_IR') {
        currentLocale.value = const Locale('fa', 'IR');
      } else {
        currentLocale.value = const Locale('en', 'US');
      }
    }
    
    exportQuality.value = _storage.read<int>(_exportQualityKey) ?? 90;
    saveToGallery.value = _storage.read<bool>(_saveToGalleryKey) ?? true;
    showGrid.value = _storage.read<bool>(_showGridKey) ?? true;
    isEditorDarkMode.value = _storage.read<bool>(_editorDarkModeKey) ?? true;
    enableZoom.value = _storage.read<bool>(_enableZoomKey) ?? false;
    outputFormat.value = _storage.read<String>(_outputFormatKey) ?? 'jpg';
    maxOutputSize.value = _storage.read<int>(_maxOutputSizeKey) ?? 2000;
    enableBackgroundGeneration.value = _storage.read<bool>(_backgroundGenerationKey) ?? true;
    enableIsolateGeneration.value = _storage.read<bool>(_isolateGenerationKey) ?? true;
    isDarkMode.value = GroundedTheme.isDarkMode;
  }

  void changeLanguage(Locale locale) {
    currentLocale.value = locale;
    _storage.write(_languageKey, '${locale.languageCode}_${locale.countryCode}');
    Get.updateLocale(locale);
    Get.changeTheme(GroundedTheme.getThemeData(locale, isDarkMode.value));
    Get.forceAppUpdate();
    
    // Show feedback
    final langName = languages.firstWhere(
      (l) => (l['locale'] as Locale).languageCode == locale.languageCode,
      orElse: () => languages[0],
    )['nativeName'] as String;
    Get.snackbar(
      '',
      LocaleKeys.settings_language_changed.trParams({'s': langName}),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: GroundedTheme.surface,
      colorText: GroundedTheme.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  void toggleThemeMode(bool darkMode) {
    isDarkMode.value = darkMode;
    GroundedTheme.setDarkMode(darkMode);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: darkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: darkMode 
            ? GroundedTheme.backgroundDark 
            : GroundedTheme.backgroundLight,
        systemNavigationBarIconBrightness: darkMode ? Brightness.light : Brightness.dark,
      ),
    );
    Get.changeTheme(GroundedTheme.getThemeData(currentLocale.value, darkMode));
    Get.forceAppUpdate();
  }

  void setExportQuality(int quality) {
    exportQuality.value = quality;
    _storage.write(_exportQualityKey, quality);
  }

  void toggleSaveToGallery(bool value) {
    saveToGallery.value = value;
    _storage.write(_saveToGalleryKey, value);
  }

  void toggleShowGrid(bool value) {
    showGrid.value = value;
    _storage.write(_showGridKey, value);
  }

  void toggleEditorDarkMode(bool value) {
    isEditorDarkMode.value = value;
    _storage.write(_editorDarkModeKey, value);
  }

  void toggleZoom(bool value) {
    enableZoom.value = value;
    _storage.write(_enableZoomKey, value);
  }
  
  void setOutputFormat(String format) {
    outputFormat.value = format;
    _storage.write(_outputFormatKey, format);
  }
  
  void setMaxOutputSize(int size) {
    maxOutputSize.value = size;
    _storage.write(_maxOutputSizeKey, size);
  }
  
  void toggleBackgroundGeneration(bool value) {
    enableBackgroundGeneration.value = value;
    _storage.write(_backgroundGenerationKey, value);
  }
  
  void toggleIsolateGeneration(bool value) {
    enableIsolateGeneration.value = value;
    _storage.write(_isolateGenerationKey, value);
  }

  /// Reset all settings to factory defaults
  void resetToDefaults() {
    // Export
    setExportQuality(90);
    setOutputFormat('jpg');
    setMaxOutputSize(2000);
    toggleSaveToGallery(true);
    
    // Performance
    toggleBackgroundGeneration(true);
    toggleIsolateGeneration(true);
    
    // Editor
    toggleShowGrid(true);
    toggleZoom(false);
    
    Get.snackbar(
      '',
      LocaleKeys.settings_reset_success.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: GroundedTheme.surface,
      colorText: GroundedTheme.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  String get currentLanguageName {
    final lang = languages.firstWhere(
      (l) => (l['locale'] as Locale).languageCode == currentLocale.value.languageCode,
      orElse: () => languages[0],
    );
    return lang['nativeName'] as String;
  }

  String get currentQualityLabel => qualityLabelKey(exportQuality.value);
  String get currentFormatLabel => formatLabel(outputFormat.value);
  String get currentSizeLabel => sizeLabel(maxOutputSize.value);
  
  /// Cached image generation configs — rebuilt only when inputs change.
  ImageGenerationConfigs? _cachedImageGenConfigs;
  String? _imageGenCacheKey;
  
  /// Get ImageGenerationConfigs for the editor.
  /// Cached to avoid allocating a new object on every LayoutBuilder rebuild.
  ImageGenerationConfigs get imageGenerationConfigs {
    final key = '${outputFormat.value}_${exportQuality.value}_${maxOutputSize.value}'
        '_${enableBackgroundGeneration.value}_${enableIsolateGeneration.value}';
    if (_imageGenCacheKey == key && _cachedImageGenConfigs != null) {
      return _cachedImageGenConfigs!;
    }
    _imageGenCacheKey = key;
    _cachedImageGenConfigs = ImageGenerationConfigs(
      outputFormat: outputFormat.value == 'png' ? OutputFormat.png : OutputFormat.jpg,
      jpegQuality: exportQuality.value,
      maxOutputSize: maxOutputSize.value == 0 
          ? Size.infinite 
          : Size(maxOutputSize.value.toDouble(), maxOutputSize.value.toDouble()),
      enableBackgroundGeneration: enableBackgroundGeneration.value,
      enableIsolateGeneration: enableIsolateGeneration.value,
      // IMPORTANT: Must be false so that captureEditorImage / doneEditing
      // always renders through the layer pipeline instead of returning the
      // raw original bytes when canUndo == false (e.g. reopened project
      // with no new edits).
      enableUseOriginalBytes: false,
      pngLevel: 6,
    );
    return _cachedImageGenConfigs!;
  }
}
