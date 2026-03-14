import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';
import '../controllers/editor_controller.dart';

/// Result of the draft exit sheet interaction.
///
/// Returned by [DraftExitSheet.show] so that the package's
/// [closeWarningDialog] can decide whether to proceed with closing.
enum DraftAction {
  /// User chose to save the current state as a draft.
  saved,

  /// User chose to discard all unsaved changes.
  discarded,
}

/// InShot-style Draft Exit Sheet.
///
/// Shown from the package's [closeWarningDialog] when the user tries to
/// close the editor with unsaved changes. The sheet captures the current
/// editor image, persists the draft when requested, and returns a
/// [DraftAction] so the caller can tell the package whether to close.
///
/// Design:
/// - Draft label with clock icon
/// - Discard button (red with trash icon)
/// - Save Draft button (green with check icon)
/// - Smooth slide-up animation with dimmed background
/// - RTL support
class DraftExitSheet extends StatefulWidget {
  /// The live editor state — used to capture the current image.
  final ProImageEditorState editor;

  /// The GetX controller — used to persist the draft.
  final EditorController controller;

  const DraftExitSheet({
    super.key,
    required this.editor,
    required this.controller,
  });

  /// Show the draft exit sheet and return the chosen action.
  ///
  /// Returns [DraftAction.saved], [DraftAction.discarded], or `null`
  /// if the user dismissed the sheet without choosing.
  static Future<DraftAction?> show({
    required ProImageEditorState editor,
    required EditorController controller,
  }) async {
    return await Get.bottomSheet<DraftAction>(
      DraftExitSheet(editor: editor, controller: controller),
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  State<DraftExitSheet> createState() => _DraftExitSheetState();
}

class _DraftExitSheetState extends State<DraftExitSheet> {
  bool _isSaving = false;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _handleSaveDraft() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      // Always capture a fresh screenshot so the thumbnail matches
      // the current editor state (the user may have edited after a
      // previous Done → Export → Back cycle).
      final bytes = await widget.editor.captureEditorImage();

      if (bytes.isEmpty) {
        if (mounted) setState(() => _isSaving = false);
        Get.snackbar(
          LocaleKeys.common_error.tr,
          LocaleKeys.export_failed.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: GroundedTheme.error.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return;
      }

      widget.controller.editedImageBytes = bytes;

      // Persist the project + state history.
      // showFeedback: false — the sheet already provides visual feedback
      // and the editor is about to close.
      final ok = await widget.controller.saveDraft(showFeedback: false);

      if (!ok) {
        if (mounted) setState(() => _isSaving = false);
        Get.snackbar(
          LocaleKeys.common_error.tr,
          LocaleKeys.export_failed.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: GroundedTheme.error.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Close the sheet and signal "saved" to closeWarningDialog.
      if (mounted) Get.back(result: DraftAction.saved);
    } catch (e) {
      debugPrint('[DraftExitSheet] Save error: $e');
      if (mounted) setState(() => _isSaving = false);
      Get.snackbar(
        LocaleKeys.common_error.tr,
        LocaleKeys.export_failed.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: GroundedTheme.error.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  void _handleDiscard() {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    Get.back(result: DraftAction.discarded);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: !_isSaving,
      child: Container(
        decoration: const BoxDecoration(
          color: GroundedTheme.surfaceElevatedDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(GroundedTheme.radiusXLarge)),
        ),
        padding: EdgeInsetsDirectional.fromSTEB(
          GroundedTheme.spacing20, GroundedTheme.spacing8,
          GroundedTheme.spacing20, bottomPadding + GroundedTheme.spacing12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: GroundedTheme.spacing16),

            // Title
            Text(
              LocaleKeys.draft_title.tr,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: GroundedTheme.textPrimaryDark.withValues(alpha: 0.94),
              ),
            ),
            const SizedBox(height: GroundedTheme.spacing4),

            // Subtitle
            Text(
              LocaleKeys.draft_subtitle.tr,
              style: const TextStyle(
                fontSize: GroundedTheme.fontSizeS,
                color: GroundedTheme.textSecondaryDark,
              ),
            ),
            const SizedBox(height: GroundedTheme.spacing20),

            // Primary: Save Draft
            _SheetButton(
              label: _isSaving
                  ? LocaleKeys.editor_saving.tr
                  : LocaleKeys.draft_save.tr,
              icon: _isSaving ? null : Icons.save_rounded,
              backgroundColor: GroundedTheme.success,
              onTap: _isSaving ? null : _handleSaveDraft,
              isLoading: _isSaving,
            ),
            const SizedBox(height: GroundedTheme.spacing8),

            // Secondary: Discard Changes
            _SheetButton(
              label: LocaleKeys.draft_discard.tr,
              icon: Icons.delete_outline_rounded,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              foregroundColor: GroundedTheme.error,
              onTap: _isSaving ? null : _handleDiscard,
            ),
            const SizedBox(height: GroundedTheme.spacing8),

            // Tertiary: Continue Editing
            _SheetButton(
              label: LocaleKeys.draft_continue.tr,
              icon: Icons.edit_rounded,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white60,
              onTap: _isSaving ? null : () => Get.back<DraftAction>(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width action button for the exit sheet.
class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.backgroundColor,
    this.icon,
    this.foregroundColor = Colors.white,
    this.onTap,
    this.isLoading = false,
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null && !isLoading;

    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(GroundedTheme.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GroundedTheme.radiusMedium),
          splashColor: onTap != null ? Colors.white12 : Colors.transparent,
          highlightColor: onTap != null ? Colors.white10 : Colors.transparent,
          child: Opacity(
            opacity: disabled ? 0.4 : 1.0,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(foregroundColor),
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, color: foregroundColor, size: 20),
                  if (icon != null || isLoading) const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
