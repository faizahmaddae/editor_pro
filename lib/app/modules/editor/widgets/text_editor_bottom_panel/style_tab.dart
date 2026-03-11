import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../../generated/locales.g.dart';
import 'panel_theme.dart';

/// Style tab with alignment, bold/italic, background mode, font scale,
/// letter spacing, and line height controls.
class StyleTab extends StatelessWidget {
  const StyleTab({
    super.key,
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
    required this.letterSpacing,
    required this.onLetterSpacingChanged,
    required this.lineHeight,
    required this.onLineHeightChanged,
  });

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

  // ── Defaults ──
  static const double _defaultFontScale = 1.0;
  static const double _defaultLetterSpacing = 0.0;
  static const double _defaultLineHeight = 1.2;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Alignment
          _buildAlignmentRow(),
          const SizedBox(height: 14),
          // Bold / Italic
          _buildFormattingRow(),
          const SizedBox(height: 14),
          // Background mode
          _buildBgModeRow(),
          const SizedBox(height: 14),
          // Font scale slider
          _buildSliderRow(
            label: LocaleKeys.text_editor_font_scale.tr,
            value: fontScale,
            min: minFontScale,
            max: maxFontScale,
            defaultValue: _defaultFontScale,
            displayValue: '${(fontScale * 100).round()}%',
            onChanged: onFontScaleChanged,
            onReset: () => onFontScaleChanged(_defaultFontScale),
          ),
          const SizedBox(height: 10),
          // Letter spacing slider
          _buildSliderRow(
            label: LocaleKeys.text_editor_letter_spacing.tr,
            value: letterSpacing,
            min: -2,
            max: 20,
            defaultValue: _defaultLetterSpacing,
            displayValue: letterSpacing.toStringAsFixed(1),
            onChanged: onLetterSpacingChanged,
            onReset: () => onLetterSpacingChanged(_defaultLetterSpacing),
          ),
          const SizedBox(height: 10),
          // Line height slider
          _buildSliderRow(
            label: LocaleKeys.text_editor_line_height.tr,
            value: lineHeight,
            min: 0.8,
            max: 3.0,
            defaultValue: _defaultLineHeight,
            displayValue: '${lineHeight.toStringAsFixed(1)}x',
            onChanged: onLineHeightChanged,
            onReset: () => onLineHeightChanged(_defaultLineHeight),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Alignment row ──

  Widget _buildAlignmentRow() {
    return Row(
      children: [
        Text(
          LocaleKeys.text_editor_alignment.tr,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const Spacer(),
        _AlignButton(
          icon: Icons.format_align_left_rounded,
          value: TextAlign.start,
          current: align,
          onTap: onAlignChanged,
        ),
        const SizedBox(width: 8),
        _AlignButton(
          icon: Icons.format_align_center_rounded,
          value: TextAlign.center,
          current: align,
          onTap: onAlignChanged,
        ),
        const SizedBox(width: 8),
        _AlignButton(
          icon: Icons.format_align_right_rounded,
          value: TextAlign.end,
          current: align,
          onTap: onAlignChanged,
        ),
      ],
    );
  }

  // ── Formatting row (Bold / Italic) ──

  Widget _buildFormattingRow() {
    return Row(
      children: [
        Text(
          LocaleKeys.text_editor_formatting.tr,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const Spacer(),
        _ToggleButton(
          icon: Icons.format_bold_rounded,
          label: LocaleKeys.text_editor_bold.tr,
          active: isBold,
          onTap: () {
            HapticFeedback.selectionClick();
            onBoldChanged(!isBold);
          },
        ),
        const SizedBox(width: 8),
        _ToggleButton(
          icon: Icons.format_italic_rounded,
          label: LocaleKeys.text_editor_italic.tr,
          active: isItalic,
          onTap: () {
            HapticFeedback.selectionClick();
            onItalicChanged(!isItalic);
          },
        ),
      ],
    );
  }

  // ── Background mode row ──

  Widget _buildBgModeRow() {
    return Row(
      children: [
        Text(
          LocaleKeys.text_editor_bg_mode.tr,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const Spacer(),
        _BgModeButton(
          icon: Icons.text_fields_rounded,
          label: LocaleKeys.text_editor_bg_text_only.tr,
          mode: LayerBackgroundMode.onlyColor,
          current: backgroundMode,
          onTap: onBgModeChanged,
        ),
        const SizedBox(width: 6),
        _BgModeButton(
          icon: Icons.format_color_fill_rounded,
          label: LocaleKeys.text_editor_bg_fill_text.tr,
          mode: LayerBackgroundMode.backgroundAndColor,
          current: backgroundMode,
          onTap: onBgModeChanged,
        ),
        const SizedBox(width: 6),
        _BgModeButton(
          icon: Icons.rectangle_rounded,
          label: LocaleKeys.text_editor_bg_fill_only.tr,
          mode: LayerBackgroundMode.background,
          current: backgroundMode,
          onTap: onBgModeChanged,
        ),
        const SizedBox(width: 6),
        _BgModeButton(
          icon: Icons.opacity_rounded,
          label: LocaleKeys.text_editor_bg_fill_opacity.tr,
          mode: LayerBackgroundMode.backgroundAndColorWithOpacity,
          current: backgroundMode,
          onTap: onBgModeChanged,
        ),
      ],
    );
  }

  // ── Generic slider row ──

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required double defaultValue,
    required String displayValue,
    required ValueChanged<double> onChanged,
    required VoidCallback onReset,
  }) {
    final isDefault = (value - defaultValue).abs() < 0.01;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: _sliderTheme,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        GestureDetector(
          onTap: isDefault
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onReset();
                },
          child: Semantics(
            label: LocaleKeys.text_editor_a11y_reset_value.trArgs([label]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isDefault
                    ? PanelTheme.surfaceSubtle
                    : PanelTheme.accent.withValues(alpha: 0.25),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  color: isDefault ? Colors.white54 : PanelTheme.accentLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const SliderThemeData _sliderTheme = PanelTheme.sliderTheme;
}

/// Single alignment button: direct-select, no cycle.
class _AlignButton extends StatelessWidget {
  const _AlignButton({
    required this.icon,
    required this.value,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
  final TextAlign value;
  final TextAlign current;
  final ValueChanged<TextAlign> onTap;

  static const _gradient = PanelTheme.accentGradient;

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(value);
      },
      child: Semantics(
        label: LocaleKeys.text_editor_a11y_align.trArgs([value.name]),
        selected: active,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: active ? _gradient : null,
            color: active ? null : PanelTheme.surfaceSubtle,
          ),
          child: Icon(icon,
              size: 16, color: active ? Colors.white : Colors.white54),
        ),
      ),
    );
  }
}

/// Reusable toggle button for bold / italic.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  static const _gradient = PanelTheme.accentGradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: label,
        toggled: active,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: active ? _gradient : null,
            color: active ? null : PanelTheme.surfaceSubtle,
          ),
          child: Icon(icon,
              size: 16, color: active ? Colors.white : Colors.white54),
        ),
      ),
    );
  }
}

/// Single background-mode button: direct-select row.
class _BgModeButton extends StatelessWidget {
  const _BgModeButton({
    required this.icon,
    required this.label,
    required this.mode,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final LayerBackgroundMode mode;
  final LayerBackgroundMode current;
  final ValueChanged<LayerBackgroundMode> onTap;

  static const _gradient = PanelTheme.accentGradient;

  @override
  Widget build(BuildContext context) {
    final active = current == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(mode);
      },
      child: Semantics(
        label: LocaleKeys.text_editor_a11y_bg_mode.trArgs([label]),
        selected: active,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: active ? _gradient : null,
            color: active ? null : PanelTheme.surfaceSubtle,
          ),
          child: Icon(icon,
              size: 14, color: active ? Colors.white : Colors.white54),
        ),
      ),
    );
  }
}
