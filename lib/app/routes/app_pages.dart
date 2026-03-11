import 'package:get/get.dart';

import '../modules/dev/font_calibration_page.dart';
import '../modules/editor/bindings/editor_binding.dart';
import '../modules/editor/views/editor_view.dart';
import '../modules/editor/views/export_page.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.EDITOR,
      page: () => const EditorView(),
      binding: EditorBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: _Paths.EXPORT,
      page: () => const ExportPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.cupertino,
    ),
    // Dev tools
    GetPage(
      name: _Paths.FONT_CALIBRATION,
      page: () => const FontCalibrationPage(),
      transition: Transition.cupertino,
    ),
  ];
}
