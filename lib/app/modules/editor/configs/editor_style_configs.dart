import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/designs/grounded/grounded_design.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/fonts/font_catalog.dart';
import '../../../core/theme/grounded_theme.dart';
import '../controllers/editor_controller.dart';
import '../widgets/draft_exit_sheet.dart';
import '../widgets/editor_loading_overlay.dart';
import '../widgets/main_editor_appbar.dart';
import '../widgets/main_editor_bottombar.dart';
import '../widgets/sub_editor_appbar.dart';
import '../widgets/text_editor_appbar.dart';
import '../widgets/text_editor_bottom_panel/fonts_tab.dart';
import '../widgets/text_editor_bottom_panel/shadow_value.dart';
import '../widgets/text_editor_bottom_panel/text_editor_bottom_panel.dart';
import '../widgets/text_editor_undo_manager.dart';
import '../widgets/text_shadow_panel.dart';

/// Dependencies required for building editor configs
/// 
/// This class encapsulates all the dependencies needed by the config builders,
/// allowing them to be pure functions while still having access to necessary state.
class EditorConfigDependencies {
  final bool isZoomEnabled;
  final bool useMaterialDesign;
  final int Function(BoxConstraints) calculateEmojiColumns;
  final void Function(BuildContext, Color, void Function(Color)) showColorPicker;
  final GlobalKey<GroundedMainBarState> mainEditorBarKey;
  final ScrollController toolbarScrollController;
  final EditorController controller;
  final void Function(ProImageEditorState) openReorderSheet;
  final void Function(TextEditorState, TextShadowConfig) applyShadowToTextStyle;
  /// Cached initial aspect ratio resolved from the format preset.
  /// Stored by the view so config rebuilds are idempotent.
  final double? initAspectRatio;

  const EditorConfigDependencies({
    required this.isZoomEnabled,
    required this.useMaterialDesign,
    required this.calculateEmojiColumns,
    required this.showColorPicker,
    required this.mainEditorBarKey,
    required this.toolbarScrollController,
    required this.controller,
    required this.openReorderSheet,
    required this.applyShadowToTextStyle,
    this.initAspectRatio,
  });
}

/// Builds all editor style configurations
/// 
/// Centralizes the construction of ProImageEditor configs to keep
/// the main view file focused on widget composition.
class EditorStyleConfigs {
  EditorStyleConfigs._();

