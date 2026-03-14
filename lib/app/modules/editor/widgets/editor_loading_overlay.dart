import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/theme/grounded_theme.dart';

/// A premium dark loading overlay that replaces the default
/// [GroundedLoadingDialog]. Fades in smoothly and shows a centered card with a
/// rotating arc indicator and the localised loading message.
class EditorLoadingOverlay extends StatefulWidget {
  const EditorLoadingOverlay({
    super.key,
    required this.message,
    required this.configs,
  });

  final String message;
  final ProImageEditorConfigs configs;

  @override
  State<EditorLoadingOverlay> createState() => _EditorLoadingOverlayState();
}

class _EditorLoadingOverlayState extends State<EditorLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: widget.message,
      child: Stack(
        children: [
          // Dimmed backdrop
          const ModalBarrier(color: Colors.black54),
          // Centered card
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 240),
              padding: const EdgeInsets.symmetric(
                vertical: GroundedTheme.spacing32,
                horizontal: GroundedTheme.spacing24,
              ),
              decoration: BoxDecoration(
                color: GroundedTheme.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(GroundedTheme.radiusXLarge),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Spinning arc indicator — RepaintBoundary isolates repaints
                  RepaintBoundary(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: AnimatedBuilder(
                        animation: _spinController,
                        builder: (_, _) => CustomPaint(
                          painter: _ArcPainter(_spinController.value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: GroundedTheme.spacing20),
                  // Message
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: GroundedTheme.fontSizeM,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Track ring
    paint.color = Colors.white.withValues(alpha: 0.08);
    canvas.drawOval(Offset.zero & size, paint);

    // Active arc — primary blue
    paint.color = GroundedTheme.primary;
    final startAngle = progress * 2 * math.pi;
    canvas.drawArc(
      Offset.zero & size,
      startAngle,
      math.pi * 0.75,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
