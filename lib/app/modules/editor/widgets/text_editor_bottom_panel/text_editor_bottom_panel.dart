import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../../generated/locales.g.dart';
import '../../../../core/fonts/font_catalog.dart';
import '../../../../core/theme/grounded_theme.dart';
import 'color_tab.dart';
import 'fonts_tab.dart';
import 'panel_theme.dart';
import 'shadow_tab.dart';
import 'shadow_value.dart';
import 'style_tab.dart';

/// Unified frosted-glass bottom panel for the text editor.
///
/// Owns tab state, renders the glass container and animated tab bar,
/// and delegates content rendering to [ColorTab], [FontsTab],
/// [StyleTab], and [ShadowTab].
///
/// Intentionally flat constructor — every prop is explicit so the widget
/// remains pure and testable.
class TextEditorBottomPanel extends StatefulWidget {
  const TextEditorBottomPanel({
    super.key,
    // Color
    required this.currentColor,
    required this.onColorChanged,
    required this.opacity,
    required this.onOpacityChanged,
    // Fonts
    required this.fontCategories,
    required this.selectedStyle,
    required this.onStyleChanged,
    this.textController,
    // Style
    required this.align,
    required this.onAlignChanged,
    required this.isBold,
    required this.onBoldChanged,
    required this.isItalic,
    required this.onItalicChanged,
    required this.backgroundMode,
    required this.onBgModeChanged,
    required this.fontScale,
    required this.minFontScale,
    required this.maxFontScale,
    required this.onFontScaleChanged,
    // Letter spacing & line height
    required this.letterSpacing,
    required this.onLetterSpacingChanged,
    required this.lineHeight,
    required this.onLineHeightChanged,
    // Shadow
    required this.shadow,
    required this.onShadowChanged,
  });

  // ── Color ──
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  final double opacity;
  final ValueChanged<double> onOpacityChanged;

  // ── Fonts ──
  final List<FontCategory> fontCategories;
  final TextStyle selectedStyle;
  final FontStyleCallback onStyleChanged;
  final TextEditingController? textController;

  // ── Style ──
  final TextAlign align;
  final ValueChanged<TextAlign> onAlignChanged;
  final bool isBold;
  final ValueChanged<bool> onBoldChanged;
  final bool isItalic;
  final ValueChanged<bool> onItalicChanged;
  final LayerBackgroundMode backgroundMode;
  final ValueChanged<LayerBackgroundMode> onBgModeChanged;
  final double fontScale;
  final double minFontScale;
  final double maxFontScale;
  final ValueChanged<double> onFontScaleChanged;
  final double letterSpacing;
  final ValueChanged<double> onLetterSpacingChanged;
  final double lineHeight;
  final ValueChanged<double> onLineHeightChanged;

  // ── Shadow ──
  final ShadowValue shadow;
  final ValueChanged<ShadowValue> onShadowChanged;

  @override
  State<TextEditorBottomPanel> createState() => _TextEditorBottomPanelState();
}

class _TextEditorBottomPanelState extends State<TextEditorBottomPanel> {
  int _tab = 0;
  int _prevTab = 0;
  static const _tabCount = 4;

  // ── Auto-font state (lives here so it survives tab switches) ──
  bool _isAutoFont = true;
  FontGroup _currentAutoGroup = FontGroup.english;

  static const _icons = [
    Icons.palette_outlined,
    Icons.text_fields_rounded,
    Icons.tune_rounded,
    Icons.blur_on_rounded,
  ];

  List<String> get _labels => [
        LocaleKeys.text_editor_tab_color.tr,
        LocaleKeys.text_editor_tab_fonts.tr,
        LocaleKeys.text_editor_tab_style.tr,
        LocaleKeys.text_editor_tab_shadow.tr,
      ];

