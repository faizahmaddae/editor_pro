import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/designs/grounded/grounded_design.dart';
import 'package:pro_image_editor/features/main_editor/services/layer_copy_manager.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/enums/editing_session_state.dart';
import '../../../core/formats/format_presets.dart';
import '../../../core/theme/grounded_theme.dart';
import '../../../modules/settings/controllers/settings_controller.dart';
import '../../../../generated/locales.g.dart';
import '../configs/editor_style_configs.dart';
import '../controllers/editor_controller.dart';
import '../widgets/premium_color_picker.dart';
import '../widgets/reorder_layer_sheet.dart';
import '../widgets/text_shadow_panel.dart';

/// Editor Screen - Full Grounded Design Implementation
/// Note: The editor is always in dark mode as this is industry standard
/// for professional photo editors (Lightroom, Snapseed, VSCO, etc.)
class EditorView extends GetView<EditorController> {
  const EditorView({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: Don't use PopScope here - it blocks sub-editor close buttons.
    // pro_image_editor handles its own navigation via onCloseEditor callback.
    return _EditorContent(controller: controller);
  }
}

class _EditorContent extends StatefulWidget {
  final EditorController controller;

  const _EditorContent({required this.controller});

  @override
  State<_EditorContent> createState() => _EditorContentState();
}

class _EditorContentState extends State<_EditorContent> {
  final _editorKey = GlobalKey<ProImageEditorState>();
  final _mainEditorBarKey = GlobalKey<GroundedMainBarState>();
  
  /// Scroll controller for toolbar - persists across widget rebuilds
  final _toolbarScrollController = ScrollController();

  /// Cached callbacks — these closures never change across rebuilds.
  ProImageEditorCallbacks? _cachedCallbacks;

  /// Cached configs keyed by layout width + height to avoid re-creation
  /// when LayoutBuilder fires with the same constraints.
  ProImageEditorConfigs? _cachedConfigs;
  double _cachedConstraintsWidth = -1;
  double _cachedConstraintsHeight = -1;

  /// True once the editor's background image has been decoded.
  /// Quick actions and format presets are deferred until this fires
  /// so that sub-editors have valid image info.
  bool _imageDecoded = false;

  /// Set to `true` when the Done button triggers `doneEditing()`.
  /// Used in [onCloseEditor] to distinguish the Done→Export path from
  /// the Back→closeWarning path (which is handled by [DraftExitSheet]).
  bool _isDoneEditing = false;

  /// Cached initial aspect ratio resolved from the format preset.
  /// Stored here so that config rebuilds (e.g. device rotation) don't lose
  /// the value after `controller.format` has been cleared.
  double? _cachedInitAspectRatio;

  // Get zoom setting from SettingsController
  bool get _isZoomEnabled => Get.find<SettingsController>().enableZoom.value;

  bool get _useMaterialDesign =>
      platformDesignMode == ImageEditorDesignMode.material;

  int _calculateEmojiColumns(BoxConstraints constraints) =>
      max(1, (_useMaterialDesign ? 8 : 10) / 400 * constraints.maxWidth - 1)
          .floor();

  @override
  void initState() {
    super.initState();
    // Share editor key with controller for state history export
    widget.controller.editorKey = _editorKey;

    // Resolve and cache the format preset's aspect ratio once.
    // This survives config rebuilds so a device rotation won't lose it.
    final formatId = widget.controller.format;
    if (formatId != null && formatId.isNotEmpty) {
      final preset = FormatPresets.getById(formatId);
      if (preset != null) {
        _cachedInitAspectRatio = preset.aspectRatio;
      }
    }
  }

