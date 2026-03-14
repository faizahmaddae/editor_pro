import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

/// Project model for persistence
class Project {
  final String id;
  final String imagePath;
  final String? thumbnailPath;
  /// Path to the state history JSON file for editable layers
  /// When present, the project can be reopened with all layers intact
  final String? stateHistoryPath;
  /// Path to the original image (before any edits)
  /// Used as the base image when loading state history
  final String? originalImagePath;
  final DateTime createdAt;
  final DateTime lastEditedAt;

  Project({
    required this.id,
    required this.imagePath,
    this.thumbnailPath,
    this.stateHistoryPath,
    this.originalImagePath,
    required this.createdAt,
    required this.lastEditedAt,
  });

  /// Returns true if this project has editable state history
  bool get hasEditableHistory => stateHistoryPath != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'thumbnailPath': thumbnailPath,
    'stateHistoryPath': stateHistoryPath,
    'originalImagePath': originalImagePath,
    'createdAt': createdAt.toIso8601String(),
    'lastEditedAt': lastEditedAt.toIso8601String(),
  };

  factory Project.fromJson(Map<String, dynamic> json) {
    // Schema migration: handle missing/malformed fields from older versions
    return Project(
      id: json['id'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      thumbnailPath: json['thumbnailPath'] as String?,
      stateHistoryPath: json['stateHistoryPath'] as String?,
      originalImagePath: json['originalImagePath'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastEditedAt: json['lastEditedAt'] != null
          ? DateTime.tryParse(json['lastEditedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Project copyWith({
    String? id,
    String? imagePath,
    String? thumbnailPath,
    String? stateHistoryPath,
    String? originalImagePath,
    DateTime? createdAt,
    DateTime? lastEditedAt,
  }) => Project(
    id: id ?? this.id,
    imagePath: imagePath ?? this.imagePath,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    stateHistoryPath: stateHistoryPath ?? this.stateHistoryPath,
    originalImagePath: originalImagePath ?? this.originalImagePath,
    createdAt: createdAt ?? this.createdAt,
    lastEditedAt: lastEditedAt ?? this.lastEditedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Storage service for recent projects
/// 
/// Uses get_storage for simplicity:
/// - Single file storage, no schema migrations
/// - Synchronous reads, fast startup
/// - Perfect for simple key-value data like recent projects
class ProjectStorage {
  static const String _key = 'recent_projects';
  static const int _maxProjects = 20;
  
  final GetStorage _box;

  ProjectStorage() : _box = GetStorage('projects');

  /// Initialize storage (call once at app startup)
  static Future<void> init() async {
    await GetStorage.init('projects');
  }

  /// Get all recent projects, sorted by last edited (newest first)
  List<Project> getRecentProjects() {
    final data = _box.read<String>(_key);
    if (data == null || data.isEmpty) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      final projects = jsonList
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Sort by lastEditedAt descending
      projects.sort((a, b) => b.lastEditedAt.compareTo(a.lastEditedAt));
      return projects;
    } catch (e) {
      return [];
    }
  }

  /// Save or update a project
  Future<void> saveProject(Project project) async {
    final projects = getRecentProjects();
    
    // Remove existing project with same ID
    projects.removeWhere((p) => p.id == project.id);
    
    // Add new project at the start
    projects.insert(0, project);
    
    // Keep only max number of projects
    final trimmed = projects.take(_maxProjects).toList();
    
    await _saveProjects(trimmed);
  }

  /// Delete a project by ID
  /// Also cleans up associated files (state history, original image, edited image)
  Future<void> deleteProject(String id) async {
    final projects = getRecentProjects();
    
    // Find the project to get file paths before removing
    final projectToDelete = projects.where((p) => p.id == id).firstOrNull;
    
    if (projectToDelete != null) {
      // Clean up associated files
      await _cleanupProjectFiles(projectToDelete);
    }
    
    projects.removeWhere((p) => p.id == id);
    await _saveProjects(projects);
  }
  
  /// Clean up all files associated with a project
  Future<void> _cleanupProjectFiles(Project project) async {
    final filesToDelete = <String>[
      project.imagePath, // Edited image
      if (project.thumbnailPath != null) project.thumbnailPath!,
      if (project.originalImagePath != null) project.originalImagePath!,
    ];
    
    // Parse state history to find sticker files referenced in widget layers
    if (project.stateHistoryPath != null) {
      try {
        final historyFile = File(project.stateHistoryPath!);
        if (await historyFile.exists()) {
          final jsonString = await historyFile.readAsString();
          final stickerFiles = _extractStickerFilesFromHistory(jsonString);
          filesToDelete.addAll(stickerFiles);
          // Add the history file itself
          filesToDelete.add(project.stateHistoryPath!);
        }
      } catch (e) {
        debugPrint('>>> Failed to parse state history for sticker cleanup: $e');
        // Still try to delete the history file
        filesToDelete.add(project.stateHistoryPath!);
      }
    }
    
    for (final path in filesToDelete) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          debugPrint('>>> Deleted file: $path');
        }
      } catch (e) {
        debugPrint('>>> Failed to delete file $path: $e');
        // Continue deleting other files even if one fails
      }
    }
  }
  
  /// Extract sticker file paths from state history JSON
  /// Looks for fileUrl fields in widget layers
  List<String> _extractStickerFilesFromHistory(String jsonString) {
    final stickerFiles = <String>[];
    
    try {
      final json = jsonDecode(jsonString);
      
      // State history structure: { stateHistory: [...], position: n }
      // Each history item may have layers with widget layers containing fileUrl
      final stateHistory = json['stateHistory'] as List<dynamic>?;
      if (stateHistory == null) return stickerFiles;
      
      for (final historyItem in stateHistory) {
        final layers = historyItem['layers'] as List<dynamic>?;
        if (layers == null) continue;
        
        for (final layer in layers) {
          // Check if this is a widget layer with a fileUrl (gallery sticker)
          final exportConfigs = layer['exportConfigs'] as Map<String, dynamic>?;
          if (exportConfigs != null) {
            final fileUrl = exportConfigs['fileUrl'] as String?;
            if (fileUrl != null && fileUrl.isNotEmpty) {
              stickerFiles.add(fileUrl);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('>>> Error extracting sticker files: $e');
    }
    
    return stickerFiles.toSet().toList(); // Remove duplicates
  }

  /// Clear all projects
  Future<void> clearAll() async {
    await _box.remove(_key);
  }

  /// Internal: persist projects list
  Future<void> _saveProjects(List<Project> projects) async {
    final jsonList = projects.map((p) => p.toJson()).toList();
    await _box.write(_key, jsonEncode(jsonList));
  }

  /// Generate a unique project ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
