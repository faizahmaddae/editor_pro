import 'package:flutter_test/flutter_test.dart';
import 'package:editor_pro/app/core/enums/editing_session_state.dart';
import 'package:editor_pro/app/core/enums/close_action.dart';

void main() {
  group('EditingSessionState', () {
    group('canExitSafely', () {
      test('clean state can exit safely', () {
        expect(EditingSessionState.clean.canExitSafely, isTrue);
      });

      test('dirty state cannot exit safely', () {
        expect(EditingSessionState.dirty.canExitSafely, isFalse);
      });

      test('saved state can exit safely', () {
        expect(EditingSessionState.saved.canExitSafely, isTrue);
      });

      test('exported state can exit safely', () {
        expect(EditingSessionState.exported.canExitSafely, isTrue);
      });
    });

    group('canSaveDraft', () {
      test('clean state cannot save draft (no changes)', () {
        expect(EditingSessionState.clean.canSaveDraft, isFalse);
      });

      test('dirty state can save draft', () {
        expect(EditingSessionState.dirty.canSaveDraft, isTrue);
      });

      test('saved state cannot save draft (already saved)', () {
        expect(EditingSessionState.saved.canSaveDraft, isFalse);
      });

      test('exported state cannot save draft (already exported)', () {
        expect(EditingSessionState.exported.canSaveDraft, isFalse);
      });
    });

    group('debugDescription', () {
      test('all states have debug descriptions', () {
        for (final state in EditingSessionState.values) {
          expect(state.debugDescription, isNotEmpty);
        }
      });
    });
  });

  group('CloseAction', () {
    test('exit and prompt are distinct values', () {
      expect(CloseAction.exit, isNot(equals(CloseAction.prompt)));
    });
  });
}
