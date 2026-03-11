import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/widgets/glass_icon_button.dart';

/// Unified top bar for sub-editors (Paint, CropRotate, Filter, Tune, Blur).
///
/// Visually distinct from the main editor bar:
/// - **Back** arrow (instead of Close) to return to the main editor
/// - **Tool title** centered to reinforce which mode the user is in
/// - **Apply** action (instead of Done) to confirm the sub-tool's changes
/// - Context-aware Undo / Redo when the sub-editor supports history
class SubEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SubEditorAppBar({
    super.key,
    required this.onClose,
    required this.onDone,
    this.toolTitle,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  final VoidCallback onClose;
  final VoidCallback onDone;

  /// The name of the active tool displayed in the center of the bar.
  /// When null, the center area shows only the undo/redo pill (if available).
  final String? toolTitle;

  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  static const double barHeight = kToolbarHeight + 8;

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final hasUndoRedo = onUndo != null || onRedo != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1A1A1A),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(top: topPadding),
      child: SizedBox(
        height: barHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Back button — returns to main editor (distinct from Close)
              GlassIconButton(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onClose();
                },
                icon: Icons.arrow_back_rounded,
                tooltip: LocaleKeys.common_back.tr,
              ),
              const Spacer(),
              // Center area: tool title + undo/redo
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (toolTitle != null)
                    Text(
                      toolTitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  if (toolTitle != null && hasUndoRedo)
                    const SizedBox(height: 2),
                  if (hasUndoRedo)
                    _UndoRedoPill(
                      canUndo: canUndo,
                      canRedo: canRedo,
                      onUndo: () {
                        HapticFeedback.lightImpact();
                        onUndo?.call();
                      },
                      onRedo: () {
                        HapticFeedback.lightImpact();
                        onRedo?.call();
                      },
                    ),
                  if (!hasUndoRedo && toolTitle == null)
                    const SizedBox.shrink(),
                ],
              ),
              const Spacer(),
              // Apply button — confirms this sub-tool's changes
              GlassIconButton(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onDone();
                },
                icon: Icons.check_rounded,
                tooltip: LocaleKeys.common_apply.tr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UndoRedoPill extends StatelessWidget {
  const _UndoRedoPill({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
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
            tooltip: LocaleKeys.common_undo.tr,
          ),
          Container(
            width: 1,
            height: 16,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          _PillButton(
            onTap: canRedo ? onRedo : null,
            icon: Icons.redo_rounded,
            enabled: canRedo,
            isStart: false,
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
    this.tooltip,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final bool enabled;
  final bool isStart;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadiusDirectional.horizontal(
      start: isStart ? const Radius.circular(14) : Radius.zero,
      end: !isStart ? const Radius.circular(14) : Radius.zero,
    ).resolve(Directionality.of(context));

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: borderRadius,
          child: Container(
            width: 36,
            height: 28,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: enabled
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.25),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
