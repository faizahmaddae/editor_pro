import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';

/// Shadow configuration for text
class TextShadowConfig {
  final bool enabled;
  final Color color;
  final double blurRadius;
  final Offset offset;
  
  const TextShadowConfig({
    this.enabled = false,
    this.color = Colors.black,
    this.blurRadius = 4.0,
    this.offset = const Offset(2, 2),
  });
  
  TextShadowConfig copyWith({
    bool? enabled,
    Color? color,
    double? blurRadius,
    Offset? offset,
  }) {
    return TextShadowConfig(
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
      blurRadius: blurRadius ?? this.blurRadius,
      offset: offset ?? this.offset,
    );
  }
  
  /// Convert to Flutter Shadow for TextStyle
  Shadow? toShadow() {
    if (!enabled) return null;
    return Shadow(
      color: color.withValues(alpha: 0.7),
      blurRadius: blurRadius,
      offset: offset,
    );
  }
  
  /// Get list of shadows for TextStyle (returns empty if disabled)
  List<Shadow> toShadowList() {
    if (!enabled) return [];
    return [toShadow()!];
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextShadowConfig &&
        other.enabled == enabled &&
        other.color == color &&
        other.blurRadius == blurRadius &&
        other.offset == offset;
  }
  
  @override
  int get hashCode => Object.hash(enabled, color, blurRadius, offset);
}

/// Panel for adjusting text shadow settings
class TextShadowPanel extends StatefulWidget {
  const TextShadowPanel({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
    required this.onClose,
    required this.onColorPickerTap,
  });
  
  final TextShadowConfig initialConfig;
  final ValueChanged<TextShadowConfig> onConfigChanged;
  final VoidCallback onClose;
  final VoidCallback onColorPickerTap;
  
  @override
  State<TextShadowPanel> createState() => _TextShadowPanelState();
}

class _TextShadowPanelState extends State<TextShadowPanel> {
  late TextShadowConfig _config;
  
  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }
  
  @override
  void didUpdateWidget(TextShadowPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with parent's config when it changes (e.g., color picker updates)
    if (widget.initialConfig != oldWidget.initialConfig) {
      _config = widget.initialConfig;
    }
  }
  
  void _updateConfig(TextShadowConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onConfigChanged(newConfig);
  }
  
  @override
  Widget build(BuildContext context) {
    // Use Focus with skipTraversal to prevent focus from going to text field
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: GroundedTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact header row with toggle and color
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shadow toggle (also closes panel when tapped)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_config.enabled) {
                      // If enabled, toggle off and close
                      _updateConfig(_config.copyWith(enabled: false));
                      widget.onClose();
                    } else {
                      // If disabled, just enable
                      _updateConfig(_config.copyWith(enabled: true));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _config.enabled ? GroundedTheme.primary : Colors.white12,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _config.enabled ? Icons.check : Icons.blur_on_rounded,
                          size: 16,
                          color: _config.enabled ? Colors.white : Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          LocaleKeys.text_editor_tab_shadow.tr,
                          style: TextStyle(
                            color: _config.enabled ? Colors.white : Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: _config.enabled ? Colors.white70 : Colors.white38,
                        ),
                      ],
                    ),
                  ),
                ),
                // Color picker (only when enabled)
                if (_config.enabled)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onColorPickerTap,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _config.color,
                        border: Border.all(color: Colors.white38, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          
          // Sliders (only when enabled) - compact inline layout
          if (_config.enabled) ...[
            const SizedBox(height: 12),
            // Blur slider
            _buildCompactSlider(
              icon: Icons.blur_circular,
              value: _config.blurRadius,
              min: 0,
              max: 20,
              onChanged: (v) => _updateConfig(_config.copyWith(blurRadius: v)),
            ),
            const SizedBox(height: 8),
            // Offset sliders in a row
            Row(
              children: [
                Expanded(
                  child: _buildCompactSlider(
                    label: 'X',
                    value: _config.offset.dx,
                    min: -15,
                    max: 15,
                    onChanged: (v) => _updateConfig(_config.copyWith(
                      offset: Offset(v, _config.offset.dy),
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactSlider(
                    label: 'Y',
                    value: _config.offset.dy,
                    min: -15,
                    max: 15,
                    onChanged: (v) => _updateConfig(_config.copyWith(
                      offset: Offset(_config.offset.dx, v),
                    )),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }
  
  Widget _buildCompactSlider({
    IconData? icon,
    String? label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        if (icon != null)
          Icon(icon, size: 16, color: Colors.white38),
        if (label != null)
          SizedBox(
            width: 16,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: GroundedTheme.primary,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: GroundedTheme.primary.withValues(alpha: 0.15),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
          width: 32,
          child: Text(
            value.toStringAsFixed(0),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
