import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Service for generating blank canvas images
/// 
/// Creates solid color images with specified dimensions using dart:ui.
/// This allows us to use normal ProImageEditor.file() instead of blank mode,
/// giving access to all editing tools (crop, filter, tune, blur, etc.)
class CanvasGenerator {
  CanvasGenerator._();

  /// Generates a solid color image and saves it to a temp file
  /// 
  /// [size] - The dimensions of the canvas (e.g., 1080x1920)
  /// [color] - The background color (defaults to white if null)
  /// 
  /// Returns the path to the generated image file
  static Future<String> generateCanvas({
    required Size size,
    Color? color,
  }) async {
    final bgColor = color ?? Colors.white;
    
    // Create the image using dart:ui
    final bytes = await _createColoredImage(
      width: size.width.toInt(),
      height: size.height.toInt(),
      color: bgColor,
    );
    
    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final fileName = 'canvas_${size.width.toInt()}x${size.height.toInt()}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    
    debugPrint('[CanvasGenerator] Created canvas: ${file.path} (${size.width}x${size.height}, color: $bgColor)');
    
    return file.path;
  }

  /// Creates a PNG image with solid color using dart:ui
  static Future<Uint8List> _createColoredImage({
    required int width,
    required int height,
    required Color color,
  }) async {
    // Create a picture recorder to draw on
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    
    // Draw a filled rectangle with the color
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );
    
    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    
    // Encode as PNG
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('Failed to encode image as PNG');
    }
    
    return byteData.buffer.asUint8List();
  }

  /// Generates a canvas with a user-picked image as background.
  ///
  /// The source image is decoded, then drawn to **cover** the target [size]
  /// (center-crop, like [BoxFit.cover]) so it fills the canvas without
  /// distortion. The result is saved as PNG in the temp directory.
  ///
  /// If [cropRect] is provided it must be normalised (0…1 for each axis) and
  /// describes the user-chosen visible portion of the source image.
  static Future<String> generateCanvasWithImage({
    required Size size,
    required String imagePath,
    Rect? cropRect,
  }) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();

    // Decode source image
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final targetW = size.width.toInt();
    final targetH = size.height.toInt();

    late final Rect srcRect;

    if (cropRect != null) {
      // User-defined crop: cropRect is normalised to 0..1.
      // Map it to actual source-image pixels.
      srcRect = Rect.fromLTWH(
        cropRect.left * srcImage.width,
        cropRect.top * srcImage.height,
        cropRect.width * srcImage.width,
        cropRect.height * srcImage.height,
      );
    } else {
      // Default: center-crop to cover the target aspect ratio.
      final srcRatio = srcImage.width / srcImage.height;
      final dstRatio = size.width / size.height;

      if (srcRatio > dstRatio) {
        final cropW = srcImage.height * dstRatio;
        final dx = (srcImage.width - cropW) / 2;
        srcRect = Rect.fromLTWH(dx, 0, cropW, srcImage.height.toDouble());
      } else {
        final cropH = srcImage.width / dstRatio;
        final dy = (srcImage.height - cropH) / 2;
        srcRect = Rect.fromLTWH(0, dy, srcImage.width.toDouble(), cropH);
      }
    }

    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawImageRect(srcImage, srcRect, dstRect, ui.Paint());

    final picture = recorder.endRecording();
    final image = await picture.toImage(targetW, targetH);
    final encoded = await image.toByteData(format: ui.ImageByteFormat.png);

    if (encoded == null) {
      throw Exception('Failed to encode image-background canvas as PNG');
    }

    final tempDir = await getTemporaryDirectory();
    final fileName =
        'canvas_img_${targetW}x$targetH'
        '_${DateTime.now().millisecondsSinceEpoch}.png';
    final outFile = File('${tempDir.path}/$fileName');
    await outFile.writeAsBytes(encoded.buffer.asUint8List());

    debugPrint(
      '[CanvasGenerator] Created image-bg canvas: ${outFile.path} '
      '(${size.width}x${size.height})',
    );

    srcImage.dispose();
    image.dispose();

    return outFile.path;
  }
}
