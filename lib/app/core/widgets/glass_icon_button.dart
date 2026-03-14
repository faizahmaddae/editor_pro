import 'package:flutter/material.dart';

import '../theme/grounded_theme.dart';

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
            color: GroundedTheme.glassButtonFill,
            border: Border.all(
              color: GroundedTheme.glassButtonBorder,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: GroundedTheme.glassIconColor,
            size: iconSize,
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Semantics(
        button: true,
        label: tooltip!,
        child: Tooltip(
          message: tooltip!,
          child: button,
        ),
      );
    }

    return button;
  }
}
