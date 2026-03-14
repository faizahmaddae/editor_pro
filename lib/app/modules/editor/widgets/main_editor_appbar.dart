import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';
import '../../../core/widgets/glass_icon_button.dart';
import '../../../core/widgets/undo_redo_pill.dart';

/// Premium editor app bar with refined aesthetics
/// Inspired by Lightroom, VSCO, and professional photo editors
class MainEditorAppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  const MainEditorAppBarCustom({
    super.key,
    required this.editor,
  });

  final ProImageEditorState editor;

  /// The height reported to the Scaffold so it reserves the correct amount
  /// of space for the body. Must match the actual rendered height exactly
  /// (the package's SafeArea already handles the status-bar inset).
  static const double barHeight = kToolbarHeight + 8;

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  @override
  Widget build(BuildContext context) {
    // Hide when a sub-editor (text, paint, …) is open — the sub-editor
    // provides its own appbar and we must avoid duplicate controls.
    if (editor.isSubEditorOpen) {
      return const SizedBox.shrink();
    }

    final canUndo = editor.canUndo;
    final canRedo = editor.canRedo;
    // Status bar height — we pad content below it for edge-to-edge look.
    // The package's SafeArea(top: false) is set so we handle it here.
    final topPadding = MediaQuery.paddingOf(context).top;

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
          padding: const EdgeInsets.symmetric(
            horizontal: GroundedTheme.spacing8,
            vertical: GroundedTheme.spacing4,
          ),
          child: Row(
            children: [
              // Close button - minimal circle
              GlassIconButton(
                onTap: () {
                  HapticFeedback.lightImpact();
                  editor.closeEditor();
                },
                icon: Icons.close_rounded,
                tooltip: LocaleKeys.common_cancel.tr,
              ),

              const Spacer(),

              // Undo/Redo in a connected pill — centered
              UndoRedoPill(
                canUndo: canUndo,
                canRedo: canRedo,
                onUndo: () {
                  HapticFeedback.lightImpact();
                  editor.undoAction();
                },
                onRedo: () {
                  HapticFeedback.lightImpact();
                  editor.redoAction();
                },
              ),

              const Spacer(),

              // Done button — clean Grounded style
              GlassIconButton(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  editor.doneEditing();
                },
                icon: Icons.done_rounded,
                tooltip: LocaleKeys.common_done.tr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

