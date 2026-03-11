import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';

/// Premium Instagram-style color picker - Compact and intuitive
class PremiumColorPicker extends StatefulWidget {
  final Color currentColor;
  final void Function(Color) onColorChanged;

  const PremiumColorPicker({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  State<PremiumColorPicker> createState() => _PremiumColorPickerState();
}

class _PremiumColorPickerState extends State<PremiumColorPicker> {
  late Color _selectedColor;
  late double _hue;
  late double _saturation;
  late double _brightness;
  bool _showAdvanced = false;
  
  // Popular colors organized by category - more intuitive than random presets
  static const List<Color> _basicColors = [
    Colors.white,
    Color(0xFFE0E0E0),
    Color(0xFF9E9E9E),
    Color(0xFF424242),
    Colors.black,
  ];
  
  static const List<Color> _vibrantColors = [
    Color(0xFFFF1744), // Red
    Color(0xFFFF9100), // Orange
    Color(0xFFFFEA00), // Yellow
    Color(0xFF00E676), // Green
    Color(0xFF00B0FF), // Blue
    Color(0xFFD500F9), // Purple
    Color(0xFFFF4081), // Pink
  ];
  
  static const List<Color> _pastelColors = [
    Color(0xFFFFCDD2), // Light Red
    Color(0xFFFFE0B2), // Light Orange
    Color(0xFFFFF9C4), // Light Yellow
    Color(0xFFC8E6C9), // Light Green
    Color(0xFFB3E5FC), // Light Blue
    Color(0xFFE1BEE7), // Light Purple
    Color(0xFFF8BBD9), // Light Pink
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
    final hsv = HSVColor.fromColor(_selectedColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _brightness = hsv.value;
  }

  void _updateColor() {
    _selectedColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _brightness).toColor();
    widget.onColorChanged(_selectedColor);
    setState(() {});
  }
  
  void _selectPreset(Color color) {
    _selectedColor = color;
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _brightness = hsv.value;
    widget.onColorChanged(color);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GroundedTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Color preview + Advanced toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Selected color preview
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Hex value
                  Expanded(
                    child: Text(
                      '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Advanced toggle
                  GestureDetector(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showAdvanced ? GroundedTheme.primary : Colors.white12,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune,
                            size: 14,
                            color: _showAdvanced ? Colors.white : Colors.white60,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            LocaleKeys.common_custom.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: _showAdvanced ? Colors.white : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Basic colors (B&W)
            _buildColorRow(_basicColors),
            const SizedBox(height: 8),
            
            // Vibrant colors
            _buildColorRow(_vibrantColors),
            const SizedBox(height: 8),
            
            // Pastel colors
            _buildColorRow(_pastelColors),
            
            // Advanced sliders (collapsible)
            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildCompactSlider(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                      ),
                      value: _hue,
                      max: 360,
                      onChanged: (v) {
                        _hue = v;
                        _updateColor();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildCompactSlider(
                      gradient: LinearGradient(
                        colors: [
                          HSVColor.fromAHSV(1.0, _hue, 0.0, _brightness).toColor(),
                          HSVColor.fromAHSV(1.0, _hue, 1.0, _brightness).toColor(),
                        ],
                      ),
                      value: _saturation,
                      max: 1,
                      onChanged: (v) {
                        _saturation = v;
                        _updateColor();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildCompactSlider(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black,
                          HSVColor.fromAHSV(1.0, _hue, _saturation, 1.0).toColor(),
                        ],
                      ),
                      value: _brightness,
                      max: 1,
                      onChanged: (v) {
                        _brightness = v;
                        _updateColor();
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorRow(List<Color> colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: colors.map((color) {
          final isSelected = _selectedColor.toARGB32() == color.toARGB32();
          return GestureDetector(
            onTap: () => _selectPreset(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isSelected ? 38 : 34,
              height: isSelected ? 38 : 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ] : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildCompactSlider({
    required Gradient gradient,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: gradient,
      ),
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 28,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 12,
            elevation: 3,
          ),
          thumbColor: Colors.white,
          overlayShape: SliderComponentShape.noOverlay,
          trackShape: const RoundedRectSliderTrackShape(),
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
        ),
        child: Slider(
          value: value,
          min: 0,
          max: max,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
