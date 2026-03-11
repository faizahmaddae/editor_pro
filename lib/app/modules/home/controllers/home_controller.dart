import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';
import '../../../data/services/project_storage.dart';

/// Home screen controller
class HomeController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final ProjectStorage _storage = ProjectStorage();

  // State
  final RxList<Project> recentProjects = <Project>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Selected quick action (for navigation to editor with specific tool)
  String? _pendingQuickAction;
  
  // For undo delete
  Project? _pendingDeleteProject;

  @override
  void onInit() {
    super.onInit();
    loadRecentProjects();
  }

  /// Load recent projects from storage
  Future<void> loadRecentProjects() async {
    // Clear the entire image cache (including ResizeImage wrappers created
    // by cacheWidth in Image.file). Per-key eviction with FileImage misses
    // the ResizeImage entries, causing stale thumbnails after re-editing.
    imageCache.clear();
    imageCache.clearLiveImages();
    
    final projects = _storage.getRecentProjects();
    if (kDebugMode) {
      debugPrint('>>> HomeController.loadRecentProjects: Found ${projects.length} projects');
      for (var p in projects) {
        debugPrint('>>> Project: ${p.id}, thumbnail: ${p.thumbnailPath}, hasHistory: ${p.hasEditableHistory}');
      }
    }
    // Clear and reassign to ensure reactive update triggers
    recentProjects.clear();
    recentProjects.addAll(projects);
    recentProjects.refresh(); // Force UI to rebuild
    if (kDebugMode) debugPrint('>>> HomeController: recentProjects refreshed, count: ${recentProjects.length}');

    // Give the RefreshIndicator time to show the spinner visibly
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Pick image from gallery
  Future<void> pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  /// Pick image from camera
  Future<void> pickFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  /// Quick action - picks image then opens specific tool
  Future<void> quickAction(String action) async {
    _pendingQuickAction = action;
    await _pickImage(ImageSource.gallery);
  }

  /// Internal pick image handler
  Future<void> _pickImage(ImageSource source) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image != null) {
        // Verify file exists
        final file = File(image.path);
        if (!await file.exists()) {
          errorMessage.value = LocaleKeys.home_error_loading.tr;
          _clearPendingActions();
          return;
        }

        // Build navigation arguments
        final Map<String, dynamic> args = {'imagePath': image.path};
        
        // Add quick action if pending
        if (_pendingQuickAction != null) {
          args['quickAction'] = _pendingQuickAction;
          _pendingQuickAction = null;
        }
        
        // Navigate to editor with the image path
        Get.toNamed('/editor', arguments: args);
      } else {
        _clearPendingActions();
      }
    } catch (e) {
      errorMessage.value = LocaleKeys.home_error_loading.tr;
      _clearPendingActions();
      if (kDebugMode) debugPrint('Error picking image: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  void _clearPendingActions() {
    _pendingQuickAction = null;
  }

  /// Open existing project
  Future<void> openProject(Project project) async {
    final file = File(project.imagePath);
    if (await file.exists()) {
      // Build arguments with state history info if available
      final Map<String, dynamic> args = {
        'imagePath': project.imagePath,
        'projectId': project.id,
      };
      
      // If project has editable history, pass it along
      if (project.hasEditableHistory) {
        args['stateHistoryPath'] = project.stateHistoryPath;
        args['originalImagePath'] = project.originalImagePath;
        if (kDebugMode) {
          debugPrint('>>> Opening project with editable history');
          debugPrint('>>>   stateHistoryPath: ${project.stateHistoryPath}');
          debugPrint('>>>   originalImagePath: ${project.originalImagePath}');
        }
      }
      
      // Precache the image before navigating for smoother editor opening
      try {
        final imageToCache = project.hasEditableHistory && project.originalImagePath != null
            ? project.originalImagePath!
            : project.imagePath;
        await precacheImage(
          FileImage(File(imageToCache)),
          Get.context!,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('>>> Precache failed (non-critical): $e');
      }
      
      Get.toNamed('/editor', arguments: args);
    } else {
      // File no longer exists, remove from recent
      await deleteProject(project.id);
      Get.snackbar(
        LocaleKeys.common_error.tr,
        LocaleKeys.home_error_loading.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: GroundedTheme.surface,
        colorText: GroundedTheme.textPrimary,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Soft delete - removes from UI without deleting files yet
  void softDeleteProject(Project project) {
    _pendingDeleteProject = project;
    recentProjects.removeWhere((p) => p.id == project.id);
  }

  /// Undo the soft delete - restore project to list
  void undoDeleteProject() {
    if (_pendingDeleteProject != null) {
      recentProjects.add(_pendingDeleteProject!);
      recentProjects.sort((a, b) => b.lastEditedAt.compareTo(a.lastEditedAt));
      _pendingDeleteProject = null;
    }
  }

  /// Confirm and permanently delete the project and its files
  Future<void> confirmDeleteProject() async {
    if (_pendingDeleteProject != null) {
      await _storage.deleteProject(_pendingDeleteProject!.id);
      _pendingDeleteProject = null;
    }
  }

  /// Delete a project immediately (for internal use, e.g. missing files)
  Future<void> deleteProject(String id) async {
    await _storage.deleteProject(id);
    loadRecentProjects();
  }

  /// Refresh projects list (called when returning from editor)
  void refreshProjects() {
    loadRecentProjects();
  }
}
