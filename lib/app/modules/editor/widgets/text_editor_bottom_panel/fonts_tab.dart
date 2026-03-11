import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../generated/locales.g.dart';
import '../../../../core/fonts/font_catalog.dart';
import 'panel_theme.dart';

/// Callback for selecting a font style.
typedef FontStyleCallback = void Function(TextStyle style);

/// A single font category (e.g. English fonts, Farsi fonts).
class FontCategory {
  final String label;
  final List<FontEntry> fonts;

  const FontCategory({required this.label, required this.fonts});
}

/// Fonts tab with language segmented control and horizontal font chip strip.
///
/// Auto-font state is owned by [TextEditorBottomPanel] (which survives tab
/// switches). This widget is purely presentational — it receives [isAutoFont]
/// and fires [onAutoModeEnabled] / [onManualFontSelected] callbacks.
class FontsTab extends StatefulWidget {
  const FontsTab({
    super.key,
    required this.fontCategories,
    required this.selectedStyle,
    required this.onStyleChanged,
    required this.isAutoFont,
    required this.onAutoModeEnabled,
    required this.onManualFontSelected,
  });

  final List<FontCategory> fontCategories;
  final TextStyle selectedStyle;
  final FontStyleCallback onStyleChanged;

  /// Whether automatic language-based font selection is active.
  final bool isAutoFont;

  /// Called when the user taps the "Auto" chip to re-enable auto mode.
  final VoidCallback onAutoModeEnabled;

  /// Called when the user manually picks a font (disables auto mode).
  final VoidCallback onManualFontSelected;

  @override
  State<FontsTab> createState() => _FontsTabState();
}

class _FontsTabState extends State<FontsTab> {
  late int _activeCategoryIndex;
  late ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _activeCategoryIndex = _detectCategory();
  }

  @override
  void didUpdateWidget(FontsTab old) {
    super.didUpdateWidget(old);
    if (old.selectedStyle.fontFamily != widget.selectedStyle.fontFamily) {
      final detected = _detectCategory();
      if (detected != _activeCategoryIndex) {
        setState(() {
          _activeCategoryIndex = detected;
          if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Auto-detect which category the current font belongs to.
  int _detectCategory() {
    final family = widget.selectedStyle.fontFamily;
    for (var i = 0; i < widget.fontCategories.length; i++) {
      for (final font in widget.fontCategories[i].fonts) {
        if (font.family == family) return i;
      }
    }
    return 0;
  }

  void _switchCategory(int index) {
    if (index == _activeCategoryIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeCategoryIndex = index;
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
    });
  }

  void _selectFont(FontEntry font) {
    HapticFeedback.selectionClick();
    // Manual font pick — tell parent to disable auto mode.
    widget.onManualFontSelected();
    final current = widget.selectedStyle;
    final newStyle = current.copyWith(fontFamily: font.family);
    widget.onStyleChanged(newStyle);
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.fontCategories;
    if (categories.isEmpty) return const SizedBox.shrink();

    final activeFonts = categories[_activeCategoryIndex].fonts;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        // Segmented control
        _buildSegmentedControl(categories),
        const SizedBox(height: 12),
        // Font chip strip (with leading Auto chip)
        SizedBox(
          height: 44,
          child: ListView.builder(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // +1 for the Auto chip at index 0
            itemCount: activeFonts.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _AutoChip(
                    isActive: widget.isAutoFont,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onAutoModeEnabled();
                    },
                  ),
                );
              }
              final font = activeFonts[i - 1];
              final isSelected =
                  !widget.isAutoFont && widget.selectedStyle.fontFamily == font.family;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: _FontChip(
                  font: font,
                  isSelected: isSelected,
                  onTap: () => _selectFont(font),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSegmentedControl(List<FontCategory> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: PanelTheme.surfaceFaint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: List.generate(categories.length, (i) {
            final active = i == _activeCategoryIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => _switchCategory(i),
                behavior: HitTestBehavior.opaque,
                child: Semantics(
                  label: categories[i].label,
                  selected: active,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? PanelTheme.surfaceMedium
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      categories[i].label,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        fontFamily: i == 1 ? 'Vazir' : null, // Farsi tab
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

/// A single font chip showing "Aa" in the actual font with name below.
class _FontChip extends StatelessWidget {
  const _FontChip({
    required this.font,
    required this.isSelected,
    required this.onTap,
  });

  final FontEntry font;
  final bool isSelected;
  final VoidCallback onTap;

  static const _gradient = PanelTheme.accentGradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: LocaleKeys.text_editor_a11y_font.trArgs([font.displayName]),
        selected: isSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected ? _gradient : null,
            color: isSelected ? null : PanelTheme.surfaceSubtle,
            border: isSelected
                ? null
                : Border.all(
                    color: PanelTheme.surfaceMedium, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                font.group == FontGroup.persian ? 'الف' : 'Aa',
                textDirection: font.group == FontGroup.persian
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: TextStyle(
                  fontFamily: font.family,
                  fontSize: 16,
                  height: 1.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                font.displayName.length > 10
                    ? '${font.displayName.substring(0, 9)}…'
                    : font.displayName,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.0,
                  color: isSelected ? Colors.white70 : Colors.white38,
                  fontFamily: font.group == FontGroup.persian ? 'Vazir' : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Auto" chip — re-enables automatic language-based font selection.
class _AutoChip extends StatelessWidget {
  const _AutoChip({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;

  static const _gradient = PanelTheme.accentGradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: LocaleKeys.text_editor_a11y_auto_font.tr,
        selected: isActive,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isActive ? _gradient : null,
            color: isActive ? null : PanelTheme.surfaceSubtle,
            border: isActive
                ? null
                : Border.all(color: PanelTheme.surfaceMedium, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: isActive ? Colors.white : Colors.white54,
              ),
              const SizedBox(height: 2),
              Text(
                LocaleKeys.text_editor_font_auto.tr,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.0,
                  color: isActive ? Colors.white70 : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
