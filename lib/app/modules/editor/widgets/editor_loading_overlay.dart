import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

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
    return Stack(
      children: [
        // Dimmed backdrop
        const ModalBarrier(color: Colors.black54),
        // Centered card
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
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
                // Spinning arc indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: AnimatedBuilder(
                    animation: _spinController,
                    builder: (_, _) => CustomPaint(
                      painter: _ArcPainter(_spinController.value),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Message
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
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

    // Active arc — blue
    paint.color = const Color(0xFF42A5F5);
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
