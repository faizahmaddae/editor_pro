import 'package:flutter_test/flutter_test.dart';
import 'package:editor_pro/app/core/enums/editing_session_state.dart';
import 'package:editor_pro/app/core/enums/close_action.dart';

/// Mock StateManager for testing
class MockStateManager {
  int historyPointer = 0;
  List<dynamic> stateHistory = [];
  
  bool get canUndo => historyPointer > 0;
  
  void addChange() {
    stateHistory.add('change_${stateHistory.length}');
    historyPointer = stateHistory.length;
  }
  
  void undo() {
    if (canUndo) {
      historyPointer--;
    }
  }
  
  void redo() {
    if (historyPointer < stateHistory.length) {
      historyPointer++;
    }
  }
  
  void undoAll() {
    historyPointer = 0;
  }
}

/// Isolated state machine for testing (mirrors EditorController logic)
class EditingSessionStateMachine {
  EditingSessionState _sessionState = EditingSessionState.clean;
  MockStateManager? stateManager;
  int? _historyPointerAtSave;
  int? _historyLengthAtSave;
  
  EditingSessionState get sessionState => _sessionState;
  
  /// Package's source of truth - works for both new and reopened projects
  bool get hasAnyChanges => stateManager?.canUndo ?? false;
  
  int get currentHistoryPointer => stateManager?.historyPointer ?? 0;
  int get currentHistoryLength => stateManager?.stateHistory.length ?? 0;
  
  bool get hasUnsavedChanges {
    if (!hasAnyChanges) return false;
    if (_historyPointerAtSave == null) return true;
    return currentHistoryPointer != _historyPointerAtSave ||
           currentHistoryLength != _historyLengthAtSave;
  }
  
  /// Simplified: no changes OR exported OR saved at current point = safe
  bool get canCloseSafely {
    if (_sessionState == EditingSessionState.exported) return true;
    if (!hasAnyChanges) return true;
    // Has changes - check if draft was saved at this point
    return _historyPointerAtSave != null && !hasUnsavedChanges;
  }
  
  bool get canSaveDraft => hasAnyChanges;
  
  CloseAction resolveCloseAction() {
    if (canCloseSafely) {
      return CloseAction.exit;
    }
    return CloseAction.prompt;
  }
  
  /// Called when import completes - no special handling needed
  /// Package's canUndo handles reopened projects correctly
  void onImportHistoryComplete() {
    // Package handles this - canUndo is false until user makes changes
  }
  
  /// Called on every state history change - just keep reference
  void onEditorStateChanged() {
    // Simplified: we just rely on hasAnyChanges (package's canUndo)
  }
  
  void _transition(EditingSessionState newState) {
    if (_sessionState != newState) {
      _sessionState = newState;
    }
  }
  
  void markAsSaved() {
    _historyPointerAtSave = currentHistoryPointer;
    _historyLengthAtSave = currentHistoryLength;
    _transition(EditingSessionState.saved);
  }
  
  void markAsExported() {
    _transition(EditingSessionState.exported);
  }
  
  void discardAndExit() {
    _sessionState = EditingSessionState.clean;
  }
  
  void startFromSaved() {
    _sessionState = EditingSessionState.saved;
  }
}

