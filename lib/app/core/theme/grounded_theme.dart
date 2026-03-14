import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Grounded Design Tokens
/// Premium, calm, modern UI with neutral palette
/// Supports both dark and light mode themes
class GroundedTheme {
  GroundedTheme._();

  // ===== THEME MODE =====
  
  /// Storage key for theme mode
  static const String _themeModeKey = 'theme_mode';
  
  /// Get storage instance
  static GetStorage get _storage => GetStorage();
  
  /// Check if dark mode is enabled
  static bool get isDarkMode {
    final savedMode = _storage.read<String>(_themeModeKey);
    return savedMode != 'light';  // Default to dark mode
  }
  
  /// Set theme mode and persist
  static void setDarkMode(bool isDark) {
    _storage.write(_themeModeKey, isDark ? 'dark' : 'light');
  }
  
  /// Toggle between dark and light mode
  static void toggleThemeMode() {
    setDarkMode(!isDarkMode);
  }

  // ===== DARK MODE COLORS =====
  
  /// Primary background - pure black (dark mode)
  static const Color backgroundDark = Color(0xFF000000);
  
  /// Secondary background - dark gray for panels/bars (dark mode)
  static const Color surfaceDark = Color(0xFF161616);
  
  /// Elevated surface - slightly lighter (dark mode)
  static const Color surfaceElevatedDark = Color(0xFF1E1E1E);
  
  /// Card/container background (dark mode)
  static const Color cardDark = Color(0xFF252525);
  
