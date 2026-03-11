import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import '../../../../generated/locales.g.dart';
import '../../../core/enums/editing_session_state.dart';
import '../../../data/services/canvas_generator.dart';
import '../../../data/services/export_service.dart';
import '../../../data/services/project_storage.dart';
import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';


/// Editor screen controller
/// 
/// Uses a state machine pattern for managing editing session lifecycle.
/// See [EditingSessionState] for state definitions.
class EditorController extends GetxController {
  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION ARGUMENTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  late String imagePath;
  
  /// Project ID for updating existing projects (null for new projects)
  String? projectId;
  
  /// Original image path (for state history re-opening)
  /// This is the source image before any edits
  String? originalImagePath;
  
  /// State history path for editable layers
  String? stateHistoryPath;
  
  /// Loaded state history for import (set when opening existing project)
  ImportStateHistory? loadedStateHistory;
  
  // Quick action to auto-open specific sub-editor
  String? quickAction;
  
  // Format preset for aspect ratio crop
  String? format;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE MACHINE
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Current session state (observable)
  final Rx<EditingSessionState> _sessionState = EditingSessionState.clean.obs;
  
  /// Public getter for session state
  EditingSessionState get sessionState => _sessionState.value;
  
  /// Editor state reference (set via onStateHistoryChange callback)
  ProImageEditorState? _editorState;
  
  /// History pointer at last draft save (for detecting new changes after save)
  int? _historyPointerAtSave;
  
  /// History length at last draft save (additional check for changes)
  int? _historyLengthAtSave;
  
  /// Initial history pointer when editor loaded (for detecting any changes since open)
  int? _initialHistoryPointer;
  
