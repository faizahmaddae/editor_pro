import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';
import '../../../core/widgets/glass_icon_button.dart';

/// Grounded-style Image Layer Editor
///
/// Features:
/// - Pick from gallery or camera
/// - Shape masks (circle, rounded, square, hexagon, star, heart, etc.)
/// - Border/stroke options
/// - Shadow options
class ImageLayerEditor extends StatefulWidget {
  const ImageLayerEditor({super.key});

  @override
  State<ImageLayerEditor> createState() => _ImageLayerEditorState();
}

class _ImageLayerEditorState extends State<ImageLayerEditor>
    with SingleTickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  // Shape options
  ImageShape _selectedShape = ImageShape.rectangle;
  double _borderRadius = 12;
  double _borderWidth = 0;
  Color _borderColor = Colors.white;
  bool _hasShadow = false;

  // Size (output size)
  double _imageSize = 200;

  // Image position within shape (for panning)
  Offset _imageOffset = Offset.zero;
  double _imageScale = 1.5;
  double _baseScale = 1.5;
  Offset _baseOffset = Offset.zero;

  // Fade-in animation for source picker entrance
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GroundedTheme.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _selectedImage == null
                  ? _buildSourcePicker()
                  : _buildEditor(),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // App Bar
  // ===========================================================================

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.3),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Close / Back — glass circle
              GlassIconButton(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (_selectedImage != null) {
                    setState(() {
                      _selectedImage = null;
                      _selectedImageBytes = null;
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: _selectedImage != null
                    ? Icons.arrow_back_rounded
                    : Icons.close_rounded,
              ),
              const Spacer(),
              if (_selectedImage != null) ...[
                // Reset
                GlassIconButton(
                  onTap: _resetToDefaults,
                  icon: Icons.refresh_rounded,
                  tooltip: LocaleKeys.common_reset.tr,
                ),
                const SizedBox(width: 6),
                // Done
                _buildDoneButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    if (_isLoading) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: GroundedTheme.textPrimaryDark,
            ),
          ),
        ),
      );
    }
    return GlassIconButton(
      onTap: _addImageLayer,
      icon: Icons.done_rounded,
      tooltip: LocaleKeys.common_done.tr,
    );
  }

  void _resetToDefaults() {
    setState(() {
      _selectedShape = ImageShape.rectangle;
      _borderRadius = 12;
      _borderWidth = 0;
      _borderColor = Colors.white;
      _hasShadow = false;
      _imageSize = 200;
      _imageOffset = Offset.zero;
      _imageScale = 1.5;
      _baseScale = 1.5;
      _baseOffset = Offset.zero;
    });
  }

  // ===========================================================================
  // Source Picker (gallery / camera)
  // ===========================================================================

  Widget _buildSourcePicker() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GroundedTheme.surfaceElevatedDark,
                border: Border.all(
                  color: GroundedTheme.borderDark,
                ),
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                size: 36,
                color: GroundedTheme.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              LocaleKeys.image_add_title.tr,
              style: TextStyle(
                color: GroundedTheme.textPrimaryDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: GroundedTheme.currentFontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.image_add_subtitle.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GroundedTheme.textSecondaryDark,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            // Source buttons
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: LocaleKeys.image_from_gallery.tr,
                    color: GroundedTheme.primary,
                    isLoading: _isLoading,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: LocaleKeys.image_from_camera.tr,
                    color: GroundedTheme.secondary,
                    isLoading: _isLoading,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Editor (preview + controls)
  // ===========================================================================

  Widget _buildEditor() {
    return Column(
      children: [
        Expanded(child: Center(child: _buildImagePreview())),
        _buildBottomPanel(),
      ],
    );
  }

  Widget _buildImagePreview() {
    final innerImageSize = _imageSize * _imageScale;

    Widget innerImage = Transform.translate(
      offset: _imageOffset,
      child: Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: innerImageSize,
        height: innerImageSize,
        gaplessPlayback: true,
      ),
    );

    Widget imageWidget = SizedBox(
      width: _imageSize,
      height: _imageSize,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: innerImageSize,
          maxHeight: innerImageSize,
          child: innerImage,
        ),
      ),
    );

    // Apply shape clipping
    imageWidget = _applyShapeClipping(imageWidget);

    // Add border (uses CustomPaint so it follows complex shape contours)
    if (_borderWidth > 0) {
      final totalSize = _imageSize + _borderWidth * 2;
      imageWidget = SizedBox(
        width: totalSize,
        height: totalSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Border fill: shape drawn at total size in the border color
            CustomPaint(
              size: Size(totalSize, totalSize),
              painter: _ShapeFillPainter(
                shape: _selectedShape,
                color: _borderColor,
                borderRadius: _selectedShape == ImageShape.roundedRect
                    ? _borderRadius + _borderWidth
                    : _borderRadius,
              ),
            ),
            // Clipped image centered on top
            imageWidget,
          ],
        ),
      );
    }

    // Add shadow
    if (_hasShadow) {
      imageWidget = Container(
        decoration: BoxDecoration(
          shape: _selectedShape == ImageShape.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
          borderRadius: _getShadowBorderRadius(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: imageWidget,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hint
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Opacity(
            opacity: 0.4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pinch_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.image_pinch_and_drag.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        // Interactive preview
        GestureDetector(
          onScaleStart: (details) {
            _baseScale = _imageScale;
            _baseOffset = _imageOffset;
          },
          onScaleUpdate: (details) {
            setState(() {
              final newScale = (_baseScale * details.scale).clamp(1.0, 3.0);
              _imageScale = newScale;

              final innerSize = _imageSize * _imageScale;
              final maxOffset = (innerSize - _imageSize) / 2;

              if (details.scale == 1.0) {
                _imageOffset = Offset(
                  (_imageOffset.dx + details.focalPointDelta.dx)
                      .clamp(-maxOffset, maxOffset),
                  (_imageOffset.dy + details.focalPointDelta.dy)
                      .clamp(-maxOffset, maxOffset),
                );
              } else {
                _imageOffset = Offset(
                  _baseOffset.dx.clamp(-maxOffset, maxOffset),
                  _baseOffset.dy.clamp(-maxOffset, maxOffset),
                );
              }
            });
          },
          onDoubleTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _imageOffset = Offset.zero;
              _imageScale = 1.5;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: _imageSize + (_borderWidth * 2) + (_hasShadow ? 20 : 0),
            height: _imageSize + (_borderWidth * 2) + (_hasShadow ? 20 : 0),
            child: Center(child: imageWidget),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Bottom Panel
  // ===========================================================================

  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: GroundedTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: GroundedTheme.borderDark, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            _buildShapeSelector(),
            const SizedBox(height: 12),
            _buildControlsSection(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeSelector() {
    return SizedBox(
      height: 68,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: ImageShape.values.length,
        itemBuilder: (context, index) {
          final shape = ImageShape.values[index];
          final isSelected = _selectedShape == shape;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedShape = shape);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? GroundedTheme.primary
                    : GroundedTheme.cardDark,
                borderRadius:
                    BorderRadius.circular(GroundedTheme.radiusMedium),
                border: Border.all(
                  color: isSelected
                      ? GroundedTheme.primary
                      : GroundedTheme.borderDark,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ShapeIcon(shape: shape, isSelected: isSelected),
                  const SizedBox(height: 4),
                  Text(
                    _getShapeName(shape),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : GroundedTheme.textSecondaryDark,
                      fontSize: GroundedTheme.fontSizeXS,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Controls
  // ===========================================================================

  Widget _buildControlsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildSliderRow(
            icon: Icons.photo_size_select_large_rounded,
            value: _imageSize,
            min: 80,
            max: 300,
            suffix: 'px',
            onChanged: (v) => setState(() => _imageSize = v),
          ),
          if (_selectedShape == ImageShape.roundedRect)
            _buildSliderRow(
              icon: Icons.rounded_corner_rounded,
              value: _borderRadius,
              min: 0,
              max: 50,
              onChanged: (v) => setState(() => _borderRadius = v),
            ),
          _buildBorderRow(),
          _buildShadowToggle(),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required double value,
    required double min,
    required double max,
    String? suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GroundedTheme.cardDark,
              borderRadius: BorderRadius.circular(GroundedTheme.radiusSmall),
            ),
            child: Icon(icon, color: GroundedTheme.textSecondaryDark, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: GroundedTheme.primary,
                inactiveTrackColor: GroundedTheme.borderDark,
                thumbColor: Colors.white,
                overlayColor: GroundedTheme.primary.withValues(alpha: 0.15),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${value.round()}${suffix ?? ''}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: GroundedTheme.textSecondaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GroundedTheme.cardDark,
              borderRadius: BorderRadius.circular(GroundedTheme.radiusSmall),
            ),
            child: const Icon(Icons.border_style_rounded,
                color: GroundedTheme.textSecondaryDark, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: GroundedTheme.primary,
                inactiveTrackColor: GroundedTheme.borderDark,
                thumbColor: Colors.white,
                overlayColor: GroundedTheme.primary.withValues(alpha: 0.15),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _borderWidth,
                min: 0,
                max: 12,
                onChanged: (v) => setState(() => _borderWidth = v),
              ),
            ),
          ),
          GestureDetector(
            onTap: _showBorderColorPicker,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _borderColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: GroundedTheme.borderDark,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GroundedTheme.cardDark,
              borderRadius: BorderRadius.circular(GroundedTheme.radiusSmall),
            ),
            child: const Icon(Icons.blur_on_rounded,
                color: GroundedTheme.textSecondaryDark, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              LocaleKeys.image_shadow.tr,
              style: const TextStyle(
                color: GroundedTheme.textSecondaryDark,
                fontSize: 14,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: _hasShadow,
              onChanged: (v) => setState(() => _hasShadow = v),
              activeTrackColor: GroundedTheme.primary.withValues(alpha: 0.4),
              activeColor: GroundedTheme.primary,
              inactiveThumbColor: GroundedTheme.textTertiaryDark,
              inactiveTrackColor: GroundedTheme.borderDark,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Shape Clipping
  // ===========================================================================

  Widget _applyShapeClipping(Widget imageWidget) {
    switch (_selectedShape) {
      case ImageShape.circle:
        return ClipOval(child: imageWidget);
      case ImageShape.roundedRect:
        return ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child: imageWidget,
        );
      case ImageShape.rectangle:
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: imageWidget,
        );
      case ImageShape.hexagon:
        return ClipPath(clipper: _HexagonClipper(), child: imageWidget);
      case ImageShape.star:
        return ClipPath(clipper: _StarClipper(), child: imageWidget);
      case ImageShape.heart:
        return ClipPath(clipper: _HeartClipper(), child: imageWidget);
      case ImageShape.diamond:
        return ClipPath(clipper: _DiamondClipper(), child: imageWidget);
      case ImageShape.triangle:
        return ClipPath(clipper: _TriangleClipper(), child: imageWidget);
    }
  }

  BorderRadius? _getShadowBorderRadius() {
    if (_selectedShape == ImageShape.circle) return null;
    if (_selectedShape == ImageShape.roundedRect) {
      return BorderRadius.circular(_borderRadius);
    }
    return BorderRadius.circular(4);
  }

  // ===========================================================================
  // Border Color Picker
  // ===========================================================================

  void _showBorderColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: GroundedTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: GroundedTheme.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                LocaleKeys.image_border_color.tr,
                style: const TextStyle(
                  color: GroundedTheme.textPrimaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _borderColors.length,
                itemBuilder: (context, index) {
                  final color = _borderColors[index];
                  final isSelected = color == _borderColor;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _borderColor = color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Image Picking
  // ===========================================================================

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.selectionClick();

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 4096,
        maxHeight: 4096,
      );

      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);
        final imageBytes = await imageFile.readAsBytes();
        if (!mounted) return;
        await precacheImage(MemoryImage(imageBytes), context);

        if (mounted) {
          setState(() {
            _selectedImage = imageFile;
            _selectedImageBytes = imageBytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          LocaleKeys.common_error.tr,
          LocaleKeys.image_load_failed.tr,
          backgroundColor: GroundedTheme.error.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // Add Image Layer
  // ===========================================================================

  void _addImageLayer() async {
    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);

    try {
      final renderedBytes = await _renderStyledImage();

      if (renderedBytes != null && mounted) {
        final totalSize = _imageSize + (_borderWidth * 2);

        final appDir = await getApplicationDocumentsDirectory();
        final layersDir = Directory('${appDir.path}/image_layers');
        if (!await layersDir.exists()) {
          await layersDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final persistedPath = '${layersDir.path}/layer_$timestamp.png';
        final persistedFile = File(persistedPath);
        await persistedFile.writeAsBytes(renderedBytes);

        // ignore: use_build_context_synchronously
        await precacheImage(FileImage(persistedFile), context);

        if (!mounted) return;

        Navigator.pop(
          context,
          WidgetLayer(
            widget: Image.file(
              persistedFile,
              width: totalSize,
              height: totalSize,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
            width: totalSize,
            exportConfigs: WidgetLayerExportConfigs(
              fileUrl: persistedPath,
            ),
            // Tag for layer identification in reorder sheet
            meta: {'layerType': 'image_layer', 'shape': _selectedShape.name},
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rendering image layer: $e');
      if (mounted) {
        Get.snackbar(
          LocaleKeys.common_error.tr,
          LocaleKeys.image_create_failed.tr,
          backgroundColor: GroundedTheme.error.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // Render Styled Image to PNG
  // ===========================================================================

  Future<Uint8List?> _renderStyledImage() async {
    final totalSize = _imageSize + (_borderWidth * 2);

    // Render at 3× for high-DPI quality
    const double renderScale = 3.0;
    final scaledTotal = totalSize * renderScale;
    final scaledImageSize = _imageSize * renderScale;
    final scaledBorderWidth = _borderWidth * renderScale;

    final codec = await ui.instantiateImageCodec(_selectedImageBytes!);
    final frame = await codec.getNextFrame();
    final sourceImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Match BoxFit.cover: use the SHORTER side of the source so the image
    // fills the square destination (same as the preview widget).
    final srcW = sourceImage.width.toDouble();
    final srcH = sourceImage.height.toDouble();
    final coverSize = math.min(srcW, srcH);

    // The preview maps _imageOffset in logical (display) pixels.
    // Convert to source-pixel space: offset / (_imageScale * _imageSize) * coverSize
    final pixelsPerLogical = coverSize / _imageSize;
    final srcCenterX = srcW / 2 - (_imageOffset.dx / _imageScale) * pixelsPerLogical;
    final srcCenterY = srcH / 2 - (_imageOffset.dy / _imageScale) * pixelsPerLogical;
    final srcHalfSize = (coverSize / _imageScale) / 2;

    final srcRect = Rect.fromLTRB(
      (srcCenterX - srcHalfSize).clamp(0, srcW),
      (srcCenterY - srcHalfSize).clamp(0, srcH),
      (srcCenterX + srcHalfSize).clamp(0, srcW),
      (srcCenterY + srcHalfSize).clamp(0, srcH),
    );

    final dstRect = Rect.fromLTWH(
        scaledBorderWidth, scaledBorderWidth, scaledImageSize, scaledImageSize);
    final clipPath = _getShapePath(dstRect);

    // Shadow
    if (_hasShadow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * renderScale);
      canvas.save();
      canvas.translate(0, 4 * renderScale);
      canvas.drawPath(clipPath, shadowPaint);
      canvas.restore();
    }

    // Border
    if (_borderWidth > 0) {
      final borderPath =
          _getShapePath(Rect.fromLTWH(0, 0, scaledTotal, scaledTotal));
      final borderPaint = Paint()..color = _borderColor;
      canvas.drawPath(borderPath, borderPaint);
    }

    // Clip and draw image with high-quality filtering
    canvas.save();
    canvas.clipPath(clipPath);
    canvas.drawImageRect(
      sourceImage,
      srcRect,
      dstRect,
      Paint()..filterQuality = ui.FilterQuality.high,
    );
    canvas.restore();

    final picture = recorder.endRecording();
    final renderedImage =
        await picture.toImage(scaledTotal.toInt(), scaledTotal.toInt());
    final byteData =
        await renderedImage.toByteData(format: ui.ImageByteFormat.png);

    sourceImage.dispose();
    renderedImage.dispose();

    return byteData?.buffer.asUint8List();
  }

  // ===========================================================================
  // Shape Path Generation
  // ===========================================================================

  Path _getShapePath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;
    final left = rect.left;
    final top = rect.top;

    switch (_selectedShape) {
      case ImageShape.circle:
        path.addOval(rect);
        break;

      case ImageShape.roundedRect:
        path.addRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(_borderRadius)));
        break;

      case ImageShape.rectangle:
        path.addRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)));
        break;

      case ImageShape.hexagon:
        path.moveTo(left + w * 0.5, top);
        path.lineTo(left + w, top + h * 0.25);
        path.lineTo(left + w, top + h * 0.75);
        path.lineTo(left + w * 0.5, top + h);
        path.lineTo(left, top + h * 0.75);
        path.lineTo(left, top + h * 0.25);
        path.close();
        break;

      case ImageShape.star:
        final cx = left + w / 2;
        final cy = top + h / 2;
        final outerRadius = w / 2;
        final innerRadius = outerRadius * 0.4;
        const points = 5;

        for (int i = 0; i < points * 2; i++) {
          final radius = i.isEven ? outerRadius : innerRadius;
          final angle = (i * math.pi / points) - math.pi / 2;
          final x = cx + radius * math.cos(angle);
          final y = cy + radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        break;

      case ImageShape.heart:
        path.moveTo(left + w * 0.5, top + h * 0.35);
        path.cubicTo(
          left + w * 0.2,
          top + h * 0.1,
          left - w * 0.1,
          top + h * 0.45,
          left + w * 0.5,
          top + h,
        );
        path.moveTo(left + w * 0.5, top + h * 0.35);
        path.cubicTo(
          left + w * 0.8,
          top + h * 0.1,
          left + w * 1.1,
          top + h * 0.45,
          left + w * 0.5,
          top + h,
        );
        path.close();
        break;

      case ImageShape.diamond:
        path.moveTo(left + w * 0.5, top);
        path.lineTo(left + w, top + h * 0.5);
        path.lineTo(left + w * 0.5, top + h);
        path.lineTo(left, top + h * 0.5);
        path.close();
        break;

      case ImageShape.triangle:
        path.moveTo(left + w / 2, top);
        path.lineTo(left + w, top + h);
        path.lineTo(left, top + h);
        path.close();
        break;
    }

    return path;
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  String _getShapeName(ImageShape shape) {
    switch (shape) {
      case ImageShape.rectangle:
        return LocaleKeys.image_shape_rectangle.tr;
      case ImageShape.roundedRect:
        return LocaleKeys.image_shape_rounded.tr;
      case ImageShape.circle:
        return LocaleKeys.image_shape_circle.tr;
      case ImageShape.hexagon:
        return LocaleKeys.image_shape_hexagon.tr;
      case ImageShape.star:
        return LocaleKeys.image_shape_star.tr;
      case ImageShape.heart:
        return LocaleKeys.image_shape_heart.tr;
      case ImageShape.diamond:
        return LocaleKeys.image_shape_diamond.tr;
      case ImageShape.triangle:
        return LocaleKeys.image_shape_triangle.tr;
    }
  }

  static const List<Color> _borderColors = [
    Colors.white,
    Color(0xFFE0E0E0),
    Color(0xFF9E9E9E),
    Color(0xFF424242),
    Colors.black,
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF1E88E5),
    Color(0xFF00ACC1),
    Color(0xFF43A047),
    Color(0xFFFDD835),
    Color(0xFFFB8C00),
  ];
}

// =============================================================================
// Supporting Types & Widgets
// =============================================================================

enum ImageShape {
  rectangle,
  roundedRect,
  circle,
  hexagon,
  star,
  heart,
  diamond,
  triangle,
}

/// Clean flat source button (gallery / camera)
class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(GroundedTheme.radiusLarge),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            if (isLoading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 28, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shape preview icon for selector chips
class _ShapeIcon extends StatelessWidget {
  const _ShapeIcon({required this.shape, required this.isSelected});

  final ImageShape shape;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : GroundedTheme.textSecondaryDark;
    const size = 24.0;

    switch (shape) {
      case ImageShape.rectangle:
        return Container(
          width: size,
          height: size * 0.75,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case ImageShape.roundedRect:
        return Container(
          width: size,
          height: size * 0.75,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      case ImageShape.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        );
      case ImageShape.hexagon:
      case ImageShape.triangle:
        return CustomPaint(
          size: const Size(size, size),
          painter: _ShapePainter(shape: shape, color: color),
        );
      case ImageShape.star:
        return Icon(Icons.star_border_rounded, size: size, color: color);
      case ImageShape.heart:
        return Icon(Icons.favorite_border_rounded, size: size, color: color);
      case ImageShape.diamond:
        return Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
    }
  }
}

/// Draws the shape outline (stroke) — used for shape selector icons
class _ShapePainter extends CustomPainter {
  _ShapePainter({required this.shape, required this.color});

  final ImageShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    switch (shape) {
      case ImageShape.hexagon:
        final w = size.width;
        final h = size.height;
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.25);
        path.lineTo(w, h * 0.75);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h * 0.75);
        path.lineTo(0, h * 0.25);
        path.close();
        break;
      case ImageShape.triangle:
        path.moveTo(size.width / 2, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.close();
        break;
      default:
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fills the shape path with a solid color — used as border background
/// behind the clipped image in the preview. This ensures borders follow
/// the exact contour of complex shapes (star, heart, hexagon, etc.).
class _ShapeFillPainter extends CustomPainter {
  _ShapeFillPainter({
    required this.shape,
    required this.color,
    this.borderRadius = 12,
  });

  final ImageShape shape;
  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path();
    final w = rect.width;
    final h = rect.height;

    switch (shape) {
      case ImageShape.circle:
        path.addOval(rect);
        break;
      case ImageShape.roundedRect:
        path.addRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));
        break;
      case ImageShape.rectangle:
        path.addRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)));
        break;
      case ImageShape.hexagon:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.25);
        path.lineTo(w, h * 0.75);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h * 0.75);
        path.lineTo(0, h * 0.25);
        path.close();
        break;
      case ImageShape.star:
        final cx = w / 2;
        final cy = h / 2;
        final outerRadius = w / 2;
        final innerRadius = outerRadius * 0.4;
        const points = 5;
        for (int i = 0; i < points * 2; i++) {
          final radius = i.isEven ? outerRadius : innerRadius;
          final angle = (i * math.pi / points) - math.pi / 2;
          final x = cx + radius * math.cos(angle);
          final y = cy + radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        break;
      case ImageShape.heart:
        path.moveTo(w * 0.5, h * 0.35);
        path.cubicTo(w * 0.2, h * 0.1, -w * 0.1, h * 0.45, w * 0.5, h);
        path.moveTo(w * 0.5, h * 0.35);
        path.cubicTo(w * 0.8, h * 0.1, w * 1.1, h * 0.45, w * 0.5, h);
        path.close();
        break;
      case ImageShape.diamond:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.5);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h * 0.5);
        path.close();
        break;
      case ImageShape.triangle:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.close();
        break;
    }

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ShapeFillPainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.borderRadius != borderRadius;
}

// =============================================================================
// Shape Clippers
// =============================================================================

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;
    const points = 5;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.35);
    path.cubicTo(w * 0.2, h * 0.1, -w * 0.1, h * 0.45, w * 0.5, h);
    path.moveTo(w * 0.5, h * 0.35);
    path.cubicTo(w * 0.8, h * 0.1, w * 1.1, h * 0.45, w * 0.5, h);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DiamondClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.5);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// _GlassIconButton removed — using shared GlassIconButton from core/widgets/