  /// Text colors (dark mode)
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);
  static const Color textTertiaryDark = Color(0xFF666666);
  
  /// Border/divider colors (dark mode)
  static const Color borderDark = Color(0xFF333333);
  static const Color dividerDark = Color(0xFF2A2A2A);
  
  /// Overlay colors (dark mode)
  static const Color overlayLightDark = Color(0x1AFFFFFF);
  static const Color overlayDarkDark = Color(0x80000000);

  // ===== LIGHT MODE COLORS =====
  
  /// Primary background - clean white (light mode)
  static const Color backgroundLight = Color(0xFFF8F9FA);
  
  /// Secondary background - light gray for panels/bars (light mode)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  /// Elevated surface - slightly darker (light mode)
  static const Color surfaceElevatedLight = Color(0xFFF0F1F3);
  
  /// Card/container background (light mode)
  static const Color cardLight = Color(0xFFFFFFFF);
  
  /// Text colors (light mode)
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  
  /// Border/divider colors (light mode)
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFE5E7EB);
  
  /// Overlay colors (light mode)
  static const Color overlayLightLight = Color(0x1A000000);
  static const Color overlayDarkLight = Color(0x40000000);

  // ===== HOME SCREEN LIGHT-MODE TOKENS =====
  // Refined cool-gray palette tuned for sRGB panels.

  /// Home scaffold background (cool gray-100)
  static const Color scaffoldLight = Color(0xFFF0F1F5);

  /// Alternate card surface
  static const Color cardAltLight = Color(0xFFF6F7FB);

  /// Stronger border for card outlines
  static const Color borderContrastLight = Color(0xFFD4D7E0);

  /// High-contrast primary text (gray-900)
  static const Color textHeroLight = Color(0xFF111827);

  /// Drag handle / decorative element color
  static const Color handleLight = Color(0xFFC0C4CC);

  // ===== ADAPTIVE COLORS (based on current theme mode) =====
  
  /// Primary background - adapts to theme mode
  static Color get background => isDarkMode ? backgroundDark : backgroundLight;
  
  /// Secondary background - adapts to theme mode
  static Color get surface => isDarkMode ? surfaceDark : surfaceLight;
  
  /// Elevated surface - adapts to theme mode
  static Color get surfaceElevated => isDarkMode ? surfaceElevatedDark : surfaceElevatedLight;
  
  /// Card/container background - adapts to theme mode
  static Color get card => isDarkMode ? cardDark : cardLight;
  
  /// Text colors - adapts to theme mode
  static Color get textPrimary => isDarkMode ? textPrimaryDark : textPrimaryLight;
  static Color get textSecondary => isDarkMode ? textSecondaryDark : textSecondaryLight;
  static Color get textTertiary => isDarkMode ? textTertiaryDark : textTertiaryLight;
  
  /// Border/divider colors - adapts to theme mode
  static Color get border => isDarkMode ? borderDark : borderLight;
  static Color get divider => isDarkMode ? dividerDark : dividerLight;
  
  /// Overlay colors - adapts to theme mode
  static Color get overlayLight => isDarkMode ? overlayLightDark : overlayLightLight;
  static Color get overlayDark => isDarkMode ? overlayDarkDark : overlayDarkLight;

  // ===== SHARED COLORS (same for both modes) =====
  
  /// Primary accent - subtle blue
  static const Color primary = Color(0xFF3B82F6);

  /// Unified dark-mode status bar + navigation bar style.
  /// Use everywhere so the status bar blends with the 0xFF161616 top bar.
  static const SystemUiOverlayStyle darkOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarIconBrightness: Brightness.light,
  );
  
  /// Secondary accent
  static const Color secondary = Color(0xFF6366F1);
  
  /// Semantic colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // ===== EDITOR-SPECIFIC THEME =====
  
  /// Storage key for editor dark mode
  static const String _editorDarkModeKey = 'editor_dark_mode';
  
  /// Check if editor dark mode is enabled (default: true)
  static bool get isEditorDarkMode {
    return _storage.read<bool>(_editorDarkModeKey) ?? true;
  }
  
  /// Editor background color (adapts to editor theme setting)
  static Color get editorBackground => isEditorDarkMode ? backgroundDark : const Color(0xFFF5F5F5);
  
  /// Editor surface color (bottom bars, panels)
  static Color get editorSurface => isEditorDarkMode ? surfaceDark : const Color(0xFFFFFFFF);
  
  /// Editor surface elevated color
  static Color get editorSurfaceElevated => isEditorDarkMode ? surfaceElevatedDark : const Color(0xFFF0F0F0);
  
  /// Editor card color
  static Color get editorCard => isEditorDarkMode ? cardDark : const Color(0xFFFFFFFF);
  
  /// Editor text primary color
  static Color get editorTextPrimary => isEditorDarkMode ? textPrimaryDark : textPrimaryLight;
  
  /// Editor text secondary color
  static Color get editorTextSecondary => isEditorDarkMode ? textSecondaryDark : textSecondaryLight;
  
  /// Editor icon color
  static Color get editorIconColor => isEditorDarkMode ? Colors.white : const Color(0xFF1A1A1A);
  
  /// Editor divider color
  static Color get editorDivider => isEditorDarkMode ? dividerDark : dividerLight;

  // ===== EDITOR: ALWAYS-DARK GLASS TOKENS =====
  // Used in glass buttons, pills, and overlays that are always rendered
  // against the dark editor background regardless of the app theme.

  /// Glass button fill (white ~12%)
  static const Color glassButtonFill = Color(0x1FFFFFFF);
  /// Glass button border (white ~18%)
  static const Color glassButtonBorder = Color(0x2EFFFFFF);
  /// Glass icon / text color (white ~90%)
  static const Color glassIconColor = Color(0xE6FFFFFF);
  /// Disabled icon / text color (white ~25%)
  static const Color glassIconDisabled = Color(0x40FFFFFF);
  /// Pill separator (white ~15%)
  static const Color glassDivider = Color(0x26FFFFFF);

  // ===== SPACING =====
  
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // ===== RADIUS =====
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusFull = 999.0;

  // ===== TYPOGRAPHY =====
  
  /// Default UI font family (English)
  static const String fontFamilyEnglish = 'Roboto';
  
  /// Persian UI font family
  static const String fontFamilyPersian = 'Vazir';
  
  /// Get font family based on locale
  static String getFontFamily(Locale? locale) {
    if (locale?.languageCode == 'fa') {
      return fontFamilyPersian;
    }
    return fontFamilyEnglish;
  }
  
  /// Get current font family based on Get.locale
  static String get currentFontFamily {
    final locale = Get.locale;
    if (locale?.languageCode == 'fa') {
      return fontFamilyPersian;
    }
    return fontFamilyEnglish;
  }
  
  /// Legacy font family (for backwards compatibility)
  static const String fontFamily = 'Roboto';
  
  /// Font sizes
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 24.0;
  static const double fontSizeDisplay = 32.0;

  // ===== SHADOWS =====
  
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: isDarkMode 
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: isDarkMode 
          ? Colors.black.withValues(alpha: 0.25)
          : Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: isDarkMode 
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ===== ANIMATION DURATIONS =====
  
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // ===== TEXT STYLES (Adaptive) =====
  
  static TextStyle get displayLarge => TextStyle(
    fontFamily: currentFontFamily,
    fontSize: fontSizeDisplay,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineLarge => TextStyle(
    fontFamily: currentFontFamily,
    fontSize: fontSizeXXL,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontFamily: currentFontFamily,
    fontSize: fontSizeXL,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get titleLarge => TextStyle(
    fontFamily: currentFontFamily,
    fontSize: fontSizeL,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get titleMedium => TextStyle(
    fontFamily: currentFontFamily,
    fontSize: fontSizeM,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: currentFontFamily,
    fontSize: fontSizeM,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: currentFontFamily,
    fontSize: fontSizeS,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get labelLarge => TextStyle(
    fontFamily: currentFontFamily,
    fontSize: fontSizeS,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: currentFontFamily,
    fontSize: fontSizeXS,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  // ===== THEME DATA =====
  
  /// Get current theme data (adapts to saved theme mode and locale)
  static ThemeData get themeData => getThemeData(Get.locale, isDarkMode);
  
  /// Get dark theme data with locale
  static ThemeData get darkThemeData => getThemeData(Get.locale, true);
  
  /// Get light theme data with locale
  static ThemeData get lightThemeData => getThemeData(Get.locale, false);
  
  /// Get theme data with locale-specific font family and theme mode
  static ThemeData getThemeData(Locale? locale, [bool? darkMode]) {
    final font = getFontFamily(locale);
    final isDark = darkMode ?? isDarkMode;
    
    // Select colors based on theme mode
    final bg = isDark ? backgroundDark : backgroundLight;
    final surf = isDark ? surfaceDark : surfaceLight;
    final surfElevated = isDark ? surfaceElevatedDark : surfaceElevatedLight;
    final cardColor = isDark ? cardDark : cardLight;
    final txtPrimary = isDark ? textPrimaryDark : textPrimaryLight;
    final txtSecondary = isDark ? textSecondaryDark : textSecondaryLight;
    final borderColor = isDark ? borderDark : borderLight;
    final dividerColor = isDark ? dividerDark : dividerLight;
    
    // Create text theme with the correct font and colors
    final textTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: font, fontSize: 57, fontWeight: FontWeight.w400, color: txtPrimary),
      displayMedium: TextStyle(fontFamily: font, fontSize: 45, fontWeight: FontWeight.w400, color: txtPrimary),
      displaySmall: TextStyle(fontFamily: font, fontSize: fontSizeDisplay, fontWeight: FontWeight.w700, color: txtPrimary),
      headlineLarge: TextStyle(fontFamily: font, fontSize: fontSizeXXL, fontWeight: FontWeight.w600, color: txtPrimary),
      headlineMedium: TextStyle(fontFamily: font, fontSize: fontSizeXL, fontWeight: FontWeight.w600, color: txtPrimary),
      headlineSmall: TextStyle(fontFamily: font, fontSize: fontSizeL, fontWeight: FontWeight.w600, color: txtPrimary),
      titleLarge: TextStyle(fontFamily: font, fontSize: fontSizeL, fontWeight: FontWeight.w600, color: txtPrimary),
      titleMedium: TextStyle(fontFamily: font, fontSize: fontSizeM, fontWeight: FontWeight.w500, color: txtPrimary),
      titleSmall: TextStyle(fontFamily: font, fontSize: fontSizeS, fontWeight: FontWeight.w500, color: txtPrimary),
      bodyLarge: TextStyle(fontFamily: font, fontSize: fontSizeM, fontWeight: FontWeight.w400, color: txtPrimary),
      bodyMedium: TextStyle(fontFamily: font, fontSize: fontSizeS, fontWeight: FontWeight.w400, color: txtSecondary),
      bodySmall: TextStyle(fontFamily: font, fontSize: fontSizeXS, fontWeight: FontWeight.w400, color: txtSecondary),
      labelLarge: TextStyle(fontFamily: font, fontSize: fontSizeS, fontWeight: FontWeight.w500, color: txtPrimary),
      labelMedium: TextStyle(fontFamily: font, fontSize: fontSizeXS, fontWeight: FontWeight.w500, color: txtPrimary),
      labelSmall: TextStyle(fontFamily: font, fontSize: fontSizeXS, fontWeight: FontWeight.w500, color: txtSecondary),
    );
    
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: font,
      textTheme: textTheme,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: surf,
        onSurface: txtPrimary,
        primary: primary,
        onPrimary: isDark ? textPrimaryDark : Colors.white,
        secondary: secondary,
        onSecondary: isDark ? textPrimaryDark : Colors.white,
        error: error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surf,
        foregroundColor: txtPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: fontSizeXL,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: primary,
        unselectedItemColor: txtSecondary,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 0 : 1,
        shadowColor: isDark ? Colors.transparent : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: isDark ? 0 : 2,
          shadowColor: isDark ? Colors.transparent : primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: TextStyle(
            fontFamily: font,
            fontSize: fontSizeM,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: txtPrimary,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: TextStyle(
            fontFamily: font,
            fontSize: fontSizeM,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: TextStyle(
            fontFamily: font,
            fontSize: fontSizeM,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: txtPrimary,
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surf,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLarge),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? surfElevated : txtPrimary,
        contentTextStyle: TextStyle(
          fontFamily: font,
          fontSize: fontSizeM,
          fontWeight: FontWeight.w400,
          color: isDark ? txtPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: txtSecondary,
        textColor: txtPrimary,
        tileColor: Colors.transparent,
        selectedTileColor: primary.withValues(alpha: 0.1),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? Colors.grey.shade500 : Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return isDark ? Colors.grey.shade800 : Colors.grey.shade300;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: fontSizeXL,
          fontWeight: FontWeight.w600,
          color: txtPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: font,
          fontSize: fontSizeM,
          fontWeight: FontWeight.w400,
          color: txtSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfElevated : surfaceElevatedLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        hintStyle: TextStyle(
          fontFamily: font,
          color: txtSecondary,
        ),
      ),
    );
  }
}