  /// Builds localization strings for the editor
  static I18n buildI18n() {
    return I18n(
      importStateHistoryMsg: LocaleKeys.editor_opening_project.tr,
      doneLoadingMsg: LocaleKeys.editor_preparing_image.tr,
      various: I18nVarious(
        loadingDialogMsg: LocaleKeys.editor_preparing_editor.tr,
        closeEditorWarningTitle: LocaleKeys.editor_discard_changes.tr,
        closeEditorWarningMessage: LocaleKeys.editor_discard_message.tr,
        closeEditorWarningConfirmBtn: LocaleKeys.editor_discard.tr,
        closeEditorWarningCancelBtn: LocaleKeys.editor_keep_editing.tr,
      ),
      paintEditor: I18nPaintEditor(
        bottomNavigationBarText: LocaleKeys.tools_draw.tr,
        moveAndZoom: LocaleKeys.zoom_move_and_zoom.tr,
        freestyle: LocaleKeys.paint_freestyle.tr,
        freestyleArrowStart: LocaleKeys.paint_freestyle_arrow_start.tr,
        freestyleArrowEnd: LocaleKeys.paint_freestyle_arrow_end.tr,
        freestyleArrowStartEnd: LocaleKeys.paint_freestyle_arrow_both.tr,
        arrow: LocaleKeys.paint_arrow.tr,
        line: LocaleKeys.paint_line.tr,
        rectangle: LocaleKeys.paint_rectangle.tr,
        circle: LocaleKeys.paint_circle.tr,
        dashLine: LocaleKeys.paint_dash_line.tr,
        dashDotLine: LocaleKeys.paint_dash_dot_line.tr,
        hexagon: LocaleKeys.paint_hexagon.tr,
        polygon: LocaleKeys.paint_polygon.tr,
        blur: LocaleKeys.paint_blur.tr,
        pixelate: LocaleKeys.paint_pixelate.tr,
        eraser: LocaleKeys.paint_eraser.tr,
        lineWidth: LocaleKeys.paint_thickness.tr,
        changeOpacity: LocaleKeys.paint_opacity.tr,
        color: LocaleKeys.paint_color.tr,
        opacity: LocaleKeys.paint_opacity.tr,
        strokeWidth: LocaleKeys.paint_stroke_width.tr,
        fill: LocaleKeys.paint_fill.tr,
        toggleFill: LocaleKeys.paint_toggle_fill.tr,
        done: LocaleKeys.paint_done.tr,
        cancel: LocaleKeys.paint_cancel.tr,
        back: LocaleKeys.paint_back.tr,
        undo: LocaleKeys.paint_undo.tr,
        redo: LocaleKeys.paint_redo.tr,
        smallScreenMoreTooltip: LocaleKeys.paint_more.tr,
      ),
      textEditor: I18nTextEditor(
        inputHintText: LocaleKeys.text_editor_hint.tr,
        bottomNavigationBarText: LocaleKeys.tools_text.tr,
        textAlign: LocaleKeys.text_editor_align.tr,
        backgroundMode: LocaleKeys.text_editor_background.tr,
        fontScale: LocaleKeys.text_editor_font_scale.tr,
        done: LocaleKeys.text_editor_done.tr,
        back: LocaleKeys.text_editor_back.tr,
      ),
      cropRotateEditor: I18nCropRotateEditor(
        bottomNavigationBarText: LocaleKeys.tools_crop.tr,
        rotate: LocaleKeys.crop_rotate_rotate.tr,
        flip: LocaleKeys.crop_rotate_flip.tr,
        reset: LocaleKeys.crop_rotate_reset.tr,
      ),
      filterEditor: I18nFilterEditor(
        bottomNavigationBarText: LocaleKeys.tools_filter.tr,
      ),
      tuneEditor: I18nTuneEditor(
        bottomNavigationBarText: LocaleKeys.tools_tune.tr,
        brightness: LocaleKeys.tune_brightness.tr,
        contrast: LocaleKeys.tune_contrast.tr,
        saturation: LocaleKeys.tune_saturation.tr,
        exposure: LocaleKeys.tune_exposure.tr,
        temperature: LocaleKeys.tune_temperature.tr,
        sharpness: LocaleKeys.tune_sharpness.tr,
      ),
      blurEditor: I18nBlurEditor(
        bottomNavigationBarText: LocaleKeys.tools_blur.tr,
      ),
      emojiEditor: I18nEmojiEditor(
        bottomNavigationBarText: LocaleKeys.tools_emoji.tr,
        search: LocaleKeys.emoji_search.tr,
        categoryRecent: LocaleKeys.emoji_category_recent.tr,
        categorySmileys: LocaleKeys.emoji_category_smileys.tr,
        categoryAnimals: LocaleKeys.emoji_category_animals.tr,
        categoryFood: LocaleKeys.emoji_category_food.tr,
        categoryActivities: LocaleKeys.emoji_category_activities.tr,
        categoryTravel: LocaleKeys.emoji_category_travel.tr,
        categoryObjects: LocaleKeys.emoji_category_objects.tr,
        categorySymbols: LocaleKeys.emoji_category_symbols.tr,
        categoryFlags: LocaleKeys.emoji_category_flags.tr,
      ),
      stickerEditor: I18nStickerEditor(
        bottomNavigationBarText: LocaleKeys.tools_sticker.tr,
      ),
      done: LocaleKeys.common_done.tr,
      cancel: LocaleKeys.common_cancel.tr,
      undo: LocaleKeys.common_undo.tr,
      redo: LocaleKeys.common_redo.tr,
    );
  }

