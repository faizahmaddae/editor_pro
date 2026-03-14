import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/core/theme/grounded_theme.dart';
import 'app/data/services/project_storage.dart';
import 'app/modules/home/views/home_view.dart';
import 'app/modules/settings/controllers/settings_controller.dart';
import 'app/routes/app_pages.dart';
import 'generated/locales.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler — logs uncaught Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  // Catch async errors not handled by Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error\n$stack');
    return true;
  };
  
  // Initialize GetStorage (default container)
  await GetStorage.init();
  
  // Initialize projects storage container
  await ProjectStorage.init();
  
  // Register SettingsController as a permanent service (used across the app)
  Get.put(SettingsController(), permanent: true);
  
  // Load saved locale
  final storage = GetStorage();
  final savedLang = storage.read<String>('language');
  Locale initialLocale = const Locale('en', 'US');
  if (savedLang == 'fa_IR') {
    initialLocale = const Locale('fa', 'IR');
  }
  
  // Load saved theme mode (defaults to dark mode)
  final isDarkMode = GroundedTheme.isDarkMode;
  
  // Set system UI style based on theme
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDarkMode 
          ? GroundedTheme.backgroundDark 
          : GroundedTheme.backgroundLight,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ),
  );
  
  // Preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Wrap runApp to catch errors in the widget tree
  runApp(PhotoEditorApp(initialLocale: initialLocale));
}

class PhotoEditorApp extends StatelessWidget {
  final Locale initialLocale;
  
  const PhotoEditorApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      onGenerateTitle: (context) => LocaleKeys.app_title.tr,
      debugShowCheckedModeBanner: false,
      
      // Localization
      translationsKeys: AppTranslation.translations,
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('fa', 'IR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      
      
      // Routes
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      
      // Navigator observers for route-aware widgets
      navigatorObservers: [homeRouteObserver],
      
      // Default transition
      defaultTransition: Transition.fadeIn,
      
      // Builder to apply font, theme, and text direction based on current locale
      builder: (context, child) {
        // Get current locale (this updates when Get.updateLocale is called)
        final locale = Get.locale ?? initialLocale;
        final fontFamily = GroundedTheme.getFontFamily(locale);
        final themeData = GroundedTheme.getThemeData(locale);
        
        // Determine text direction based on locale
        final isRtl = locale.languageCode == 'fa' || locale.languageCode == 'ar';
        final textDirection = isRtl ? TextDirection.rtl : TextDirection.ltr;
        
        return Directionality(
          textDirection: textDirection,
          child: Theme(
            data: themeData,
            child: DefaultTextStyle.merge(
              style: TextStyle(fontFamily: fontFamily),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 1.3),
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
