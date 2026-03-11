import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../generated/locales.g.dart';
import 'panel_theme.dart';

/// Color selection tab with quick palette, HSV picker, hex input,
/// recent colors, and opacity slider.
class ColorTab extends StatefulWidget {
  const ColorTab({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
    required this.opacity,
    required this.onOpacityChanged,
  });

  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  final double opacity;
  final ValueChanged<double> onOpacityChanged;

  @override
  State<ColorTab> createState() => _ColorTabState();
}

class _ColorTabState extends State<ColorTab> {
  bool _showHSV = false;

  /// Height of the saturation/value selection square.
  static const _kSVHeight = 120.0;

  // HSV state
  late double _hue;
  late double _saturation;
  late double _value;

  // Hex input
  final _hexController = TextEditingController();
  final _hexFocus = FocusNode();

  // Recent colors (persists across tab switches via static, clamped to 8)
  static final List<Color> _recentColors = [];
  static const int _maxRecent = 8;

  @override
  void initState() {
    super.initState();
    _syncHSV(widget.currentColor);
    _syncHex(widget.currentColor);
  }

  @override
  void didUpdateWidget(ColorTab old) {
    super.didUpdateWidget(old);
    if (!PanelTheme.colorsClose(old.currentColor, widget.currentColor)) {
      _syncHSV(widget.currentColor);
      _syncHex(widget.currentColor);
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  void _syncHSV(Color c) {
    final hsv = HSVColor.fromColor(c.withValues(alpha: 1));
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  void _syncHex(Color c) {
    final hex = c
        .withValues(alpha: 1)
        .value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
    if (_hexController.text != hex) {
      _hexController.text = hex;
    }
  }

  void _pickColor(Color c) {
    HapticFeedback.selectionClick();
    _addRecent(c);
    _syncHSV(c);
    _syncHex(c);
    widget.onColorChanged(c.withValues(alpha: widget.opacity));
    setState(() {});
  }

  void _addRecent(Color c) {
    // Skip if it's a palette preset
    for (final p in _palette) {
      if (PanelTheme.colorsClose(p, c)) return;
    }
    _recentColors.removeWhere((r) => PanelTheme.colorsClose(r, c));
    _recentColors.insert(0, c.withValues(alpha: 1));
    if (_recentColors.length > _maxRecent) _recentColors.removeLast();
  }

  void _onHSVChanged() {
    final c = HSVColor.fromAHSV(1, _hue, _saturation, _value).toColor();
    _syncHex(c);
    _addRecent(c);
    widget.onColorChanged(c.withValues(alpha: widget.opacity));
  }

  void _onHexSubmitted(String hex) {
    hex = hex.replaceAll('#', '').trim();
    if (hex.length == 6) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) {
        final c = Color(0xFF000000 | v);
        _pickColor(c);
      }
    }
    _hexFocus.unfocus();
  }

  void _copyHex() {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: '#${_hexController.text}'));
  }

  // ───── Palette ─────
  static const List<Color> _palette = [
    Colors.white,
    Color(0xFFE0E0E0),
    Color(0xFF9E9E9E),
    Color(0xFF616161),
    Colors.black,
    Color(0xFFE53935), // red
    Color(0xFFFF7043), // deep orange
    Color(0xFFFFA726), // orange
    Color(0xFFFFCA28), // amber
    Color(0xFFFFEE58), // yellow
    Color(0xFF66BB6A), // green
    Color(0xFF26A69A), // teal
    Color(0xFF29B6F6), // light blue
    Color(0xFF42A5F5), // blue
    Color(0xFF5C6BC0), // indigo
    Color(0xFFAB47BC), // purple
    Color(0xFFEC407A), // pink
    Color(0xFF8D6E63), // brown
    Color(0xFF78909C), // blue grey
    Color(0xFF26C6DA), // cyan
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Picker area — palette and custom HSV swap in place
          // (never stacked, so the panel stays compact).
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _showHSV
                  ? _buildCustomView()
                  : _buildPaletteView(),
            ),
          ),
          // Recent colors (shared)
          if (_recentColors.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildRecentColors(),
          ],
          const SizedBox(height: 12),
          // Opacity slider (shared)
          _buildOpacitySlider(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPalette() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _palette.map((c) {
        final sel = PanelTheme.colorsClose(c, widget.currentColor.withValues(alpha: 1));
        return GestureDetector(
          onTap: () => _pickColor(c),
          child: Semantics(
            label: LocaleKeys.text_editor_a11y_color_swatch.tr,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: sel
                    ? Border.all(color: Colors.white, width: 2.5)
                    : Border.all(color: Colors.white24, width: 1),
                boxShadow: sel
                    ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                    : null,
              ),
              child: sel
                  ? Icon(Icons.check, size: 14,
                      color: c.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Palette view: preset color grid with toggle to custom picker.
  Widget _buildPaletteView() {
    return Column(
      key: const ValueKey('palette-view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPalette(),
        const SizedBox(height: 10),
        _buildModeToggle(),
      ],
    );
  }

  /// Custom picker view: HSV square + hue bar with hex input in header.
  Widget _buildCustomView() {
    return Column(
      key: const ValueKey('custom-view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCustomHeader(),
        const SizedBox(height: 10),
        _buildHSVPicker(),
      ],
    );
  }

  /// Header row for custom picker: back toggle (left) + hex input (right).
  Widget _buildCustomHeader() {
    return Row(
      children: [
        _buildModeToggle(),
        const Spacer(),
        const Text('#',
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(width: 4),
        SizedBox(
          width: 84,
          height: 28,
          child: TextField(
            controller: _hexController,
            focusNode: _hexFocus,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, letterSpacing: 1.2),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
            maxLength: 6,
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
            ],
            onSubmitted: _onHexSubmitted,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _copyHex,
          child: Semantics(
            label: LocaleKeys.text_editor_a11y_copy_hex.tr,
            child: const Icon(Icons.copy_rounded,
                size: 16, color: Colors.white54),
          ),
        ),
      ],
    );
  }

  /// Toggle between palette grid and custom HSV picker.
  Widget _buildModeToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        final willOpen = !_showHSV;
        if (willOpen) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
        setState(() => _showHSV = willOpen);
      },
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: LocaleKeys.text_editor_a11y_toggle_picker.tr,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.currentColor.withValues(alpha: 1),
                  border: Border.all(color: Colors.white38, width: 1),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _showHSV ? Icons.apps_rounded : Icons.colorize_rounded,
                size: 16,
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHSVPicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Saturation / Value square
        SizedBox(
          height: _kSVHeight,
          child: LayoutBuilder(builder: (_, box) {
            return GestureDetector(
              onPanDown: (d) =>
                  _updateSV(d.localPosition, box.maxWidth, _kSVHeight),
              onPanUpdate: (d) =>
                  _updateSV(d.localPosition, box.maxWidth, _kSVHeight),
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(box.maxWidth, _kSVHeight),
                  painter: _HSVSquarePainter(hue: _hue),
                  child: Stack(
                    children: [
                    Positioned(
                      left: (_saturation * box.maxWidth) - 8,
                      top: ((1 - _value) * _kSVHeight) - 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: HSVColor.fromAHSV(1, _hue, _saturation, _value)
                              .toColor(),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        // Hue bar
        SizedBox(
          height: 18,
          child: LayoutBuilder(builder: (_, box) {
            return GestureDetector(
              onPanDown: (d) => _updateHue(d.localPosition.dx, box.maxWidth),
              onPanUpdate: (d) =>
                  _updateHue(d.localPosition.dx, box.maxWidth),
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(box.maxWidth, 18),
                  painter: _HueBarPainter(),
                  child: Stack(children: [
                    Positioned(
                      left: (_hue / 360) * box.maxWidth - 5,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _updateSV(Offset pos, double w, double h) {
    setState(() {
      _saturation = (pos.dx / w).clamp(0, 1);
      _value = (1 - pos.dy / h).clamp(0, 1);
    });
    _onHSVChanged();
  }

  void _updateHue(double x, double w) {
    setState(() {
      _hue = ((x / w) * 360).clamp(0, 360);
    });
    _onHSVChanged();
  }

  Widget _buildRecentColors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.text_editor_recent_colors.tr,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentColors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = _recentColors[i];
              final sel = PanelTheme.colorsClose(c, widget.currentColor.withValues(alpha: 1));
              return GestureDetector(
                onTap: () => _pickColor(c),
                child: Semantics(
                  label: LocaleKeys.text_editor_a11y_recent_color.tr,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: Colors.white, width: 2)
                          : Border.all(color: Colors.white12, width: 1),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOpacitySlider() {
    return Row(
      children: [
        Text(
          LocaleKeys.text_editor_opacity.tr,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: PanelTheme.sliderTheme,
            child: Slider(
              value: widget.opacity,
              min: 0,
              max: 1,
              onChanged: (v) {
                widget.onOpacityChanged(v);
              },
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.opacity != 1.0
              ? () {
                  HapticFeedback.selectionClick();
                  widget.onOpacityChanged(1.0);
                }
              : null,
          child: Semantics(
            label: LocaleKeys.text_editor_a11y_reset_opacity.tr,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: (widget.opacity - 1.0).abs() > 0.01
                    ? PanelTheme.accent.withValues(alpha: 0.25)
                    : PanelTheme.surfaceSubtle,
              ),
              child: Text(
                '${(widget.opacity * 100).round()}%',
                style: TextStyle(
                  color: (widget.opacity - 1.0).abs() > 0.01
                      ? PanelTheme.accentLight
                      : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter: HSV saturation/value square.
class _HSVSquarePainter extends CustomPainter {
  _HSVSquarePainter({required this.hue});
  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    // Base hue color
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    final rect = Offset.zero & size;

    // Hue base
    canvas.drawRect(rect, Paint()..color = hueColor);

    // White → transparent horizontal gradient (saturation)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );

    // Transparent → Black vertical gradient (value)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_HSVSquarePainter old) => old.hue != hue;
}

/// Custom painter: Hue spectrum bar.
class _HueBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = List.generate(
        7, (i) => HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor());
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