  /// Builds main editor configuration
  static MainEditorConfigs buildMainEditorConfigs(EditorConfigDependencies deps) {
    return MainEditorConfigs(
      // Disable top safe area so the glassmorphism appbar extends behind
      // the status bar (like Lightroom/VSCO). The appbar handles status-bar
      // padding internally, and Flutter's Scaffold automatically offsets
      // the body by viewPadding.top + appBar.preferredSize.height.
      safeArea: const EditorSafeArea(top: false),
      // Enable zoom in main editor (based on settings)
      enableZoom: deps.isZoomEnabled,
      editorMinScale: 0.8,
      editorMaxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(100),
      enableDoubleTapZoom: deps.isZoomEnabled,
      doubleTapZoomFactor: 2.0,
      tools: const [
        SubEditorMode.paint,
        SubEditorMode.text,
        SubEditorMode.cropRotate,
        SubEditorMode.tune,
        SubEditorMode.filter,
        SubEditorMode.blur,
        SubEditorMode.emoji,
        SubEditorMode.sticker,
      ],
      widgets: MainEditorWidgets(
        // Show our custom InShot-style draft exit sheet instead of the
        // built-in close-warning dialog. The sheet handles image capture
        // and draft persistence internally.
        closeWarningDialog: (editor) async {
          // Skip the sheet when there is nothing unsaved — the package
          // fires this whenever canUndo is true, but our state machine
          // knows about exports and draft saves too.
          if (deps.controller.canCloseSafely) return true;

          final result = await DraftExitSheet.show(
            editor: editor,
            controller: deps.controller,
          );
          switch (result) {
            case DraftAction.saved:
              // Draft persisted — let the package close the editor.
              return true;
            case DraftAction.discarded:
              // User chose to throw away changes.
              deps.controller.clearState();
              return true;
            case null:
              // Sheet dismissed — stay in the editor.
              return false;
          }
        },
        // Hide default remove area since FloatSelect has its own delete button
        removeLayerArea: (a, b, c, d) => const SizedBox.shrink(),
        // Clip the body so layers with Clip.none don't overflow behind
        // the bottom toolbar when dragged near the edge.
        wrapBody: (editor, rebuildStream, content) =>
            ClipRect(child: content),
        // Floating action buttons (left side)
        bodyItems: (editor, rebuildStream) {
          return [
            // Reorder Layers button (always visible when layers exist)
            ReactiveWidget(
              stream: rebuildStream,
              builder: (_) => editor.isLayerBeingTransformed || editor.isSubEditorOpen
                  ? const SizedBox.shrink()
                  : PositionedDirectional(
                      bottom: deps.isZoomEnabled ? 70 : 20, // Stack above zoom button
                      start: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: GroundedTheme.primary,
                          borderRadius: const BorderRadiusDirectional.only(
                            topEnd: Radius.circular(100),
                            bottomEnd: Radius.circular(100),
                          ),
                        ),
                        child: GestureInterceptor(
                          child: IconButton(
                            tooltip: LocaleKeys.layer_reorder.tr,
                            onPressed: editor.activeLayers.isEmpty
                                ? null
                                : () => deps.openReorderSheet(editor),
                            icon: Icon(
                              Icons.layers,
                              color: editor.activeLayers.isEmpty
                                  ? Colors.white38
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            // Reset zoom button (shown when zoom is enabled)
            if (deps.isZoomEnabled)
              ReactiveWidget(
                stream: rebuildStream,
                builder: (_) => editor.isLayerBeingTransformed || editor.isSubEditorOpen
                    ? const SizedBox.shrink()
                    : PositionedDirectional(
                        bottom: 20,
                        start: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: GroundedTheme.primary,
                            borderRadius: const BorderRadiusDirectional.only(
                              topEnd: Radius.circular(100),
                              bottomEnd: Radius.circular(100),
                            ),
                          ),
                          child: GestureInterceptor(
                            child: IconButton(
                              tooltip: LocaleKeys.zoom_reset.tr,
                              onPressed: editor.resetZoom,
                              icon: const Icon(
                                Icons.zoom_out_map_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
          ];
        },
        appBar: (editor, rebuildStream) => ReactiveAppbar(
          stream: rebuildStream,
          appbarSize: const Size.fromHeight(
            MainEditorAppBarCustom.barHeight,
          ),
          builder: (_) => MainEditorAppBarCustom(editor: editor),
        ),
        bottomBar: (editor, rebuildStream, key) => ReactiveWidget(
          key: key,
          builder: (context) {
            return MainEditorBottomBarCustom(
              editor: editor,
              configs: editor.configs,
              callbacks: editor.callbacks,
              toolbarScrollController: deps.toolbarScrollController,
            );
          },
          stream: rebuildStream,
        ),
      ),
      // Editor always uses dark theme (industry standard for photo editors)
      style: const MainEditorStyle(
        background: GroundedTheme.backgroundDark,
        bottomBarBackground: GroundedTheme.surfaceDark,
        appBarColor: GroundedTheme.textPrimaryDark,
        uiOverlayStyle: GroundedTheme.darkOverlayStyle,
      ),
    );
  }

  /// Builds paint editor configuration
  static PaintEditorConfigs buildPaintEditorConfigs(EditorConfigDependencies deps) {
    return PaintEditorConfigs(
      // Enable zoom in paint editor (moveAndZoom tool) based on settings
      enableZoom: deps.isZoomEnabled,
      editorMinScale: 0.8,
      editorMaxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(100),
      enableDoubleTapZoom: deps.isZoomEnabled,
      // Editor always uses dark theme
      style: const PaintEditorStyle(
        background: GroundedTheme.backgroundDark,
        bottomBarBackground: GroundedTheme.surfaceDark,
        appBarColor: GroundedTheme.textPrimaryDark,
        initialStrokeWidth: 5,
        uiOverlayStyle: GroundedTheme.darkOverlayStyle,
      ),
      // Custom zoom icon for paint editor
      icons: const PaintEditorIcons(
        moveAndZoom: Icons.pinch_outlined,
      ),
      widgets: PaintEditorWidgets(
        appBar: (paintEditor, rebuildStream) => ReactiveAppbar(
          stream: rebuildStream,
          appbarSize: const Size.fromHeight(SubEditorAppBar.barHeight),
          builder: (_) => SubEditorAppBar(
            onClose: paintEditor.close,
            onDone: paintEditor.done,
            onUndo: paintEditor.undoAction,
            onRedo: paintEditor.redoAction,
            canUndo: paintEditor.canUndo,
            canRedo: paintEditor.canRedo,
          ),
        ),
        colorPicker: (paintEditor, rebuildStream, currentColor, setColor) =>
            null,
        bottomBar: (editorState, rebuildStream) {
          return ReactiveWidget(
            builder: (context) {
              return GroundedPaintBar(
                configs: editorState.configs,
                callbacks: editorState.callbacks,
                editor: editorState,
                showActionBar: false,
                i18nColor: LocaleKeys.paint_color.tr,
                showColorPicker: (currentColor) {
                  Color? newColor;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: currentColor,
                          onColorChanged: (color) {
                            newColor = color;
                          },
                        ),
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          child: Text(LocaleKeys.paint_done.tr),
                          onPressed: () {
                            if (newColor != null) {
                              editorState.setColor(newColor!);
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            stream: rebuildStream,
          );
        },
      ),
    );
  }

  /// Font categories for the bottom panel font tab
  static List<FontCategory> _buildFontCategories() {
    return [
      FontCategory(
        label: LocaleKeys.text_editor_english_fonts.tr,
        fonts: FontCatalog.englishFonts,
      ),
      FontCategory(
        label: LocaleKeys.text_editor_farsi_fonts.tr,
        fonts: FontCatalog.persianFonts,
      ),
    ];
  }

  /// Builds text editor configuration
  static TextEditorConfigs buildTextEditorConfigs(EditorConfigDependencies deps) {
    // Shared undo manager — captured by both appBar and bodyItems closures.
    final undoManager = TextEditorUndoManager();

    return TextEditorConfigs(
      customTextStyles: FontCatalog.toTextStyles(),
      showSelectFontStyleBottomBar: false,
      // Disable tap-outside-to-save because our custom bottom panel
      // sits inside the same GestureDetector(behavior: translucent)
      // and taps on panel controls would dismiss the editor.
      enableTapOutsideToSave: false,
      // Default to background with opacity for a softer look
      initialBackgroundColorMode: LayerBackgroundMode.backgroundAndColorWithOpacity,
      // Editor always uses dark theme
      style: const TextEditorStyle(
        // faiz height adjustment to better center text vertically
        textHeight: null,
        // Even distribution centres glyphs inside their rounded background
        // rects when lineHeight > 1.0 (default proportional skews ~75/25).
        leadingDistribution: TextLeadingDistribution.even,
        // Static margin — pro_image_editor doesn't support dynamic values.
        // 280 covers the tab bar (~57) + safe area (~34) + tallest default
        // content (~210 style tab). Expanded states (HSV picker, shadow)
        // may exceed this but are transient interaction states.
        textFieldMargin: EdgeInsets.only(top: kToolbarHeight, bottom: 280),
        bottomBarBackground: GroundedTheme.surfaceDark,
        appBarColor: GroundedTheme.textPrimaryDark,
        bottomBarMainAxisAlignment: MainAxisAlignment.start,
      ),
      widgets: TextEditorWidgets(
        appBar: (textEditor, rebuildStream) => ReactiveAppbar(
          stream: rebuildStream,
          builder: (_) => TextEditorAppBar(
            textEditor: textEditor,
            undoManager: undoManager,
          ),
        ),
        colorPicker: (textEditor, rebuildStream, currentColor, setColor) => null,
        bottomBar: (editorState, rebuildStream) => null,
        bodyItems: (textEditor, rebuildStream) => [
          ReactiveWidget(
            stream: rebuildStream,
            builder: (_) {
              // Capture state for undo/redo after the current frame
              // to avoid calling notifyListeners() during build.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                undoManager.capture(textEditor);
              });
              // Empty SizedBox — bodyItems sit under the text field,
              // so the actual panel is placed in bodyItemsOverlay instead.
              return const SizedBox.shrink();
            },
          ),
        ],
        // Place the panel in bodyItemsOverlay so it renders ON TOP of the
        // text field and receives taps correctly.
        bodyItemsOverlay: (textEditor, rebuildStream) => [
          ReactiveWidget(
            stream: rebuildStream,
            builder: (_) {
              // Extract letter spacing and line height from current style
              final style = textEditor.selectedTextStyle;
              final letterSpacing = style.letterSpacing ?? 0.0;
              final lineHeight = style.height ?? 1.2;
              final shadow = ShadowValue.fromStyle(style);
              final isBold = style.fontWeight == FontWeight.bold ||
                  style.fontWeight == FontWeight.w700 ||
                  style.fontWeight == FontWeight.w800 ||
                  style.fontWeight == FontWeight.w900;
              final isItalic = style.fontStyle == FontStyle.italic;

              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: TextEditorBottomPanel(
                    // Color
                    currentColor: textEditor.primaryColor,
                    onColorChanged: (c) => textEditor.primaryColor = c,
                    opacity: textEditor.primaryColor.a,
                    onOpacityChanged: (v) {
                      final c = textEditor.primaryColor;
                      textEditor.primaryColor = c.withValues(alpha: v);
                    },
                    // Fonts
                    fontCategories: _buildFontCategories(),
                    selectedStyle: textEditor.selectedTextStyle,
                    onStyleChanged: textEditor.setTextStyle,
                    textController: textEditor.textCtrl,
                    // Style
                    align: textEditor.align,
                    onAlignChanged: (a) {
                      textEditor.align = a;
                      // align is a raw field — trigger rebuild via setTextStyle
                      textEditor.setTextStyle(textEditor.selectedTextStyle);
                    },
                    backgroundMode: textEditor.backgroundColorMode,
                    onBgModeChanged: (mode) {
                      // Cycle toggleBackgroundMode until desired mode is reached
                      while (textEditor.backgroundColorMode != mode) {
                        textEditor.toggleBackgroundMode();
                      }
                    },
                    isBold: isBold,
                    onBoldChanged: (v) {
                      final s = textEditor.selectedTextStyle;
                      textEditor.setTextStyle(s.copyWith(
                        fontWeight: v ? FontWeight.bold : FontWeight.normal,
                      ));
                    },
                    isItalic: isItalic,
                    onItalicChanged: (v) {
                      final s = textEditor.selectedTextStyle;
                      textEditor.setTextStyle(s.copyWith(
                        fontStyle: v ? FontStyle.italic : FontStyle.normal,
                      ));
                    },
                    fontScale: textEditor.fontScale,
                    minFontScale: 0.4,
                    maxFontScale: 3.0,
                    onFontScaleChanged: (v) => textEditor.fontScale = v,
                    // Letter spacing & line height
                    letterSpacing: letterSpacing,
                    onLetterSpacingChanged: (v) {
                      final s = textEditor.selectedTextStyle;
                      textEditor.setTextStyle(s.copyWith(letterSpacing: v));
                    },
                    lineHeight: lineHeight,
                    onLineHeightChanged: (v) {
                      final s = textEditor.selectedTextStyle;
                      textEditor.setTextStyle(s.copyWith(height: v));
                    },
                    // Shadow
                    shadow: shadow,
                    onShadowChanged: (sv) {
                      final s = textEditor.selectedTextStyle;
                      textEditor.setTextStyle(s.copyWith(shadows: sv.toShadows()));
                    },
                  ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds crop/rotate editor configuration
  static CropRotateEditorConfigs buildCropRotateEditorConfigs(EditorConfigDependencies deps) {
    return CropRotateEditorConfigs(
      // Set initial aspect ratio from cached format preset (survives config rebuilds)
      initAspectRatio: deps.initAspectRatio,
      // Social media optimized aspect ratios
      aspectRatios: [
        AspectRatioItem(text: LocaleKeys.crop_rotate_free.tr, value: -1),
        AspectRatioItem(text: LocaleKeys.crop_rotate_original.tr, value: 0.0),
        AspectRatioItem(text: '16:9', value: 16.0 / 9.0),  // YouTube/landscape
        AspectRatioItem(text: '9:16', value: 9.0 / 16.0),  // TikTok/Reels/Stories
        AspectRatioItem(text: '4:5', value: 4.0 / 5.0),    // Instagram feed
        AspectRatioItem(text: '1:1', value: 1.0),          // Square
        AspectRatioItem(text: '1.91:1', value: 1.91),      // Facebook/Twitter
        AspectRatioItem(text: '21:9', value: 21.0 / 9.0),  // Cinematic ultrawide
        AspectRatioItem(text: '4:3', value: 4.0 / 3.0),
        AspectRatioItem(text: '3:4', value: 3.0 / 4.0),
      ],
      // Editor always uses dark theme
      style: const CropRotateEditorStyle(
        cropCornerColor: GroundedTheme.textPrimaryDark,
        cropCornerLength: 36,
        cropCornerThickness: 4,
        background: GroundedTheme.backgroundDark,
        bottomBarBackground: GroundedTheme.surfaceDark,
        appBarColor: GroundedTheme.textPrimaryDark,
        helperLineColor: Color(0x25FFFFFF),
        uiOverlayStyle: GroundedTheme.darkOverlayStyle,
      ),
      widgets: CropRotateEditorWidgets(
        appBar: (cropRotateEditor, rebuildStream) => ReactiveAppbar(
          stream: rebuildStream,
          appbarSize: const Size.fromHeight(SubEditorAppBar.barHeight),
          builder: (_) => SubEditorAppBar(
            onClose: cropRotateEditor.close,
            onDone: cropRotateEditor.done,
            onUndo: cropRotateEditor.undoAction,
            onRedo: cropRotateEditor.redoAction,
            canUndo: cropRotateEditor.canUndo,
            canRedo: cropRotateEditor.canRedo,
          ),
        ),
        bottomBar: (cropRotateEditor, rebuildStream) => ReactiveWidget(
          stream: rebuildStream,
          builder: (_) => GroundedCropRotateBar(
            configs: cropRotateEditor.configs,
            callbacks: cropRotateEditor.callbacks,
            editor: cropRotateEditor,
            selectedRatioColor: GroundedTheme.primary,
            showActionBar: false,
          ),
        ),
      ),
    );
  }

  /// Builds filter editor configuration
  static FilterEditorConfigs buildFilterEditorConfigs() {
    return FilterEditorConfigs(
      fadeInUpDuration: kGroundedFadeInDuration,
      fadeInUpStaggerDelayDuration: kGroundedFadeInStaggerDelay,
      // Editor always uses dark theme
      style: const FilterEditorStyle(
        filterListSpacing: 7,
        filterListMargin: EdgeInsets.fromLTRB(8, 0, 8, 8),
        background: GroundedTheme.backgroundDark,
        uiOverlayStyle: GroundedTheme.darkOverlayStyle,
      ),
      widgets: FilterEditorWidgets(
        slider: (editorState, rebuildStream, value, onChanged, onChangeEnd) =>
            ReactiveWidget(
          stream: rebuildStream,
          builder: (_) => Slider(
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            value: value,
            activeColor: Colors.blue.shade200,
          ),
        ),
        appBar: (editorState, rebuildStream) => ReactiveAppbar(
          stream: rebuildStream,
          appbarSize: const Size.fromHeight(SubEditorAppBar.barHeight),
          builder: (_) => SubEditorAppBar(
            onClose: editorState.close,
            onDone: editorState.done,
          ),
        ),
        bottomBar: (editorState, rebuildStream) {
          return ReactiveWidget(
            builder: (context) {
              return GroundedFilterBar(
                configs: editorState.configs,
                callbacks: editorState.callbacks,
                editor: editorState,
                showActionBar: false,
              );
            },
            stream: rebuildStream,
          );
        },
      ),
    );
  }

  /// Builds tune editor configuration
  static TuneEditorConfigs buildTuneEditorConfigs() {
    return TuneEditorConfigs(
      // Editor always uses dark theme
      style: const TuneEditorStyle(
        background: GroundedTheme.backgroundDark,
        bottomBarBackground: GroundedTheme.surfaceDark,
        uiOverlayStyle: GroundedTheme.darkOverlayStyle,
      ),
      widgets: TuneEditorWidgets(
        appBar: (editor, rebuildStream) => ReactiveAppbar(
          stream: rebuildStream,
          appbarSize: const Size.fromHeight(SubEditorAppBar.barHeight),
          builder: (_) => SubEditorAppBar(
            onClose: editor.close,
            onDone: editor.done,
            onUndo: editor.undo,
            onRedo: editor.redo,
            canUndo: editor.canUndo,
            canRedo: editor.canRedo,
          ),
        ),
        bottomBar: (editorState, rebuildStream) {
          return ReactiveWidget(
            builder: (context) {
              return GroundedTuneBar(
                configs: editorState.configs,
                callbacks: editorState.callbacks,
                editor: editorState,
                showActionBar: false,
              );
            },
            stream: rebuildStream,
          );
        },
      ),
    );
  }

  /// Builds blur editor configuration
  static BlurEditorConfigs buildBlurEditorConfigs() {
    return BlurEditorConfigs(
      // Editor always uses dark theme
      style: const BlurEditorStyle(
        background: GroundedTheme.backgroundDark,
        uiOverlayStyle: GroundedTheme.darkOverlayStyle,
      ),
      widgets: BlurEditorWidgets(
        appBar: (blurEditor, rebuildStream) => ReactiveAppbar(
          stream: rebuildStream,
          appbarSize: const Size.fromHeight(SubEditorAppBar.barHeight),
          builder: (_) => SubEditorAppBar(
            onClose: blurEditor.close,
            onDone: blurEditor.done,
          ),
        ),
        bottomBar: (editorState, rebuildStream) {
          return ReactiveWidget(
            builder: (context) {
              return GroundedBlurBar(
                configs: editorState.configs,
                callbacks: editorState.callbacks,
                editor: editorState,
                showActionBar: false,
              );
            },
            stream: rebuildStream,
          );
        },
      ),
    );
  }

  /// Builds emoji editor configuration
  static EmojiEditorConfigs buildEmojiEditorConfigs(
    EditorConfigDependencies deps,
    BoxConstraints constraints,
  ) {
    return EmojiEditorConfigs(
      checkPlatformCompatibility: !kIsWeb,
      style: EmojiEditorStyle(
        backgroundColor: Colors.transparent,
        textStyle: DefaultEmojiTextStyle.copyWith(
          fontSize: deps.useMaterialDesign ? 36 : 30,
        ),
        emojiViewConfig: EmojiViewConfig(
          gridPadding: EdgeInsets.zero,
          horizontalSpacing: 0,
          verticalSpacing: 0,
          recentsLimit: 28,
          backgroundColor: Colors.transparent,
          noRecents: Text(
            LocaleKeys.emoji_no_recents.tr,
            style: const TextStyle(fontSize: 20, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          buttonMode: !deps.useMaterialDesign
              ? ButtonMode.CUPERTINO
              : ButtonMode.MATERIAL,
          loadingIndicator: const Center(child: CircularProgressIndicator()),
          columns: deps.calculateEmojiColumns(constraints),
          emojiSizeMax: !deps.useMaterialDesign ? 32 : 40,
          replaceEmojiOnLimitExceed: false,
        ),
        bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
      ),
    );
  }

  /// Builds sticker editor configuration
  static StickerEditorConfigs buildStickerEditorConfigs() {
    // Note: Sticker editor is handled by CustomStickerEditor opened via MainEditorBottomBarCustom
    // This config is only used as a fallback and to enable the sticker feature
    return StickerEditorConfigs(
      builder: (setLayer, scrollController) => const SizedBox.shrink(),
    );
  }

  /// Builds layer interaction configuration
  static LayerInteractionConfigs buildLayerInteractionConfigs() {
    return LayerInteractionConfigs(
      // Enable layer selection on all platforms
      selectable: LayerInteractionSelectable.enabled,
      // Don't auto-select to prevent viewport shifting
      initialSelected: false,
      // Keep selection visible after interaction
      keepSelectionOnInteraction: true,
      // Don't hide toolbar on interaction
      hideToolbarOnInteraction: false,
      // Enable multi-selection via long press on mobile
      enableLongPressMultiSelection: true,
      // Enable pinch gestures for layers on mobile
      enableMobilePinchScale: true,
      enableMobilePinchRotate: true,
    );
  }

  /// Builds dialog configuration
  static DialogConfigs buildDialogConfigs() {
    return DialogConfigs(
      widgets: DialogWidgets(
        loadingDialog: (message, configs) => EditorLoadingOverlay(
          message: message,
          configs: configs,
        ),
      ),
    );
  }
}