  @override
  void dispose() {
    _toolbarScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: Do NOT wrap ProImageEditor with a scaled MediaQuery.
    // The Grounded design widgets use hard-coded sizes/paddings and a
    // blanket TextScaler will cause text overflow inside package UI.
    // Instead, apply text scaling only inside our custom widgets
    // (appbar, bottom bar, sheets) where we control the layout.
    // IMPORTANT: Only isLoadingHistory is read inside this Obx.
    // Reading additional .obs values here would rebuild the entire
    // ProImageEditor widget tree — keep the reactive scope minimal.
    return Obx(() {
      // Show loading indicator while state history is being loaded
      if (widget.controller.isLoadingHistory.value) {
        return Container(
          color: GroundedTheme.background,
          child: const Center(
            child: CircularProgressIndicator(
              color: GroundedTheme.primary,
            ),
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          // Guard: verify image file exists before handing it to the editor.
          final imageFile = File(widget.controller.editorImagePath);
          if (!imageFile.existsSync()) {
            return _buildError(LocaleKeys.editor_error_file_missing.tr);
          }

          // Reuse cached configs when constraints haven't changed.
          if (_cachedConfigs == null ||
              constraints.maxWidth != _cachedConstraintsWidth ||
              constraints.maxHeight != _cachedConstraintsHeight) {
            _cachedConstraintsWidth = constraints.maxWidth;
            _cachedConstraintsHeight = constraints.maxHeight;
            _cachedConfigs = _buildConfigs(constraints);
          }
          _cachedCallbacks ??= _buildCallbacks();

          // Always use file mode - blank canvas is now a generated image file
          return ProImageEditor.file(
            // Use editorImagePath which returns original image when reopening
            imageFile,
            key: _editorKey,
            callbacks: _cachedCallbacks!,
            configs: _cachedConfigs!,
          );
        },
      );
    });
  }

  ProImageEditorCallbacks _buildCallbacks() {
    return ProImageEditorCallbacks(
      // === Top-Level Callbacks ===
      onImageEditingStarted: () async {
        // Mark that this close cycle was initiated by the Done button
        // so onCloseEditor routes to the export page.
        _isDoneEditing = true;
      },
      onImageEditingComplete: (bytes) async {
        if (bytes.isNotEmpty) {
          widget.controller.editedImageBytes = bytes;
        }
      },
      onCloseEditor: (editorMode) {
        if (editorMode != EditorMode.main) {
          // Standalone sub-editors (Paint, CropRotate, Filter, Tune, Blur)
          // delegate their Navigator.pop to this callback when onCloseEditor
          // is provided — see StandaloneEditorState.close().
          // TextEditor and EmojiEditor pop themselves and never reach here.
          Navigator.pop(context);
          return;
        }

        // Main editor close — two possible paths:
        //
        // 1. Done flow  — _isDoneEditing is true, image bytes exist.
        //    → Navigate to the export page.
        //
        // 2. Back flow — _isDoneEditing is false.
        //    closeWarningDialog already showed DraftExitSheet (if needed)
        //    and the user either saved, discarded, or had no changes.
        //    → Simply exit the editor.
        if (_isDoneEditing &&
            widget.controller.editedImageBytes != null &&
            widget.controller.sessionState != EditingSessionState.exported) {
          _isDoneEditing = false;
          widget.controller.showExportSheet();
        } else {
          _isDoneEditing = false;
          Get.back();
        }
      },

      // === Main Editor Callbacks ===
      mainEditorCallbacks: MainEditorCallbacks(
        // KEY: Subscribe to state history changes for state machine
        onStateHistoryChange: (stateManager, editor) {
          widget.controller.onEditorStateChanged(stateManager, editor);
        },
        // KEY: Capture save point AFTER import completes (for reopened projects)
        onImportHistoryEnd: (state, import) {
          widget.controller.onImportHistoryComplete(state.stateManager);
        },
        onAfterViewInit: () {
          if (kDebugMode) debugPrint('[Editor] Main editor initialized');
        },
        // Gate quick actions on image decode so sub-editors have valid
        // image info (crop bounds, filters, etc.).
        onImageDecoded: () {
          if (_imageDecoded) return; // prevent double-fire
          _imageDecoded = true;
          _handleQuickAction();
          _applyFormat();
        },
        onStartCloseSubEditor: (subEditor) {
          if (kDebugMode) debugPrint('[Editor] Closing sub-editor: $subEditor');
          _mainEditorBarKey.currentState?.setState(() {});
        },
        onEndCloseSubEditor: (subEditor) {
          if (kDebugMode) debugPrint('[Editor] Sub-editor closed: $subEditor');
        },
        // Haptic feedback when layer snaps to helper lines (like WhatsApp)
        helperLines: HelperLinesCallbacks(
          onLineHit: () {
            HapticFeedback.lightImpact();
          },
        ),
      ),

      // === Text Editor Callbacks ===
      textEditorCallbacks: TextEditorCallbacks(
        onInit: () {
          if (kDebugMode) debugPrint('[TextEditor] Initialized');
        },
        onDone: () {
          if (kDebugMode) debugPrint('[TextEditor] Done - text layer created/updated');
        },
        onColorChanged: (colorValue) {
          if (kDebugMode) debugPrint('[TextEditor] Color changed: $colorValue');
        },
        onBackgroundModeChanged: (mode) {
          if (kDebugMode) debugPrint('[TextEditor] Background mode: $mode');
        },
      ),

      // === Paint Editor Callbacks ===
      paintEditorCallbacks: PaintEditorCallbacks(
        onDone: () {
          if (kDebugMode) debugPrint('[PaintEditor] Done - paint layer created');
        },
      ),

      // === Sticker Editor Callbacks ===
      stickerEditorCallbacks: StickerEditorCallbacks(
        onSearchChanged: (value) {
          if (kDebugMode) debugPrint('[StickerEditor] Search: $value');
        },
      ),

      // === Filter Editor Callbacks ===
      filterEditorCallbacks: FilterEditorCallbacks(
        onDone: () {
          if (kDebugMode) debugPrint('[FilterEditor] Filter applied');
        },
      ),

      // === Crop/Rotate Editor Callbacks ===
      cropRotateEditorCallbacks: CropRotateEditorCallbacks(
        onDone: () {
          if (kDebugMode) debugPrint('[CropRotate] Crop/rotate applied');
        },
      ),

      // === Blur Editor Callbacks ===
      blurEditorCallbacks: BlurEditorCallbacks(
        onDone: () {
          if (kDebugMode) debugPrint('[BlurEditor] Blur applied');
        },
      ),

      // === Tune Editor Callbacks ===
      tuneEditorCallbacks: TuneEditorCallbacks(
        onDone: () {
          if (kDebugMode) debugPrint('[TuneEditor] Adjustments applied');
        },
      ),
    );
  }
  
  /// Handles quick action by auto-opening the corresponding sub-editor
  void _handleQuickAction() {
    final quickAction = widget.controller.quickAction;
    if (quickAction == null || quickAction.isEmpty) return;
    
    // Clear the quick action so it doesn't trigger again
    widget.controller.quickAction = null;
    
    // Wait for the next frame so the editor is fully laid out.
    // onAfterViewInit already fires after the first frame, so one
    // additional post-frame callback is sufficient.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final editorState = _editorKey.currentState;
      if (editorState == null) return;
      
      switch (quickAction) {
        case 'cropRotate':
          editorState.openCropRotateEditor();
          break;
        case 'filter':
          editorState.openFilterEditor();
          break;
        case 'tune':
          editorState.openTuneEditor();
          break;
        case 'blur':
          editorState.openBlurEditor();
          break;
        case 'text':
          editorState.openTextEditor();
          break;
        case 'paint':
          editorState.openPaintEditor();
          break;
        default:
          if (kDebugMode) debugPrint('Unknown quick action: $quickAction');
      }
    });
  }

