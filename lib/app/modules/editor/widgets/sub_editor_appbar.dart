import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';
import '../../../core/widgets/glass_icon_button.dart';
import '../../../core/widgets/undo_redo_pill.dart';

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
      decoration: BoxDecoration(
        color: GroundedTheme.backgroundDark,
        border: Border(
          bottom: BorderSide(
            color: GroundedTheme.surfaceElevatedDark,
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
                    UndoRedoPill(
                      compact: true,
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
