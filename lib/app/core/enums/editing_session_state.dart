/// Editing session states for the state machine.
///
/// This enum tracks the lifecycle of an editing session to determine:
/// - When to show "save draft" prompts
/// - When user can exit safely without losing work
/// - What UI state to display
///
/// State transitions:
/// ```
/// CLEAN ──(edit)──► DIRTY ──(save)──► SAVED
///   ▲                 │                  │
///   │    (undo all)   │     (edit)       │
///   └─────────────────┘◄─────────────────┘
///
/// Any state ──(export)──► EXPORTED
/// ```
enum EditingSessionState {
  /// Editor opened, no changes made.
  /// User can exit without any prompt.
  clean,

  /// User has unsaved changes.
  /// Must prompt before exit (save draft / discard).
  dirty,

  /// Draft saved, no new changes since save.
  /// User can exit without prompt.
  saved,

  /// Final image exported (saved to gallery or shared).
  /// User can exit without prompt.
  exported,
}

/// Extension methods for [EditingSessionState].
extension EditingSessionStateX on EditingSessionState {
  /// Returns true if user can exit editor without losing work.
  bool get canExitSafely {
    switch (this) {
      case EditingSessionState.clean:
      case EditingSessionState.saved:
      case EditingSessionState.exported:
        return true;
      case EditingSessionState.dirty:
        return false;
    }
  }

  /// Returns true if save draft option should be shown.
  bool get canSaveDraft => this == EditingSessionState.dirty;

  /// Returns a human-readable description for debugging.
  String get debugDescription {
    switch (this) {
      case EditingSessionState.clean:
        return 'CLEAN (no changes)';
      case EditingSessionState.dirty:
        return 'DIRTY (unsaved changes)';
      case EditingSessionState.saved:
        return 'SAVED (draft persisted)';
      case EditingSessionState.exported:
        return 'EXPORTED (final image)';
    }
  }
}
