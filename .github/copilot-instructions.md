# Editor Pro - AI Coding Instructions

## Project Overview

Editor Pro is a premium Flutter image editor application built using the **GetX** framework for state management, routing, and dependency injection. It leverages the `pro_image_editor` package with the **Grounded-Design** theme for core editing functionality. The app supports advanced image editing features such as drawing, text editing, cropping, and applying filters.

## Architecture: GetX Pattern

This project follows the **GetX Pattern**, which organizes the codebase into modules with bindings, controllers, and views. The structure is generated using `get_cli`:

```
lib/
├── main.dart                    # App entry with GetMaterialApp, localization, theme
├── app/
│   ├── core/                    # Shared utilities
│   │   ├── fonts/               # Font catalog system
│   │   │   └── font_catalog.dart
│   │   └── theme/               # Grounded design tokens
│   │       └── grounded_theme.dart
│   ├── data/                    # Data layer
│   │   └── services/            # Business services
│   │       ├── export_service.dart
│   │       └── project_storage.dart
│   ├── modules/                 # Feature modules (pages/screens)
│   │   ├── home/                # Home screen module
│   │   └── editor/              # Editor screen module
│   └── routes/                  # Navigation (app_pages.dart, app_routes.dart)
└── generated/
    └── locales.g.dart          # Auto-generated - DO NOT EDIT
```

### Cross-Component Communication
- **State Management**: Managed using `GetX` reactive state (`.obs`) and dependency injection.
- **Routing**: Defined in `app/routes/app_pages.dart` with named routes.
- **Localization**: Translation keys are stored in `assets/locales/` and accessed via `LocaleKeys.key_name.tr`.

## Design System: Grounded-Design

The app uses **Grounded-Design** from `pro_image_editor` as the main design baseline.

### Key Design Tokens
```dart
static const background = Color(0xFF000000);   // Pure black background
static const surface = Color(0xFF161616);      // Bottom bars, cards
static const primary = Color(0xFF2196F3);      // Blue accent
```

### Grounded Components Used
- `GroundedMainBar` - Main editor toolbar
- `GroundedPaintBar` - Paint/draw tools
- `GroundedTextBar` - Text editor toolbar
- `GroundedFilterBar` - Filter selection
- `GroundedTuneBar` - Image adjustments
- `GroundedCropRotateBar` - Crop/rotate tools

## Key Conventions

### Creating New Features
Use `get_cli` commands to generate modules and components:
```bash
get create page:editor         # Creates module with binding, controller, view
get create controller:tools on editor  # Adds controller to existing module
```

### Controller Pattern
Controllers extend `GetxController` with lifecycle hooks:
```dart
class FeatureController extends GetxController {
  final someValue = 0.obs;           // Reactive state with .obs

  @override
  void onInit() { super.onInit(); }  // Called when controller created
}
```

### View Pattern
Views extend `GetView<Controller>` for automatic controller access:
```dart
class FeatureView extends GetView<FeatureController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => Text('${controller.someValue}'));
  }
}
```

### Bindings Pattern
Bindings use `Get.lazyPut` for lazy dependency injection:
```dart
class FeatureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeatureController>(() => FeatureController());
  }
}
```

## Localization

- **Supported locales**: `en_US` (English), `fa_IR` (Persian/Farsi)
- Translation files: `assets/locales/{locale}.json`
- Regenerate translations after modification:
  ```bash
  get generate locales assets/locales
  ```

## Font Catalog System

Located at `lib/app/core/fonts/font_catalog.dart`:

- `FontEntry` - Model with `name`, `displayName`, `fontFamily`, `group`, `style`
- `FontCatalog.search(query)` - Filter fonts by name
- `FontCatalog.toTextStyles()` - Convert to `TextStyle` list for `pro_image_editor`

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `get` | State management, routing, DI |
| `pro_image_editor` | Core image editing |
| `image_picker` | Gallery and camera image selection |
| `flutter_colorpicker` | Color picker for paint/text tools |

## Development Commands

```bash
flutter run                              # Run app
flutter pub get                          # Install dependencies
get generate locales assets/locales      # Regenerate translations
flutter analyze                          # Run static analysis
```

## File Naming Conventions

- Controllers: `{feature}_controller.dart`
- Views: `{feature}_view.dart`
- Bindings: `{feature}_binding.dart`
- Widgets: `{widget_name}.dart`
- Services: `{service_name}_service.dart`
- Routes: `Routes.HOME`, `Routes.EDITOR`
