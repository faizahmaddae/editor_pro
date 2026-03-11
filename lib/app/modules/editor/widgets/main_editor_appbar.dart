import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/widgets/glass_icon_button.dart';

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
      color: const Color(0xFF161616),
      padding: EdgeInsets.only(top: topPadding),
      child: SizedBox(
        height: barHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              _UndoRedoPill(
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

/// Connected undo/redo pill with premium styling
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
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo
          _PillButton(
            onTap: canUndo ? onUndo : null,
            icon: Icons.undo_rounded,
            enabled: canUndo,
            isStart: true,
            tooltip: LocaleKeys.common_undo.tr,
          ),
          // Subtle divider
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          // Redo
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

/// Individual button within the undo/redo pill
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
      start: isStart ? const Radius.circular(22) : Radius.zero,
      end: !isStart ? const Radius.circular(22) : Radius.zero,
    ).resolve(Directionality.of(context));

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: borderRadius,
          child: Container(
            width: 48,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: enabled 
                  ? Colors.white.withValues(alpha: 0.9) 
                  : Colors.white.withValues(alpha: 0.25),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}


