import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Export format options
enum ExportFormat {
  png,
  jpg,
}

/// Export quality levels
enum ExportQuality {
  low(30),
  medium(60),
  high(85),
  maximum(100);

  final int value;
  const ExportQuality(this.value);
}

/// Export options configuration
class ExportOptions {
  final ExportFormat format;
  final ExportQuality quality;

  const ExportOptions({
    this.format = ExportFormat.png,
    this.quality = ExportQuality.high,
  });

  String get extension => format == ExportFormat.png ? 'png' : 'jpg';
}

/// Export service for saving and sharing images
class ExportService {
  ExportService._();

  /// Save image bytes to gallery
  static Future<bool> saveToGallery(
    Uint8List imageBytes, {
    String? albumName,
  }) async {
    try {
      debugPrint('ExportService.saveToGallery: Starting with ${imageBytes.length} bytes');
      
      // Request permission first
      final hasAccess = await Gal.hasAccess(toAlbum: albumName != null);
      debugPrint('ExportService.saveToGallery: hasAccess = $hasAccess');
      
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: albumName != null);
        debugPrint('ExportService.saveToGallery: Permission granted = $granted');
        if (!granted) {
          debugPrint('ExportService.saveToGallery: Permission denied');
          return false;
        }
      }
      
      // Save to temp file first
      final tempDir = await getTemporaryDirectory();
      final fileName = 'editor_pro_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(imageBytes);
      debugPrint('ExportService.saveToGallery: Temp file created at ${tempFile.path}');

      // Save to gallery using gal
      await Gal.putImage(tempFile.path, album: albumName);
      debugPrint('ExportService.saveToGallery: Image saved to gallery');

      // Clean up temp file
      await tempFile.delete();
      debugPrint('ExportService.saveToGallery: Temp file deleted');

      return true;
    } catch (e, stackTrace) {
      debugPrint('ExportService.saveToGallery: Failed - $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Share image bytes
  static Future<bool> shareImage(
    Uint8List imageBytes, {
    String? text,
  }) async {
    File? tempFile;
    try {
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'editor_pro_${DateTime.now().millisecondsSinceEpoch}.png';
      tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(imageBytes);

      // Share
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: text,
      );

      return true;
    } catch (e) {
      debugPrint('Failed to share: $e');
      return false;
    } finally {
      // Clean up temp file
      try {
        await tempFile?.delete();
      } catch (_) {}
    }
  }

  /// Save image to app documents with custom options
  static Future<String?> saveToDocuments(
    Uint8List imageBytes,
    ExportOptions options,
  ) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final fileName = 'editor_pro_${DateTime.now().millisecondsSinceEpoch}.${options.extension}';
      final file = File('${docDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      debugPrint('Failed to save to documents: $e');
      return null;
    }
  }

  /// Get temporary file path for edited image
  static Future<String> getTempFilePath(String extension) async {
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/editor_pro_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }
}