  /// Applies format preset by opening crop editor with the target aspect ratio
  void _applyFormat() {
    final formatId = widget.controller.format;
    if (formatId == null || formatId.isEmpty) return;
    
    // Clear the format so it doesn't trigger again
    widget.controller.format = null;
    
    // Get the preset
    final preset = FormatPresets.getById(formatId);
    if (preset == null) {
      if (kDebugMode) debugPrint('Unknown format: $formatId');
      return;
    }
    
    // Wait for the next frame so the editor is fully laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final editorState = _editorKey.currentState;
      if (editorState == null) return;
      
      // Open crop editor - the aspect ratio will be set via configs
      // We use openCropRotateEditor and the user can apply the preset ratio
      editorState.openCropRotateEditor();
      if (kDebugMode) debugPrint('>>> Opened crop editor for format: ${preset.id} (${FormatPresets.formatRatio(preset.aspectRatio)})');
    });
  }

  /// Builds the dependencies object for config builders
  EditorConfigDependencies _buildDependencies() {
    return EditorConfigDependencies(
      isZoomEnabled: _isZoomEnabled,
      useMaterialDesign: _useMaterialDesign,
      calculateEmojiColumns: _calculateEmojiColumns,
      showColorPicker: _showColorPicker,
      mainEditorBarKey: _mainEditorBarKey,
      toolbarScrollController: _toolbarScrollController,
      controller: widget.controller,
      openReorderSheet: _openReorderSheet,
      initAspectRatio: _cachedInitAspectRatio,
      applyShadowToTextStyle: _applyShadowToTextStyle,
    );
  }

  ProImageEditorConfigs _buildConfigs(BoxConstraints constraints) {
    // Get settings controller for image generation configs
    final settings = Get.find<SettingsController>();
    
    // Get current font family based on locale
    final fontFamily = GroundedTheme.getFontFamily(Get.locale);
    
    // Build dependencies for config builders
    final deps = _buildDependencies();
    
    // Editor always uses dark theme (industry standard for photo editors)
    return ProImageEditorConfigs(
      designMode: platformDesignMode,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade800,
          brightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(
          size: 28,
          color: Colors.white,
        ),
      ),
      
      // Image generation settings from user preferences
      imageGeneration: settings.imageGenerationConfigs,
      
      // State history for editable layers (when reopening a saved project)
      stateHistory: StateHistoryConfigs(
        initStateHistory: widget.controller.loadedStateHistory,
        // Each history entry stores an in-memory screenshot.
        // 200 is a mobile-safe middle ground — enough for a full session
        // without OOM risk on most devices.
        stateHistoryLimit: 200,
      ),
      
      // Localization
      i18n: EditorStyleConfigs.buildI18n(),
      
      // Layer interaction - FloatSelect design with reordering
      layerInteraction: EditorStyleConfigs.buildLayerInteractionConfigs(),
      
      // Main editor
      mainEditor: EditorStyleConfigs.buildMainEditorConfigs(deps),
      
      // Paint editor
      paintEditor: EditorStyleConfigs.buildPaintEditorConfigs(deps),
      
      // Text editor
      textEditor: EditorStyleConfigs.buildTextEditorConfigs(deps),
      
      // Crop/Rotate editor
      cropRotateEditor: EditorStyleConfigs.buildCropRotateEditorConfigs(deps),
      
      // Filter editor
      filterEditor: EditorStyleConfigs.buildFilterEditorConfigs(),
      
      // Tune editor
      tuneEditor: EditorStyleConfigs.buildTuneEditorConfigs(),
      
      // Blur editor
      blurEditor: EditorStyleConfigs.buildBlurEditorConfigs(),
      
      // Emoji editor
      emojiEditor: EditorStyleConfigs.buildEmojiEditorConfigs(deps, constraints),
      
      // Sticker editor
      stickerEditor: EditorStyleConfigs.buildStickerEditorConfigs(),
      
      // Dialog configs
      dialogConfigs: EditorStyleConfigs.buildDialogConfigs(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fallback screen shown when the source image cannot be loaded.
  Widget _buildError(String message) {
    return Container(
      color: GroundedTheme.backgroundDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded, color: GroundedTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(LocaleKeys.common_back.tr,
                  style: const TextStyle(color: GroundedTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the layer reorder bottom sheet
  void _openReorderSheet(ProImageEditorState editor) {
    final layerCopyManager = LayerCopyManager();
    HapticFeedback.selectionClick();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          // Use StatefulBuilder to make the sheet reactive
          child: StatefulBuilder(
            builder: (context, setSheetState) => ReorderLayerSheet(
              layers: editor.activeLayers,
              scrollController: scrollController,
              onReorder: (oldIndex, newIndex) {
                // ReorderableListView quirk: adjust newIndex when moving down
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                editor.moveLayerListPosition(
                  oldIndex: oldIndex,
                  newIndex: newIndex,
                );
                // Rebuild the sheet to reflect the new order
                setSheetState(() {});
              },
              onDuplicate: (index) {
                final layer = editor.activeLayers[index];
                final duplicatedLayer = layerCopyManager.duplicateLayer(layer);
                editor.addLayer(
                  duplicatedLayer,
                  autoCorrectZoomOffset: false,
                  autoCorrectZoomScale: false,
                );
                // Rebuild the sheet to reflect the new layer
                setSheetState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    Color currentColor,
    void Function(Color) onColorChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PremiumColorPicker(
        currentColor: currentColor,
        onColorChanged: onColorChanged,
      ),
    );
  }
  
  /// Apply shadow configuration to the text editor's current text style
  void _applyShadowToTextStyle(TextEditorState editorState, TextShadowConfig config) {
    final currentStyle = editorState.selectedTextStyle;
    final newStyle = currentStyle.copyWith(
      shadows: config.toShadowList(),
    );
    editorState.setTextStyle(newStyle);
  }
}