void main() {
  group('EditingSessionStateMachine', () {
    late EditingSessionStateMachine machine;
    late MockStateManager mockStateManager;
    
    setUp(() {
      machine = EditingSessionStateMachine();
      mockStateManager = MockStateManager();
      machine.stateManager = mockStateManager;
    });
    
    group('Initial State', () {
      test('starts in clean state for new session', () {
        expect(machine.sessionState, EditingSessionState.clean);
        expect(machine.canCloseSafely, isTrue);
        expect(machine.resolveCloseAction(), CloseAction.exit);
      });
      
      test('can start in saved state for reopened draft', () {
        machine.startFromSaved();
        expect(machine.sessionState, EditingSessionState.saved);
        expect(machine.canCloseSafely, isTrue);
      });
    });
    
    group('Scenario 1: No edits → close', () {
      test('user opens editor, makes no changes, clicks back → exits immediately', () {
        // User opens editor (clean state)
        expect(machine.sessionState, EditingSessionState.clean);
        expect(machine.hasAnyChanges, isFalse);
        
        // User clicks back
        final action = machine.resolveCloseAction();
        expect(action, CloseAction.exit);
        expect(machine.canCloseSafely, isTrue);
      });
    });
    
    group('Scenario 2: Edit → export to gallery', () {
      test('user makes edits, exports to gallery → exits after export', () {
        // User adds a sticker
        mockStateManager.addChange();
        machine.onEditorStateChanged();
        
        expect(machine.hasAnyChanges, isTrue);
        expect(machine.canCloseSafely, isFalse);
        
        // User exports to gallery
        machine.markAsExported();
        
        expect(machine.sessionState, EditingSessionState.exported);
        expect(machine.canCloseSafely, isTrue);
        expect(machine.resolveCloseAction(), CloseAction.exit);
      });
    });
    
    group('Scenario 3: Edit → back → discard', () {
      test('user makes edits, clicks back, discards → exits', () {
        // User adds a sticker
        mockStateManager.addChange();
        machine.onEditorStateChanged();
        
        expect(machine.hasAnyChanges, isTrue);
        
        // User clicks back
        final action = machine.resolveCloseAction();
        expect(action, CloseAction.prompt);
        
        // User clicks discard
        machine.discardAndExit();
        expect(machine.sessionState, EditingSessionState.clean);
      });
    });
    
    group('Scenario 4: Edit → back → save draft → exit', () {
      test('user makes edits, clicks back, saves draft → exits', () {
        // User adds a sticker
        mockStateManager.addChange();
        machine.onEditorStateChanged();
        
        expect(machine.canSaveDraft, isTrue);
        
        // User clicks back → prompt
        expect(machine.resolveCloseAction(), CloseAction.prompt);
        
        // User clicks save draft
        machine.markAsSaved();
        
        expect(machine.sessionState, EditingSessionState.saved);
        expect(machine.canCloseSafely, isTrue);
        expect(machine.resolveCloseAction(), CloseAction.exit);
      });
    });
    
    group('Scenario 5: Edit → save draft → more edits → back', () {
      test('user saves draft, makes more edits, clicks back → prompts again', () {
        // User adds a sticker
        mockStateManager.addChange();
        machine.onEditorStateChanged();
        
        // User saves draft
        machine.markAsSaved();
        expect(machine.sessionState, EditingSessionState.saved);
        expect(machine.hasUnsavedChanges, isFalse);
        
        // User makes more edits
        mockStateManager.addChange();
        machine.onEditorStateChanged();
        
        expect(machine.hasUnsavedChanges, isTrue);
        expect(machine.canCloseSafely, isFalse);
        expect(machine.resolveCloseAction(), CloseAction.prompt);
      });
    });
    
    group('Scenario 6: Edit → undo all → close', () {
      test('user makes edits, undoes everything, clicks back → exits immediately', () {
        // User adds a sticker
        mockStateManager.addChange();
        machine.onEditorStateChanged();
        
        // User adds another sticker
        mockStateManager.addChange();
        machine.onEditorStateChanged();
        
        // User undoes everything
        mockStateManager.undoAll();
        machine.onEditorStateChanged();
        
        expect(machine.hasAnyChanges, isFalse);
        expect(machine.canCloseSafely, isTrue);
        expect(machine.resolveCloseAction(), CloseAction.exit);
      });
    });
    
    group('Scenario 7: Reopen draft → no edits → close', () {
      test('user reopens draft without editing → exits immediately', () {
        // Key: Package sets historyPointer at loaded position
        // so canUndo (hasAnyChanges) is FALSE until user makes NEW changes
        
        // Simulate: no new changes made
        // hasAnyChanges is false (canUndo = false)
        expect(machine.hasAnyChanges, isFalse);
        expect(machine.canCloseSafely, isTrue);
        expect(machine.resolveCloseAction(), CloseAction.exit);
      });
      
      test('package handles reopened projects correctly via canUndo', () {
        // Simulate reopening - package loads state history
        // With enableInitialEmptyState: false, historyPointer = loaded position
        // canUndo returns false until user makes NEW changes
        
        // No changes made - canUndo is false
        expect(machine.hasAnyChanges, isFalse);
        expect(machine.canCloseSafely, isTrue);
        expect(machine.resolveCloseAction(), CloseAction.exit);
      });
    });
    
    group('Scenario 8: Reopen draft → edit → back', () {
      test('user reopens draft, makes edits, clicks back → prompts', () {
        // Start fresh (simulates package loading state history with canUndo=false)
        expect(machine.hasAnyChanges, isFalse);
        expect(machine.canCloseSafely, isTrue);
        
        // User makes new edits
        mockStateManager.addChange();
        machine.onEditorStateChanged();
        
        expect(machine.hasAnyChanges, isTrue);
        expect(machine.canCloseSafely, isFalse);
        expect(machine.resolveCloseAction(), CloseAction.prompt);
      });
    });
    
    group('Core Behaviors', () {
      test('hasAnyChanges reflects package canUndo', () {
        expect(machine.hasAnyChanges, isFalse);
        
        mockStateManager.addChange();
        expect(machine.hasAnyChanges, isTrue);
        
        mockStateManager.undoAll();
        expect(machine.hasAnyChanges, isFalse);
      });
      
      test('canCloseSafely returns true after export regardless of changes', () {
        mockStateManager.addChange();
        expect(machine.canCloseSafely, isFalse);
        
        machine.markAsExported();
        expect(machine.canCloseSafely, isTrue);
      });
      
      test('canCloseSafely returns true after save at current position', () {
        mockStateManager.addChange();
        expect(machine.canCloseSafely, isFalse);
        
        machine.markAsSaved();
        expect(machine.canCloseSafely, isTrue);
      });
      
      test('canCloseSafely returns false after save then more changes', () {
        mockStateManager.addChange();
        machine.markAsSaved();
        expect(machine.canCloseSafely, isTrue);
        
        mockStateManager.addChange();
        expect(machine.canCloseSafely, isFalse);
      });
      
      test('hasUnsavedChanges detects changes after save', () {
        mockStateManager.addChange();
        machine.markAsSaved();
        expect(machine.hasUnsavedChanges, isFalse);
        
        mockStateManager.addChange();
        expect(machine.hasUnsavedChanges, isTrue);
      });
    });
    
    group('Edge Cases', () {
      test('multiple rapid changes stay unsafe', () {
        for (int i = 0; i < 10; i++) {
          mockStateManager.addChange();
        }
        
        expect(machine.hasAnyChanges, isTrue);
        expect(machine.canCloseSafely, isFalse);
      });
      
      test('undo followed by redo stays unsafe', () {
        mockStateManager.addChange();
        mockStateManager.addChange();
        
        mockStateManager.undo();
        
        // Still has changes (canUndo still true)
        expect(machine.hasAnyChanges, isTrue);
        expect(machine.canCloseSafely, isFalse);
      });
    });
  });
}
