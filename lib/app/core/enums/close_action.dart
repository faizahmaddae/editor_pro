/// Actions to take when user requests to close the editor.
///
/// Determined by [EditorController.resolveCloseAction()] based on
/// the current [EditingSessionState].
enum CloseAction {
  /// Close immediately without any prompt.
  /// Used when: no changes, draft already saved, or image exported.
  exit,

  /// Show the draft exit sheet with Save/Discard options.
  /// Used when: unsaved changes exist.
  prompt,
}
