import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../generated/locales.g.dart';
import 'panel_theme.dart';
import 'shadow_value.dart';

/// Named preset with a localised label and a pre-configured shadow.
class _ShadowPreset {
  final String label;
  final ShadowValue value;
  const _ShadowPreset({required this.label, required this.value});
}

/// Shadow tab with toggle, quick presets, 2D offset pad,
/// blur slider, and shadow color picker.
class ShadowTab extends StatefulWidget {
  const ShadowTab({
    super.key,
    required this.shadow,
    required this.onShadowChanged,
  });

  final ShadowValue shadow;
  final ValueChanged<ShadowValue> onShadowChanged;

  @override
  State<ShadowTab> createState() => _ShadowTabState();
}

class _ShadowTabState extends State<ShadowTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.shadow.enabled ? 1.0 : 0.0,
    );
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(ShadowTab old) {
    super.didUpdateWidget(old);
    if (widget.shadow.enabled != old.shadow.enabled) {
      widget.shadow.enabled ? _expandCtrl.forward() : _expandCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  void _emit(ShadowValue v) => widget.onShadowChanged(v);

  // ── Preset definitions (getter so .tr resolves at runtime) ──

  List<_ShadowPreset> get _presets => [
        _ShadowPreset(
          label: LocaleKeys.text_editor_shadow_drop.tr,
          value: const ShadowValue(
              enabled: true, color: Colors.black, blur: 4, dx: 2, dy: 2),
        ),
        _ShadowPreset(
          label: LocaleKeys.text_editor_shadow_glow.tr,
          value: const ShadowValue(
              enabled: true, color: Color(0xFF42A5F5), blur: 12, dx: 0, dy: 0),
        ),
        _ShadowPreset(
          label: LocaleKeys.text_editor_shadow_neon.tr,
          value: const ShadowValue(
              enabled: true, color: Color(0xFF00E676), blur: 20, dx: 0, dy: 0),
        ),
        _ShadowPreset(
          label: LocaleKeys.text_editor_shadow_hard.tr,
          value: const ShadowValue(
              enabled: true, color: Colors.black, blur: 0, dx: 3, dy: 3),
        ),
        _ShadowPreset(
          label: LocaleKeys.text_editor_shadow_soft.tr,
          value: const ShadowValue(
              enabled: true,
              color: Color(0x80000000),
              blur: 10,
              dx: 0,
              dy: 4),
        ),
      ];

  // ── Shadow color presets ──

  static const List<Color> _colorPresets = [
    Colors.black,
    Color(0xFF1A237E), // dark blue
    Color(0xFF6A1B9A), // purple
    Color(0xFF1565C0), // blue
    Color(0xFFD32F2F), // red
    Color(0xFFFDD835), // yellow
    Colors.white,
    Color(0xFF00897B), // teal
  ];

  @override
  Widget build(BuildContext context) {
    final shadow = widget.shadow;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Toggle row with live preview
          _buildToggleRow(shadow),
          // Expandable content — compute presets once per build
          SizeTransition(
            sizeFactor: _expandAnim,
            child: FadeTransition(
              opacity: _expandAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  // Quick presets (list built once per frame)
                  _buildPresets(shadow, _presets),
                  const SizedBox(height: 14),
                  // 2D offset pad + blur slider side by side
                  _buildOffsetAndBlur(shadow),
                  const SizedBox(height: 14),
                  // Shadow color
                  _buildColorRow(shadow),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Toggle row ──

  Widget _buildToggleRow(ShadowValue shadow) {
    return Row(
      children: [
        // Live "Aa" preview
        Container(
          width: 40,
          height: 36,
          alignment: Alignment.center,
          child: Text(
            'Aa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              shadows: shadow.toShadows(),
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _emit(shadow.copyWith(enabled: !shadow.enabled));
          },
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            label: shadow.enabled
                ? LocaleKeys.text_editor_shadow_on.tr
                : LocaleKeys.text_editor_shadow_off.tr,
            toggled: shadow.enabled,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: shadow.enabled
                    ? PanelTheme.accent
                    : PanelTheme.surfaceSubtle,
              ),
              child: Text(
                shadow.enabled
                    ? LocaleKeys.text_editor_shadow_on.tr
                    : LocaleKeys.text_editor_shadow_off.tr,
                style: TextStyle(
                  color: shadow.enabled ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Quick presets ──

  Widget _buildPresets(ShadowValue shadow, List<_ShadowPreset> presets) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = presets[i];
          final active = _isPresetActive(p, shadow);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _emit(p.value.copyWith(color: shadow.color));
            },
            child: Semantics(
              label: LocaleKeys.text_editor_a11y_shadow_preset.trArgs([p.label]),
              selected: active,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: PanelTheme.surfaceFaint,
                  border: Border.all(
                    color: active
                        ? PanelTheme.accent
                        : Colors.white.withValues(alpha: 0.1),
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Aa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: p.value.toShadows(),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.label,
                      style: TextStyle(
                        color: active ? Colors.white70 : Colors.white38,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isPresetActive(_ShadowPreset preset, ShadowValue current) {
    // Not the preset if shadow is disabled
    if (!current.enabled) return false;
    final p = preset.value;
    return (p.blur - current.blur).abs() < 0.5 &&
        (p.dx - current.dx).abs() < 0.5 &&
        (p.dy - current.dy).abs() < 0.5;
  }

  // ── 2D offset pad + blur ──

  Widget _buildOffsetAndBlur(ShadowValue shadow) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2D offset pad
        _OffsetPad(
          dx: shadow.dx,
          dy: shadow.dy,
          onChanged: (dx, dy) => _emit(shadow.copyWith(dx: dx, dy: dy)),
          onReset: () => _emit(shadow.copyWith(dx: 0, dy: 0)),
        ),
        const SizedBox(width: 16),
        // Blur controls
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.text_editor_shadow_blur.tr,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const SizedBox(height: 6),
              SliderTheme(
                data: PanelTheme.sliderTheme,
                child: Slider(
                  value: shadow.blur,
                  min: 0,
                  max: 20,
                  onChanged: (v) => _emit(shadow.copyWith(blur: v)),
                ),
              ),
              // Quick-pick blur chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0.0, 4.0, 10.0, 20.0].map((v) {
                  final active = (shadow.blur - v).abs() < 0.5;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _emit(shadow.copyWith(blur: v));
                    },
                    child: Semantics(
                      label: LocaleKeys.text_editor_a11y_blur_value
                          .trArgs(['${v.toInt()}']),
                      selected: active,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: active
                              ? PanelTheme.accent.withValues(alpha: 0.3)
                              : PanelTheme.surfaceFaint,
                        ),
                        child: Text(
                          '${v.toInt()}',
                          style: TextStyle(
                            color:
                                active ? Colors.white : Colors.white38,
                            fontSize: 11,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shadow color row ──

  Widget _buildColorRow(ShadowValue shadow) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _colorPresets.map((c) {
        final selected = PanelTheme.colorsClose(c, shadow.color);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _emit(shadow.copyWith(color: c));
          },
          child: Semantics(
            label: LocaleKeys.text_editor_a11y_shadow_color.tr,
            selected: selected,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c,
                border: Border.all(
                  color: selected ? Colors.white : Colors.white24,
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                    : null,
              ),
              child: selected
                  ? Icon(Icons.check,
                      size: 14,
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
}

// ── 2D Offset Pad ──

class _OffsetPad extends StatelessWidget {
  const _OffsetPad({
    required this.dx,
    required this.dy,
    required this.onChanged,
    required this.onReset,
  });

  final double dx;
  final double dy;
  final void Function(double dx, double dy) onChanged;
  final VoidCallback onReset;

  static const double _size = 110;
  static const double _range = 15;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanDown: (d) => _update(d.localPosition),
          onPanUpdate: (d) => _update(d.localPosition),
          child: Semantics(
            label: LocaleKeys.text_editor_a11y_offset_pad.tr,
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size(_size, _size),
                painter: _OffsetPadPainter(dx: dx, dy: dy, range: _range),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Coordinates + reset
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${dx.toStringAsFixed(1)}, ${dy.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
            const SizedBox(width: 6),
            if (dx.abs() > 0.1 || dy.abs() > 0.1)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onReset();
                },
                child: Semantics(
                  label: LocaleKeys.text_editor_a11y_reset_offset.tr,
                  child: const Icon(Icons.restart_alt_rounded,
                      size: 14, color: PanelTheme.accentLight),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _update(Offset pos) {
    final rawDx = ((pos.dx / _size) * 2 - 1) * _range;
    final rawDy = ((pos.dy / _size) * 2 - 1) * _range;
    onChanged(
      PanelTheme.snap(rawDx.clamp(-_range, _range), 0.5),
      PanelTheme.snap(rawDy.clamp(-_range, _range), 0.5),
    );
  }
}

class _OffsetPadPainter extends CustomPainter {
  _OffsetPadPainter({
    required this.dx,
    required this.dy,
    required this.range,
  });

  final double dx;
  final double dy;
  final double range;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final linePaint = Paint()
      ..color = const Color(0x20FFFFFF)
      ..strokeWidth = 0.5;

    // Grid lines
    const divisions = 6;
    for (var i = 0; i <= divisions; i++) {
      final t = i / divisions;
      // Vertical
      canvas.drawLine(
        Offset(t * size.width, 0),
        Offset(t * size.width, size.height),
        linePaint,
      );
      // Horizontal
      canvas.drawLine(
        Offset(0, t * size.height),
        Offset(size.width, t * size.height),
        linePaint,
      );
    }

    // Crosshairs
    final crossPaint = Paint()
      ..color = const Color(0x40FFFFFF)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);
    canvas.drawLine(
        Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);

    // Thumb
    final tx = center.dx + (dx / range) * (size.width / 2);
    final ty = center.dy + (dy / range) * (size.height / 2);
    final thumbPos = Offset(tx.clamp(0, size.width), ty.clamp(0, size.height));

    // Thumb shadow
    canvas.drawCircle(
      thumbPos,
      7,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Thumb fill
    canvas.drawCircle(thumbPos, 6, Paint()..color = Colors.white);
    // Thumb border
    canvas.drawCircle(
      thumbPos,
      6,
      Paint()
        ..color = PanelTheme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_OffsetPadPainter old) =>
      old.dx != dx || old.dy != dy;
}
