import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Immutable snapshot of the text editor's visual state.
class _Snapshot {
  final TextAlign align;
  final TextStyle textStyle;
  final LayerBackgroundMode bgMode;
  final double fontScale;
  final Color primaryColor;

  const _Snapshot({
    required this.align,
    required this.textStyle,
    required this.bgMode,
    required this.fontScale,
    required this.primaryColor,
  });

  /// Returns true if this snapshot is visually identical to [other].
  bool matches(_Snapshot other) {
    return align == other.align &&
        textStyle == other.textStyle &&
        bgMode == other.bgMode &&
        (fontScale - other.fontScale).abs() < 0.01 &&
        primaryColor == other.primaryColor;
  }
}

/// Lightweight undo/redo manager for the text editor.
///
/// Call [capture] whenever the editor state changes (on every reactive rebuild).
/// It deduplicates consecutive identical snapshots automatically.
class TextEditorUndoManager extends ChangeNotifier {
  final List<_Snapshot> _history = [];
  int _index = -1;
  bool _isApplying = false;

  bool get canUndo => _index > 0;
  bool get canRedo => _index < _history.length - 1;

  /// Take a snapshot of the current editor state.
  /// Consecutive duplicates are silently ignored.
  void capture(TextEditorState editor) {
    // Skip capture during undo/redo to preserve the redo stack.
    if (_isApplying) return;
    final snap = _Snapshot(
      align: editor.align,
      textStyle: editor.selectedTextStyle,
      bgMode: editor.backgroundColorMode,
      fontScale: editor.fontScale,
      primaryColor: editor.primaryColor,
    );

    // Skip if identical to current
    if (_index >= 0 && _history[_index].matches(snap)) return;

    // Truncate any forward history (redo branch)
    if (_index < _history.length - 1) {
      _history.removeRange(_index + 1, _history.length);
    }

    _history.add(snap);
    _index = _history.length - 1;
    notifyListeners();
  }

  /// Restore the previous state.
  void undo(TextEditorState editor) {
    if (!canUndo) return;
    _index--;
    _apply(editor, _history[_index]);
    notifyListeners();
  }

  /// Restore the next state.
  void redo(TextEditorState editor) {
    if (!canRedo) return;
    _index++;
    _apply(editor, _history[_index]);
    notifyListeners();
  }

  void _apply(TextEditorState editor, _Snapshot snap) {
    _isApplying = true;
    editor.align = snap.align;
    editor.selectedTextStyle = snap.textStyle;
    editor.fontScale = snap.fontScale;
    editor.primaryColor = snap.primaryColor;

    // Cycle backgroundColorMode to the target
    while (editor.backgroundColorMode != snap.bgMode) {
      editor.toggleBackgroundMode();
    }

    // Clear the guard after the post-frame capture runs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isApplying = false;
    });
  }
}
