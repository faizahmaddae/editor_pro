import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../generated/locales.g.dart';
import 'text_editor_undo_manager.dart';

/// Instagram-style text editor app bar
/// Minimal, elegant, with frosted glass effect
class TextEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TextEditorAppBar({
    super.key,
    required this.textEditor,
    required this.undoManager,
  });

  final TextEditorState textEditor;
  final TextEditorUndoManager undoManager;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        children: [
          // Close button
          _GlassButton(
            onTap: () {
              HapticFeedback.lightImpact();
              textEditor.close();
            },
            icon: Icons.close_rounded,
            tooltip: LocaleKeys.common_cancel.tr,
          ),
          const Spacer(),
          // Undo / Redo
          ListenableBuilder(
            listenable: undoManager,
            builder: (_, child) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GlassButton(
                  onTap: undoManager.canUndo
                      ? () {
                          HapticFeedback.lightImpact();
                          undoManager.undo(textEditor);
                        }
                      : null,
                  icon: Icons.undo_rounded,
                  tooltip: LocaleKeys.common_undo.tr,
                  size: 36,
                  iconSize: 20,
                ),
                const SizedBox(width: 8),
                _GlassButton(
                  onTap: undoManager.canRedo
                      ? () {
                          HapticFeedback.lightImpact();
                          undoManager.redo(textEditor);
                        }
                      : null,
                  icon: Icons.redo_rounded,
                  tooltip: LocaleKeys.common_redo.tr,
                  size: 36,
                  iconSize: 20,
                ),
              ],
            ),
          ),
          const Spacer(),
          // Done button
          _GlassButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              textEditor.done();
            },
            icon: Icons.check_rounded,
            isPrimary: true,
            tooltip: LocaleKeys.common_done.tr,
          ),
        ],
      ),
    );
  }
}

/// Frosted glass style button
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.onTap,
    required this.icon,
    this.isPrimary = false,
    this.tooltip,
    this.size = 44,
    this.iconSize = 24,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final bool isPrimary;
  final String? tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip ?? '',
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: disabled ? 0.35 : 1.0,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPrimary 
                        ? Colors.white.withValues(alpha: 0.95)
                        : Colors.black.withValues(alpha: 0.4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.black : Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
