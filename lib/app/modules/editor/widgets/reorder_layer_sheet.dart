import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';

/// A bottom sheet widget for reordering layers via drag-and-drop.
///
/// Users can drag layers to change their stacking order.
/// The list shows layers from bottom to top (first item = back layer).
class ReorderLayerSheet extends StatefulWidget {
  const ReorderLayerSheet({
    super.key,
    required this.layers,
    required this.onReorder,
    this.onDuplicate,
    this.scrollController,
  });

  /// List of layers to display and reorder
  final List<Layer> layers;

  /// Callback when layers are reordered
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Callback when a layer is duplicated
  final void Function(int index)? onDuplicate;

  /// Scroll controller from DraggableScrollableSheet for coordinated scrolling
  final ScrollController? scrollController;

  @override
  State<ReorderLayerSheet> createState() => _ReorderLayerSheetState();
}

class _ReorderLayerSheetState extends State<ReorderLayerSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GroundedTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Frosted-glass header
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Icon with subtle glow
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: GroundedTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.layers_rounded,
                    color: GroundedTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  LocaleKeys.layer_reorder.tr,
                  style: GroundedTheme.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Count pill badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Text(
                    widget.layers.length == 1
                        ? LocaleKeys.layer_count_one.tr
                        : LocaleKeys.layer_count_other.trParams(
                            {'count': '${widget.layers.length}'}),
                    style: GroundedTheme.labelSmall.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Layer list
          Flexible(
            child: widget.layers.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    scrollController: widget.scrollController,
                    shrinkWrap: widget.scrollController == null,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 10),
                    dragStartBehavior: DragStartBehavior.down,
                    proxyDecorator: _proxyDecorator,
                    itemCount: widget.layers.length,
                    itemBuilder: (context, index) {
                      final layer = widget.layers[index];
                      return _buildLayerTile(layer, index);
                    },
                    onReorder: (oldIndex, newIndex) {
                      HapticFeedback.mediumImpact();
                      widget.onReorder(oldIndex, newIndex);
                      setState(() {});
                    },
                  ),
          ),
          // Footer hint
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGripDots(3, 2, 3, Colors.white24),
                const SizedBox(width: 8),
                Text(
                  LocaleKeys.layer_drag_hint.tr,
                  style: GroundedTheme.labelSmall.copyWith(
                    color: Colors.white30,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.layers_clear,
                color: Colors.white.withValues(alpha: 0.16), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.layer_empty.tr,
            style: GroundedTheme.bodyMedium.copyWith(color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLayerTile(Layer layer, int index) {
    final isFirst = index == 0;
    final isLast = index == widget.layers.length - 1;
    final isEndpoint = isFirst || isLast;

    return Semantics(
      label:
          '${_getLayerTitle(layer)}, ${_getLayerTypeLabel(layer)}',
      key: ValueKey(layer.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          // Gradient accent for front/back layers
          gradient: isEndpoint
              ? LinearGradient(
                  begin: AlignmentDirectional.centerEnd,
                  end: AlignmentDirectional.centerStart,
                  colors: [
                    GroundedTheme.primary.withValues(alpha: 0.08),
                    GroundedTheme.cardDark,
                  ],
                )
              : null,
          color: isEndpoint ? null : GroundedTheme.cardDark,
          border: Border.all(
            color: isEndpoint
                ? GroundedTheme.primary.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Layer preview thumbnail
              _buildLayerPreview(layer),
              const SizedBox(width: 12),
              // Title & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getLayerTitle(layer),
                      style: GroundedTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _buildSubtitleRow(layer, isFirst, isLast),
                  ],
                ),
              ),
              // Actions
              if (widget.onDuplicate != null) ...[
                _buildActionButton(
                  icon: Icons.copy_rounded,
                  color: GroundedTheme.primary,
                  tooltip: LocaleKeys.layer_duplicate.tr,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onDuplicate!(index);
                  },
                ),
                const SizedBox(width: 2),
              ],
              // Drag handle — large touch target
              Semantics(
                label: LocaleKeys.layer_drag_hint.tr,
                child: ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    width: 44,
                    height: 56,
                    alignment: Alignment.center,
                    color: Colors.transparent, // ensures full area is hittable
                    child: _buildGripDots(4, 2, 4.5, Colors.white38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Subtitle row with colored type badge and optional position tag.
  Widget _buildSubtitleRow(Layer layer, bool isFirst, bool isLast) {
    final type = _getLayerTypeLabel(layer);
    final position = isLast
        ? LocaleKeys.layer_position_front.tr
        : (isFirst ? LocaleKeys.layer_position_back.tr : null);

    return Row(
      children: [
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: _getLayerAccentColor(layer).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            type,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _getLayerAccentColor(layer),
              height: 1.3,
            ),
          ),
        ),
        // Position indicator
        if (position != null) ...[
          const SizedBox(width: 6),
          Text(
            position,
            style: TextStyle(
              fontSize: 10,
              color: GroundedTheme.primary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Small icon button for actions (e.g. duplicate).
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
          ),
        ),
      ),
    );
  }

  /// A small grid of dots used as a drag handle / hint.
  Widget _buildGripDots(int rows, int cols, double dotSpacing, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        rows,
        (r) => Padding(
          padding: EdgeInsets.only(bottom: r < rows - 1 ? dotSpacing : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              cols,
              (c) => Padding(
                padding: EdgeInsets.only(right: c < cols - 1 ? dotSpacing : 0),
                child: Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerPreview(Layer layer) {
    Widget preview;
    Color bgColor = GroundedTheme.primary.withValues(alpha: 0.15);
    const double thumbSize = 40;

    if (layer is TextLayer) {
      preview = Text(
        'Aa',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: GroundedTheme.primary,
        ),
      );
    } else if (layer is EmojiLayer) {
      preview = Text(
        layer.emoji,
        style: const TextStyle(fontSize: 26),
      );
      bgColor = Colors.white.withValues(alpha: 0.06);
    } else if (layer is PaintLayer) {
      final isCensor = layer.item.mode == PaintMode.pixelate ||
          layer.item.mode == PaintMode.blur;
      preview = Icon(
        isCensor ? Icons.blur_circular : Icons.brush_rounded,
        color: isCensor ? Colors.purple : layer.item.color,
        size: 22,
      );
      bgColor = isCensor
          ? Colors.purple.withValues(alpha: 0.15)
          : layer.item.color.withValues(alpha: 0.15);
    } else if (layer is WidgetLayer) {
      final layerType = _getWidgetLayerType(layer);
      switch (layerType) {
        case _WidgetLayerType.galleryImage:
          final fileUrl = layer.exportConfigs.fileUrl;
          if (fileUrl != null && File(fileUrl).existsSync()) {
            preview = ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(fileUrl),
                width: thumbSize,
                height: thumbSize,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_rounded,
                  color: Colors.green,
                  size: 22,
                ),
              ),
            );
          } else {
            preview =
                const Icon(Icons.image_rounded, color: Colors.green, size: 22);
          }
          bgColor = Colors.green.withValues(alpha: 0.15);
        case _WidgetLayerType.imageLayer:
          final fileUrl = layer.exportConfigs.fileUrl;
          final shapeName = layer.meta?['shape'] as String?;
          final shapeIcon = _getShapeIcon(shapeName);
          if (fileUrl != null && File(fileUrl).existsSync()) {
            preview = Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(fileUrl),
                    width: thumbSize,
                    height: thumbSize,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      shapeIcon,
                      color: Colors.deepPurple,
                      size: 22,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: GroundedTheme.cardDark,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(shapeIcon, color: Colors.white, size: 10),
                  ),
                ),
              ],
            );
          } else {
            preview = Icon(shapeIcon, color: Colors.deepPurple, size: 22);
          }
          bgColor = Colors.deepPurple.withValues(alpha: 0.15);
        case _WidgetLayerType.sticker:
          final stickerInfo = _getStickerIconInfo(layer);
          if (stickerInfo != null) {
            preview = Icon(stickerInfo.$1, color: stickerInfo.$2, size: 26);
            bgColor = stickerInfo.$2.withValues(alpha: 0.15);
          } else {
            preview = const Icon(
              Icons.auto_awesome,
              color: Colors.orange,
              size: 22,
            );
            bgColor = Colors.orange.withValues(alpha: 0.15);
          }
        case _WidgetLayerType.unknown:
          preview = const Icon(Icons.widgets, color: Colors.orange, size: 22);
          bgColor = Colors.orange.withValues(alpha: 0.15);
      }
    } else {
      preview = const Icon(Icons.layers, color: Colors.white54, size: 22);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Center(child: preview),
    );
  }

  String _getLayerTitle(Layer layer) {
    if (layer is TextLayer) {
      return layer.text.length > 20
          ? '${layer.text.substring(0, 20)}...'
          : layer.text;
    } else if (layer is EmojiLayer) {
      return '${LocaleKeys.layer_type_emoji.tr} ${layer.emoji}';
    } else if (layer is PaintLayer) {
      final mode = layer.item.mode;
      if (mode == PaintMode.pixelate) return LocaleKeys.layer_type_pixelate.tr;
      if (mode == PaintMode.blur) return LocaleKeys.layer_type_blur.tr;
      if (mode == PaintMode.arrow) return LocaleKeys.layer_type_arrow.tr;
      if (mode == PaintMode.line) return LocaleKeys.layer_type_line.tr;
      if (mode == PaintMode.dashLine) {
        return LocaleKeys.layer_type_dash_line.tr;
      }
      if (mode == PaintMode.rect) return LocaleKeys.layer_type_rectangle.tr;
      if (mode == PaintMode.circle) return LocaleKeys.layer_type_circle.tr;
      return LocaleKeys.layer_type_drawing.tr;
    } else if (layer is WidgetLayer) {
      final layerType = _getWidgetLayerType(layer);
      switch (layerType) {
        case _WidgetLayerType.galleryImage:
          return LocaleKeys.layer_type_gallery_image.tr;
        case _WidgetLayerType.imageLayer:
          final shapeName = layer.meta?['shape'] as String?;
          final shapeLabel = _getShapeLabel(shapeName);
          return shapeLabel != null
              ? '${LocaleKeys.layer_type_image_layer.tr} • $shapeLabel'
              : LocaleKeys.layer_type_image_layer.tr;
        case _WidgetLayerType.sticker:
          return LocaleKeys.layer_type_sticker.tr;
        case _WidgetLayerType.unknown:
          return LocaleKeys.layer_type_sticker.tr;
      }
    }
    return LocaleKeys.layer_type_layer.tr;
  }

  /// Short type label used in the colored badge.
  String _getLayerTypeLabel(Layer layer) {
    if (layer is TextLayer) return LocaleKeys.layer_type_text.tr;
    if (layer is EmojiLayer) return LocaleKeys.layer_type_emoji.tr;
    if (layer is PaintLayer) return LocaleKeys.layer_type_paint.tr;
    if (layer is WidgetLayer) {
      final layerType = _getWidgetLayerType(layer);
      return switch (layerType) {
        _WidgetLayerType.galleryImage => LocaleKeys.layer_type_image.tr,
        _WidgetLayerType.imageLayer =>
          _getShapeLabel(layer.meta?['shape'] as String?) ??
              LocaleKeys.layer_type_image.tr,
        _WidgetLayerType.sticker => LocaleKeys.layer_type_sticker.tr,
        _WidgetLayerType.unknown => LocaleKeys.layer_type_widget.tr,
      };
    }
    return LocaleKeys.layer_type_layer.tr;
  }

  /// Accent color per layer type, used for badge tinting.
  Color _getLayerAccentColor(Layer layer) {
    if (layer is TextLayer) return GroundedTheme.primary;
    if (layer is EmojiLayer) return Colors.amber;
    if (layer is PaintLayer) {
      final isCensor = layer.item.mode == PaintMode.pixelate ||
          layer.item.mode == PaintMode.blur;
      return isCensor ? Colors.purple : layer.item.color;
    }
    if (layer is WidgetLayer) {
      final layerType = _getWidgetLayerType(layer);
      return switch (layerType) {
        _WidgetLayerType.galleryImage => Colors.green,
        _WidgetLayerType.imageLayer => Colors.deepPurple,
        _WidgetLayerType.sticker =>
          _getStickerIconInfo(layer)?.$2 ?? Colors.orange,
        _WidgetLayerType.unknown => Colors.orange,
      };
    }
    return Colors.white54;
  }

  /// Determine the sub-type of a WidgetLayer using meta tags,
  /// with heuristic fallback for layers created before tagging.
  _WidgetLayerType _getWidgetLayerType(WidgetLayer layer) {
    // Prefer explicit meta tag
    final meta = layer.meta;
    if (meta != null && meta.containsKey('layerType')) {
      switch (meta['layerType']) {
        case 'gallery_image':
          return _WidgetLayerType.galleryImage;
        case 'image_layer':
          return _WidgetLayerType.imageLayer;
        case 'sticker':
          return _WidgetLayerType.sticker;
      }
    }

    // Heuristic fallback for older layers without meta
    final exportConfigs = layer.exportConfigs;
    if (exportConfigs.id?.startsWith('icon_') == true) {
      return _WidgetLayerType.sticker;
    }
    if (exportConfigs.fileUrl != null) {
      if (exportConfigs.fileUrl!.contains('/image_layers/')) {
        return _WidgetLayerType.imageLayer;
      }
      if (exportConfigs.fileUrl!.contains('/stickers/')) {
        return _WidgetLayerType.galleryImage;
      }
      // Generic file-based layer — treat as image
      return _WidgetLayerType.galleryImage;
    }

    return _WidgetLayerType.unknown;
  }

  /// Get the appropriate icon for a shape name.
  IconData _getShapeIcon(String? shapeName) {
    return switch (shapeName) {
      'circle' => Icons.circle_outlined,
      'rectangle' => Icons.crop_square_rounded,
      'roundedRect' => Icons.rounded_corner,
      'hexagon' => Icons.hexagon_outlined,
      'star' => Icons.star_outline_rounded,
      'heart' => Icons.favorite_outline_rounded,
      'diamond' => Icons.diamond_outlined,
      'triangle' => Icons.change_history_rounded,
      _ => Icons.photo_library,
    };
  }

  /// Get the localized label for a shape name.
  String? _getShapeLabel(String? shapeName) {
    return switch (shapeName) {
      'circle' => LocaleKeys.layer_shape_circle.tr,
      'rectangle' => LocaleKeys.layer_shape_rectangle.tr,
      'roundedRect' => LocaleKeys.layer_shape_roundedRect.tr,
      'hexagon' => LocaleKeys.layer_shape_hexagon.tr,
      'star' => LocaleKeys.layer_shape_star.tr,
      'heart' => LocaleKeys.layer_shape_heart.tr,
      'diamond' => LocaleKeys.layer_shape_diamond.tr,
      'triangle' => LocaleKeys.layer_shape_triangle.tr,
      _ => null,
    };
  }

  /// Extract the icon and color from a sticker WidgetLayer.
  /// Uses meta data first, falls back to parsing exportConfigs.id.
  (IconData, Color)? _getStickerIconInfo(WidgetLayer layer) {
    int? codePoint;
    int? colorValue;

    // Try meta first
    final meta = layer.meta;
    if (meta != null) {
      codePoint = meta['iconCodePoint'] as int?;
      colorValue = meta['iconColor'] as int?;
    }

    // Fallback: parse from exportConfigs.id (format: icon_{codePoint}_{colorARGB32})
    if (codePoint == null || colorValue == null) {
      final id = layer.exportConfigs.id;
      if (id != null && id.startsWith('icon_')) {
        final parts = id.split('_');
        if (parts.length >= 3) {
          codePoint ??= int.tryParse(parts[1]);
          colorValue ??= int.tryParse(parts[2]);
        }
      }
    }

    if (codePoint != null && colorValue != null) {
      return (
        IconData(codePoint, fontFamily: 'MaterialIcons'),
        Color(colorValue),
      );
    }
    return null;
  }

  /// Decoration for the item being dragged
  Widget _proxyDecorator(
      Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animValue = Curves.easeInOut.transform(animation.value);
        final elevation = lerpDouble(0, 8, animValue)!;
        final scale = lerpDouble(1, 1.02, animValue)!;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GroundedTheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: GroundedTheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Sub-types for WidgetLayer identification in the reorder sheet.
enum _WidgetLayerType {
  sticker,
  galleryImage,
  imageLayer,
  unknown,
}
