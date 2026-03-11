import 'package:flutter/material.dart';

/// Immutable value object representing a text shadow configuration.
///
/// Used by the shadow tab to communicate shadow state to the editor.
/// Designed to be pure and testable — no dependencies on editor state.
class ShadowValue {
  final bool enabled;
  final Color color;
  final double blur;
  final double dx;
  final double dy;

  const ShadowValue({
    this.enabled = false,
    this.color = Colors.black,
    this.blur = 4.0,
    this.dx = 2.0,
    this.dy = 2.0,
  });

  /// Extract shadow config from the first shadow in a [TextStyle].
  factory ShadowValue.fromStyle(TextStyle style) {
    final shadows = style.shadows;
    if (shadows == null || shadows.isEmpty) {
      return const ShadowValue();
    }
    final s = shadows.first;
    return ShadowValue(
      enabled: true,
      color: s.color,
      blur: s.blurRadius,
      dx: s.offset.dx,
      dy: s.offset.dy,
    );
  }

  /// Convert to a [List<Shadow>] suitable for [TextStyle.shadows].
  List<Shadow> toShadows() {
    if (!enabled) return const [];
    return [
      Shadow(
        color: color.withValues(alpha: 0.7),
        blurRadius: blur,
        offset: Offset(dx, dy),
      ),
    ];
  }

  ShadowValue copyWith({
    bool? enabled,
    Color? color,
    double? blur,
    double? dx,
    double? dy,
  }) {
    return ShadowValue(
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
      blur: blur ?? this.blur,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShadowValue &&
        other.enabled == enabled &&
        other.color == color &&
        other.blur == blur &&
        other.dx == dx &&
        other.dy == dy;
  }

  @override
  int get hashCode => Object.hash(enabled, color, blur, dx, dy);

  @override
  String toString() =>
      'ShadowValue(enabled: $enabled, color: $color, blur: $blur, dx: $dx, dy: $dy)';
}
