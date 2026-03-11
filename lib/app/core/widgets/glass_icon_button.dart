import 'package:flutter/material.dart';

/// Solid circular icon button used across editor screens.
///
/// Provides a dark circle with a subtle border, matching
/// the solid dark design language of the editor app bars.
/// Uses [Material] + [InkWell] for proper ripple feedback and
/// supports an optional [tooltip] for accessibility.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.tooltip,
    this.size = 44,
    this.iconSize = 22,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String? tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.9),
            size: iconSize,
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