  void _switchTab(int i) {
    if (i == _tab || i < 0 || i >= _tabCount) return;
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _prevTab = _tab;
      _tab = i;
    });
  }

  // ── Lifecycle ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final hasExistingText =
        widget.textController?.text.isNotEmpty ?? false;
    _isAutoFont = !hasExistingText;
    if (hasExistingText) {
      _currentAutoGroup = FontCatalog.detectLanguage(
        widget.textController!.text,
      );
    } else {
      // Match the initial font to the app locale so the placeholder
      // text renders with the correct font family (e.g. Vazir for fa).
      final isPersianLocale = Get.locale?.languageCode == 'fa';
      if (isPersianLocale) {
        _currentAutoGroup = FontGroup.persian;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _applyDefaultFont(FontGroup.persian);
        });
      }
    }
    widget.textController?.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(TextEditorBottomPanel old) {
    super.didUpdateWidget(old);
    if (old.textController != widget.textController) {
      old.textController?.removeListener(_onTextChanged);
      widget.textController?.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.textController?.removeListener(_onTextChanged);
    super.dispose();
  }

  // ── Auto-font detection ─────────────────────────────────────────

  Timer? _debounce;

  void _onTextChanged() {
    if (!_isAutoFont) return;
    // Debounce rapid keystrokes (300 ms) so the font doesn't flicker
    // on mixed-language text.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || !_isAutoFont) return;
      _detectAndApply(widget.textController?.text ?? '');
    });
  }

  void _detectAndApply(String text) {
    // When text is cleared, reset the auto group so the very first
    // character of new text gets a fresh detection.
    if (text.isEmpty) {
      _currentAutoGroup = FontGroup.english;
      return;
    }

    final detected = FontCatalog.detectLanguage(
      text,
      currentGroup: _currentAutoGroup,
    );
    if (detected == _currentAutoGroup && _isCurrentFontInGroup(detected)) {
      return;
    }
    _currentAutoGroup = detected;
    if (!_isCurrentFontInGroup(detected)) {
      _applyDefaultFont(detected);
    }
  }

  bool _isCurrentFontInGroup(FontGroup group) {
    final family = widget.selectedStyle.fontFamily;
    final fonts = group == FontGroup.persian
        ? FontCatalog.persianFonts
        : FontCatalog.englishFonts;
    return fonts.any((f) => f.family == family);
  }

  void _applyDefaultFont(FontGroup group) {
    final defaultFont = group == FontGroup.persian
        ? FontCatalog.defaultPersianFont
        : FontCatalog.defaultEnglishFont;
    final current = widget.selectedStyle;
    widget.onStyleChanged(current.copyWith(fontFamily: defaultFont.family));
  }

  void _enableAutoMode() {
    _debounce?.cancel();
    setState(() {
      _isAutoFont = true;
      _currentAutoGroup = FontCatalog.detectLanguage(
        widget.textController?.text ?? '',
      );
    });
    _detectAndApply(widget.textController?.text ?? '');
  }

  void _disableAutoMode() {
    setState(() => _isAutoFont = false);
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = GroundedTheme.currentFontFamily;

    return DefaultTextStyle(
      style: TextStyle(fontFamily: fontFamily),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xE6101018),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Content area — animated switcher with directional slide
                    _buildContent(),
                    // Separator
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.white10,
                    ),
                    // Tab bar — bottom-anchored for thumb reachability
                    _buildTabBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final pages = <Widget>[
      ColorTab(
        key: const ValueKey(0),
        currentColor: widget.currentColor,
        onColorChanged: widget.onColorChanged,
        opacity: widget.opacity,
        onOpacityChanged: widget.onOpacityChanged,
      ),
      FontsTab(
        key: const ValueKey(1),
        fontCategories: widget.fontCategories,
        selectedStyle: widget.selectedStyle,
        onStyleChanged: widget.onStyleChanged,
        isAutoFont: _isAutoFont,
        onAutoModeEnabled: _enableAutoMode,
        onManualFontSelected: _disableAutoMode,
      ),
      StyleTab(
        key: const ValueKey(2),
        align: widget.align,
        onAlignChanged: widget.onAlignChanged,
        isBold: widget.isBold,
        onBoldChanged: widget.onBoldChanged,
        isItalic: widget.isItalic,
        onItalicChanged: widget.onItalicChanged,
        backgroundMode: widget.backgroundMode,
        onBgModeChanged: widget.onBgModeChanged,
        fontScale: widget.fontScale,
        minFontScale: widget.minFontScale,
        maxFontScale: widget.maxFontScale,
        onFontScaleChanged: widget.onFontScaleChanged,
        letterSpacing: widget.letterSpacing,
        onLetterSpacingChanged: widget.onLetterSpacingChanged,
        lineHeight: widget.lineHeight,
        onLineHeightChanged: widget.onLineHeightChanged,
      ),
      ShadowTab(
        key: const ValueKey(3),
        shadow: widget.shadow,
        onShadowChanged: widget.onShadowChanged,
      ),
    ];

    // Slide direction: new tab slides in from the side it's on
    final goingForward = _tab > _prevTab;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          // Determine direction: incoming widget slides from the right (forward)
          // or left (backward); outgoing widget slides the opposite way.
          final isIncoming =
              child.key == ValueKey(_tab);
          final beginOffset = isIncoming
              ? Offset(goingForward ? 0.3 : -0.3, 0)
              : Offset(goingForward ? -0.3 : 0.3, 0);

          return SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: pages[_tab],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: PanelTheme.surfaceFaint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: List.generate(4, (i) {
            final active = i == _tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => _switchTab(i),
                behavior: HitTestBehavior.opaque,
                child: Semantics(
                  label: _labels[i],
                  selected: active,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: active
                          ? PanelTheme.accent.withValues(alpha: 0.25)
                          : Colors.transparent,
                      border: active
                          ? Border.all(
                              color: PanelTheme.accent.withValues(alpha: 0.4),
                            )
                          : null,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: PanelTheme.accent.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: -1,
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _icons[i],
                            size: 17,
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _labels[i],
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

}
