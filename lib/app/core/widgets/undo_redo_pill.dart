import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/locales.g.dart';
import '../theme/grounded_theme.dart';

/// Connected undo/redo pill shared between main and sub-editor app bars.
///
/// Set [compact] to `true` for the smaller sub-editor variant.
class UndoRedoPill extends StatelessWidget {
  const UndoRedoPill({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    this.compact = false,
  });

  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  /// When true, renders the smaller 28px variant used in sub-editor bars.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double height = compact ? 28 : 44;
    final double radius = compact ? 14 : 22;
    final double dividerHeight = compact ? 16 : 24;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: GroundedTheme.glassButtonFill,
        border: Border.all(
          color: GroundedTheme.glassButtonBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillButton(
            onTap: canUndo ? onUndo : null,
            icon: Icons.undo_rounded,
            enabled: canUndo,
            isStart: true,
            compact: compact,
            tooltip: LocaleKeys.common_undo.tr,
          ),
          Container(
            width: 1,
            height: dividerHeight,
            color: GroundedTheme.glassDivider,
          ),
          _PillButton(
            onTap: canRedo ? onRedo : null,
            icon: Icons.redo_rounded,
            enabled: canRedo,
            isStart: false,
            compact: compact,
            tooltip: LocaleKeys.common_redo.tr,
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.onTap,
    required this.icon,
    required this.enabled,
    required this.isStart,
    required this.compact,
    this.tooltip,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final bool enabled;
  final bool isStart;
  final bool compact;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final double radius = compact ? 14 : 22;
    final double width = compact ? 36 : 48;
    final double height = compact ? 28 : 44;
    final double iconSize = compact ? 16 : 20;

    final borderRadius = BorderRadiusDirectional.horizontal(
      start: isStart ? Radius.circular(radius) : Radius.zero,
      end: !isStart ? Radius.circular(radius) : Radius.zero,
    ).resolve(Directionality.of(context));

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: borderRadius,
          child: Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: enabled
                  ? GroundedTheme.glassIconColor
                  : GroundedTheme.glassIconDisabled,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