  /// Initial history length when editor loaded
  int? _initialHistoryLength;

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES (from package's StateManager)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// StateManager from the editor (null until editor initializes)
  StateManager? get _stateManager => _editorState?.stateManager;
  
  /// Has ANY changes been made since editor loaded?
  /// Compares current state to initial state when editor opened.
  /// This correctly handles reopened projects with existing history.
  bool get hasAnyChanges {
    if (_initialHistoryPointer == null) return false;
    return currentHistoryPointer != _initialHistoryPointer ||
           currentHistoryLength != _initialHistoryLength;
  }
  
  /// Current history position
  int get currentHistoryPointer => _stateManager?.historyPointer ?? 0;
  
  /// Current history length
  int get currentHistoryLength => _stateManager?.stateHistory.length ?? 0;
  
  /// Has unsaved changes since last draft save?
  /// If we haven't saved a draft yet, any change is unsaved.
  /// If we have saved, compare current position to saved position.
  bool get hasUnsavedChanges {
    if (!hasAnyChanges) return false;
    if (_historyPointerAtSave == null) return true;
    return currentHistoryPointer != _historyPointerAtSave ||
           currentHistoryLength != _historyLengthAtSave;
  }
  
  /// Can close editor without prompting?
  /// Safe to close when:
  /// - No changes at all (new session or reopened with no edits)
  /// - Already exported
  /// - Draft saved and no new changes since save
  bool get canCloseSafely {
    if (_sessionState.value == EditingSessionState.exported) return true;
    if (!hasAnyChanges) return true;
    // Has changes - check if draft was saved at this point
    return _historyPointerAtSave != null && !hasUnsavedChanges;
  }
  
  /// Should show "save draft" option in dialog?
  bool get canSaveDraft => hasAnyChanges;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROCESS FLAGS
  // ═══════════════════════════════════════════════════════════════════════════
  
  final RxBool isSaving = false.obs;
  final RxBool isLoadingHistory = false.obs;
  
  /// Edited image bytes (set by onImageEditingComplete)
  Uint8List? editedImageBytes;
  
  /// Reference to the editor state for exporting history
  GlobalKey<ProImageEditorState>? editorKey;
  


  EditorController();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    
    // Check if we're in blank canvas mode
    if (args?['mode'] == 'blank') {
      // Parse canvas size
      final canvasSizeMap = args?['canvasSize'] as Map<String, dynamic>?;
      Size canvasSize;
      if (canvasSizeMap != null) {
        canvasSize = Size(
          (canvasSizeMap['width'] as num).toDouble(),
          (canvasSizeMap['height'] as num).toDouble(),
        );
      } else {
        canvasSize = const Size(1080, 1920); // Default size
      }
      
      // Parse background color
      Color? bgColor;
      final bgColorValue = args?['backgroundColor'] as int?;
      if (bgColorValue != null) {
        bgColor = Color(bgColorValue);
      }

      // Parse optional background image path
      final bgImagePath = args?['backgroundImagePath'] as String?;

      // Parse optional normalised crop rect
      Rect? bgImageCropRect;
      final cropMap = args?['backgroundImageCropRect'] as Map<String, dynamic>?;
      if (cropMap != null) {
        bgImageCropRect = Rect.fromLTWH(
          (cropMap['left'] as num).toDouble(),
          (cropMap['top'] as num).toDouble(),
          (cropMap['width'] as num).toDouble(),
          (cropMap['height'] as num).toDouble(),
        );
      }
      
      debugPrint('[Editor] Blank canvas mode: size=$canvasSize, bg=$bgColor, bgImage=$bgImagePath');
      
      // Generate canvas image - sets imagePath when complete
      // Show loading while generating
      isLoadingHistory.value = true;
      _generateBlankCanvas(canvasSize, bgColor, bgImagePath, bgImageCropRect);
    } else {
      // Normal image editing mode
      imagePath = args?['imagePath'] ?? '';
      if (imagePath.isEmpty) {
        Get.back();
        Get.snackbar(
          LocaleKeys.common_error.tr,
          LocaleKeys.home_error_loading.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }
    
    quickAction = args?['quickAction'];
    format = args?['format'];
    originalImagePath = args?['originalImagePath'];
    stateHistoryPath = args?['stateHistoryPath'];
    // Read projectId from arguments - used to update existing projects instead of creating new ones
    projectId = args?['projectId'];
    
    // Load state history if available (for reopening projects with editable layers)
    if (stateHistoryPath != null) {
      _loadStateHistory();
      // No need to set special state - package's canUndo handles this correctly
      // with enableInitialEmptyState: false in ImportEditorConfigs
    }
  }
  
  @override
  void onClose() {
    // Clear references to prevent memory leaks
    editorKey = null;
    _editorState = null;
    editedImageBytes = null;
    loadedStateHistory = null;
    super.onClose();
  }
  
  /// Load state history from file if stateHistoryPath is provided
  Future<void> _loadStateHistory() async {
    if (stateHistoryPath == null) return;
    
    isLoadingHistory.value = true;
    
    try {
      final file = File(stateHistoryPath!);
      if (await file.exists()) {
        // Read file content as string and parse with ImportStateHistory.fromJson
        final jsonString = await file.readAsString();
        
        // Validate JSON is not empty
        if (jsonString.trim().isEmpty) {
          debugPrint('>>> State history file is empty: $stateHistoryPath');
          return;
        }
        
        loadedStateHistory = ImportStateHistory.fromJson(
          jsonString,
          configs: ImportEditorConfigs(
            recalculateSizeAndPosition: true,
            mergeMode: ImportEditorMergeMode.replace,
            // IMPORTANT: Disable initial empty state to keep history pointer consistent
            // Without this, the editor adds an empty state at position 0 which offsets
            // all positions by +1, making change detection unreliable
            enableInitialEmptyState: false,
            // Provide widgetLoader to restore icon stickers from their ID
            widgetLoader: _widgetLoader,
          ),
        );
        debugPrint('>>> State history loaded from: $stateHistoryPath');
        debugPrint('>>> Loaded history position: ${loadedStateHistory!.editorPosition}, stateHistory length: ${loadedStateHistory!.stateHistory.length}');
      } else {
        debugPrint('>>> State history file not found: $stateHistoryPath');
        // Clear stateHistoryPath since file doesn't exist
        stateHistoryPath = null;
      }
    } on FormatException catch (e) {
      debugPrint('>>> Invalid state history JSON format: $e');
      stateHistoryPath = null;
      Get.snackbar(
        LocaleKeys.common_error.tr,
        LocaleKeys.editor_error_restore_history.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('>>> Error loading state history: $e');
      stateHistoryPath = null;
    } finally {
      isLoadingHistory.value = false;
    }
  }
  
  /// Generates a blank canvas image and sets imagePath
  /// 
  /// This converts blank canvas mode into regular file mode by generating
  /// a solid color image file. This gives access to all editing tools.
  /// If [backgroundImagePath] is provided, the user's image is center-cropped
  /// to fill the canvas instead of using a solid colour.
  /// [cropRect] allows specifying a user-chosen portion (normalised 0..1).
  Future<void> _generateBlankCanvas(
    Size size,
    Color? color,
    String? backgroundImagePath,
    Rect? cropRect,
  ) async {
    try {
      final String canvasPath;

      if (backgroundImagePath != null) {
        canvasPath = await CanvasGenerator.generateCanvasWithImage(
          size: size,
          imagePath: backgroundImagePath,
          cropRect: cropRect,
        );
      } else {
        canvasPath = await CanvasGenerator.generateCanvas(
          size: size,
          color: color,
        );
      }
      
      // Set the generated image as our source
      imagePath = canvasPath;
      
      debugPrint('[Editor] Generated canvas image: $canvasPath');
    } catch (e) {
      debugPrint('[Editor] Failed to generate canvas: $e');
      Get.snackbar(
        LocaleKeys.common_error.tr,
        LocaleKeys.editor_error_create_canvas.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } finally {
      isLoadingHistory.value = false;
    }
  }
  
  /// Widget loader for restoring stickers from their export ID
  /// Handles icon stickers with format: 'icon_{codePoint}_{colorValue}'
  /// For gallery stickers, the package uses fileUrl directly (not this loader)
  Widget _widgetLoader(String id, {Map<String, dynamic>? meta}) {
    // Parse icon sticker ID format: 'icon_{codePoint}_{colorValue}'
    if (id.startsWith('icon_')) {
      final parts = id.split('_');
      if (parts.length >= 3) {
        final codePoint = int.tryParse(parts[1]);
        final colorValue = int.tryParse(parts[2]);
        
        if (codePoint != null && colorValue != null) {
          return Icon(
            IconData(codePoint, fontFamily: 'MaterialIcons'),
            size: 100,
            color: Color(colorValue),
          );
        }
      }
      // Icon ID format was recognized but parsing failed
      debugPrint('>>> Failed to parse icon sticker ID: $id');
      return const Icon(
        Icons.broken_image,
        size: 100,
        color: Colors.grey,
      );
    }
    
    // For non-icon stickers, check if id is a file path (gallery sticker fallback)
    if (id.contains('/') && (id.endsWith('.png') || id.endsWith('.jpg') || id.endsWith('.jpeg'))) {
      final file = File(id);
      if (file.existsSync()) {
        debugPrint('>>> Loading sticker from file path: $id');
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            file,
            fit: BoxFit.contain,
            width: 200,
            height: 200,
          ),
        );
      }
    }
    
    // Unknown ID format - return placeholder
    debugPrint('>>> Unknown sticker ID: $id');
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: const Icon(
        Icons.image_not_supported,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE MACHINE: TRANSITIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Called when import history completes (for reopened projects).
  /// Capture the initial state so we can detect new changes.
  void onImportHistoryComplete(StateManager stateManager) {
    _captureInitialState();
    debugPrint('[Editor] Import history completed');
  }

  /// Called from ProImageEditor's onStateHistoryChange callback.
  /// We keep a reference to the editor state and capture initial state on first call.
  void onEditorStateChanged(StateManager stateManager, ProImageEditorState editor) {
    final isFirstCall = _editorState == null;
    _editorState = editor;
    
    // Capture initial state on first callback ONLY for new projects (no loaded history).
    // For reopened projects with history, onImportHistoryEnd will capture the initial state
    // after import completes - capturing here would capture the wrong pointer (before import).
    if (isFirstCall && _initialHistoryPointer == null && loadedStateHistory == null) {
      _captureInitialState();
    }
  }
  
  /// Capture the current state as the "initial" state for change detection.
  void _captureInitialState() {
    _initialHistoryPointer = currentHistoryPointer;
    _initialHistoryLength = currentHistoryLength;
    debugPrint('[Editor] Initial state captured: pointer=$_initialHistoryPointer, length=$_initialHistoryLength');
  }
  
  /// Internal: transition to new state
  void _transition(EditingSessionState newState) {
    if (_sessionState.value == newState) return;
    _sessionState.value = newState;
  }
  
  /// Mark current state as saved (draft).
  /// Records the history pointer to detect subsequent changes.
  void _markAsSaved() {
    _historyPointerAtSave = currentHistoryPointer;
    _historyLengthAtSave = currentHistoryLength;
    _transition(EditingSessionState.saved);
  }
  
  /// Mark as exported (final image saved/shared).
  void _markAsExported() {
    _transition(EditingSessionState.exported);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE MACHINE: CLOSE HANDLING
  // ═══════════════════════════════════════════════════════════════════════════

  // NOTE: Close-with-unsaved-changes is handled by the package's
  // closeWarningDialog → DraftExitSheet in editor_style_configs.dart.
  // The sheet captures the image, saves the draft, and returns a
  // DraftAction. The package then calls onCloseEditor which simply
  // pops the editor page.
  
  /// Clear editing state (bytes and session state).
  /// Does NOT navigate - caller is responsible for navigation.
  void clearState() {
    editedImageBytes = null;
    _sessionState.value = EditingSessionState.clean;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // EDITOR IMAGE PATH
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Get the image path to use for the editor
  /// If we have original image and state history, use original image as base
  String get editorImagePath {
    if (originalImagePath != null && loadedStateHistory != null) {
      return originalImagePath!;
    }
    return imagePath;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save to gallery
  Future<void> saveToGallery() async {
    debugPrint('>>> saveToGallery called, editedImageBytes is ${editedImageBytes == null ? "NULL" : "${editedImageBytes!.length} bytes"}');
    
    if (editedImageBytes == null) {
      debugPrint('>>> saveToGallery: No edited image bytes available');
      Get.snackbar(
        LocaleKeys.common_error.tr,
        LocaleKeys.editor_error_no_image.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }
    
    debugPrint('>>> saveToGallery: Saving ${editedImageBytes!.length} bytes...');
    isSaving.value = true;
    
    final success = await ExportService.saveToGallery(editedImageBytes!);
    
    debugPrint('>>> saveToGallery: Result = $success');
    isSaving.value = false;
    
    if (success) {
      // Transition to EXPORTED state
      _markAsExported();
      
      // Save to recent projects
      await _saveToRecentProjects();
      
      Get.snackbar(
        LocaleKeys.common_success.tr,
        LocaleKeys.editor_saved_to_gallery.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        LocaleKeys.common_error.tr,
        LocaleKeys.editor_save_failed.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Share image
  Future<void> shareImage() async {
    if (editedImageBytes == null) return;
    
    isSaving.value = true;
    
    final success = await ExportService.shareImage(editedImageBytes!);
    
    isSaving.value = false;
    
    if (success) {
      // Transition to EXPORTED state
      _markAsExported();
      // Also save to recent projects when sharing
      await _saveToRecentProjects();
    } else {
      Get.snackbar(
        LocaleKeys.common_error.tr,
        LocaleKeys.editor_share_failed.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Save as draft (project only, no gallery export).
  ///
  /// Returns `true` on success, `false` on failure.
  /// When [showFeedback] is `false` the success/error snackbar is suppressed
  /// (used by [DraftExitSheet] which provides its own visual feedback).
  Future<bool> saveDraft({bool showFeedback = true}) async {
    if (editedImageBytes == null) return false;
    
    isSaving.value = true;
    
    try {
      await _saveToRecentProjects();
      
      // Transition to SAVED and record save point
      _markAsSaved();
      
      if (showFeedback) {
        Get.snackbar(
          LocaleKeys.common_success.tr,
          LocaleKeys.export_draft_saved.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
      return true;
    } catch (e) {
      debugPrint('>>> Error saving draft: $e');
      if (showFeedback) {
        Get.snackbar(
          LocaleKeys.common_error.tr,
          LocaleKeys.export_failed.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJECT PERSISTENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save to recent projects with edited image and state history
  Future<void> _saveToRecentProjects() async {
    if (editedImageBytes == null) return;
    
    try {
      final storage = ProjectStorage();
      final id = projectId ?? ProjectStorage.generateId();
      final isExistingProject = projectId != null;
      
      // Get existing project data to preserve createdAt
      DateTime createdAt = DateTime.now();
      if (isExistingProject) {
        final existingProjects = storage.getRecentProjects();
        final existing = existingProjects.where((p) => p.id == id).firstOrNull;
        if (existing != null) {
          createdAt = existing.createdAt;
        }
      }
      
      // Save edited image in app documents (this is what we'll reopen)
      final appDir = await getApplicationDocumentsDirectory();
      final projectsDir = Directory('${appDir.path}/projects');
      if (!await projectsDir.exists()) {
        await projectsDir.create(recursive: true);
      }
      
      // Save the full edited image (for thumbnail/preview)
      final editedImagePath = '${projectsDir.path}/$id.png';
      final editedImageFile = File(editedImagePath);
      await editedImageFile.writeAsBytes(editedImageBytes!);
      
      debugPrint('>>> Edited image saved at: $editedImagePath');
      
      // Export state history if editor is available
      String? savedStateHistoryPath;
      String? savedOriginalImagePath;
      
      if (editorKey?.currentState != null) {
        try {
          final editorState = editorKey!.currentState!;
          
          // Wait until the render pipeline is fully quiescent before
          // exporting state history.  A single endOfFrame isn't enough
          // when multiple frames are scheduled (e.g. animation ticks).
          // We keep draining frames until no more are pending, with a
          // safety cap to avoid an infinite loop.
          for (int i = 0; i < 10; i++) {
            await SchedulerBinding.instance.endOfFrame;
            if (!SchedulerBinding.instance.hasScheduledFrame) break;
          }
          
          final stateHistory = await editorState.exportStateHistory(
            configs: const ExportEditorConfigs(
              historySpan: ExportHistorySpan.all,
              exportPaint: true,
              exportText: true,
              exportCropRotate: true,
              exportFilter: true,
              exportTuneAdjustments: true,
              exportEmoji: true,
              exportBlur: true,
              exportWidgets: true,
              enableMinify: true,
            ),
          );
          
          // Save state history to JSON file
          savedStateHistoryPath = '${projectsDir.path}/$id.history.json';
          await stateHistory.toFile(path: savedStateHistoryPath);
          debugPrint('>>> State history saved at: $savedStateHistoryPath');
          
          // Save original image path (the source before edits)
          // If we already have an original, keep it; otherwise use current imagePath
          savedOriginalImagePath = originalImagePath ?? imagePath;
          
          // Copy original image if it's not already in projects dir
          if (!savedOriginalImagePath.contains(projectsDir.path)) {
            final originalDestPath = '${projectsDir.path}/$id.original.png';
            final originalFile = File(savedOriginalImagePath);
            if (await originalFile.exists()) {
              await originalFile.copy(originalDestPath);
              savedOriginalImagePath = originalDestPath;
              debugPrint('>>> Original image copied to: $originalDestPath');
              
              // Clean up temp canvas file if this was a blank canvas
              // (temp files have paths like: /tmp/canvas_1080x1920_timestamp.png)
              if (imagePath.contains('canvas_') && 
                  imagePath.contains(Directory.systemTemp.path)) {
                try {
                  final tempCanvas = File(imagePath);
                  if (await tempCanvas.exists()) {
                    await tempCanvas.delete();
                    debugPrint('>>> Cleaned up temp canvas: $imagePath');
                  }
                } catch (e) {
                  debugPrint('>>> Failed to clean temp canvas: $e');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('>>> Error exporting state history: $e');
          // Continue saving without state history
        }
      }
      
      // Update projectId so subsequent saves update the same project
      projectId = id;
      
      await storage.saveProject(Project(
        id: id,
        imagePath: editedImagePath, // Use the EDITED image for preview
        thumbnailPath: editedImagePath,
        stateHistoryPath: savedStateHistoryPath, // State history for editable layers
        originalImagePath: savedOriginalImagePath, // Original image for re-editing
        createdAt: createdAt, // Preserve original creation date
        lastEditedAt: DateTime.now(),
      ));
      
      debugPrint('>>> Project ${isExistingProject ? "updated" : "created"} with editable layers');
      
      // Refresh home controller's recent projects list
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadRecentProjects();
        debugPrint('>>> Home controller refreshed');
      }
    } catch (e) {
      debugPrint('>>> Error saving to recent projects: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  /// Navigate to export page (public method)
  void showExportSheet() {
    debugPrint('[Editor] Navigating to export page');
    if (editedImageBytes == null) {
      debugPrint('[Editor] No image bytes to export');
      return;
    }

    Get.toNamed(
      Routes.EXPORT,
      arguments: {
        'imageBytes': editedImageBytes,
        'onSaveComplete': () {
          // Transition to EXPORTED state when export completes
          _markAsExported();
        },
        'onSaveToRecentProjects': () async {
          await _saveToRecentProjects();
        },
        'onDiscard': () {
          // Clear state - export page handles navigation to home
          clearState();
        },
      },
    )?.then((result) {
      // If export was successful, go back to home
      if (result == true) {
        Get.back(); // Close editor
      }
    });
  }
}
