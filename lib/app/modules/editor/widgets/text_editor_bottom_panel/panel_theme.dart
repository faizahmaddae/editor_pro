import 'package:flutter/material.dart';

/// Shared design tokens for the text-editor bottom panel.
///
/// Centralises magic colours, the slider theme, and small utilities so
/// individual tabs stay DRY.
abstract final class PanelTheme {
  // ── Accent colours ──────────────────────────────────────────────

  /// Primary purple accent used for active states and selections.
  static const Color accent = Color(0xFF7C3AED);

  /// Secondary blue accent for gradients.
  static const Color accentSecondary = Color(0xFF3B82F6);

  /// Lighter purple for non-default value indicators.
  static const Color accentLight = Color(0xFFB07CFF);

  /// Standard accent gradient (purple → blue), used for underlines,
  /// selected chips, and alignment buttons.
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentSecondary],
  );

  // ── Surface tints ──────────────────────────────────────────────

  /// ~6 % white overlay — card/chip backgrounds.
  static Color get surfaceFaint => Colors.white.withValues(alpha: 0.06);

  /// ~8 % white overlay — input fills, inactive buttons.
  static Color get surfaceSubtle => Colors.white.withValues(alpha: 0.08);

  /// ~12 % white overlay — active segments, border highlights.
  static Color get surfaceMedium => Colors.white.withValues(alpha: 0.12);

  // ── Shared slider theme ────────────────────────────────────────

  /// Consistent slider appearance across all tabs.
  static const SliderThemeData sliderTheme = SliderThemeData(
    trackHeight: 3,
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
    overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
    activeTrackColor: accent,
    inactiveTrackColor: Color(0x14FFFFFF),
    thumbColor: Colors.white,
  );

  // ── Utilities ──────────────────────────────────────────────────

  /// Tolerance-based colour comparison (ignores alpha channel).
  static bool colorsClose(Color a, Color b) {
    return (a.r - b.r).abs() < 0.02 &&
        (a.g - b.g).abs() < 0.02 &&
        (a.b - b.b).abs() < 0.02;
  }

  /// Rounds [v] to the nearest [step] increment.
  static double snap(double v, double step) =>
      (v / step).roundToDouble() * step;
}
