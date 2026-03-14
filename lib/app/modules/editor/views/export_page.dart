import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';
import '../../../data/services/export_service.dart';

/// Creative export page - Celebrate the user's creation!
/// Immersive design with floating actions and premium feel
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> with TickerProviderStateMixin {
  late final Uint8List imageBytes;
  late final MemoryImage _imageProvider;
  late final VoidCallback? onSaveComplete;
  late final Future<void> Function()? onSaveToRecentProjects;

  // State
  ExportState _state = ExportState.idle;
  String? _errorMessage;
  _SuccessType? _successType;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    imageBytes = args['imageBytes'] as Uint8List;
    _imageProvider = MemoryImage(imageBytes);
    onSaveComplete = args['onSaveComplete'] as VoidCallback?;
    onSaveToRecentProjects = args['onSaveToRecentProjects'] as Future<void> Function()?;

    // Setup animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _saveToGallery() async {
    if (_state == ExportState.saving) return;

    _setExportState(ExportState.saving);
    HapticFeedback.lightImpact();

    try {
      final success = await ExportService.saveToGallery(imageBytes);

      if (success) {
        await onSaveToRecentProjects?.call();
        _successType = _SuccessType.gallery;
        _setExportState(ExportState.success);
        _scaleController.forward();
        HapticFeedback.mediumImpact();

        await Future.delayed(const Duration(milliseconds: 1800));
        onSaveComplete?.call();
        Get.back(result: true);
      } else {
        _errorMessage = LocaleKeys.editor_save_failed.tr;
        _setExportState(ExportState.error);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setExportState(ExportState.error);
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _shareImage() async {
    if (_state == ExportState.saving) return;

    _setExportState(ExportState.saving);
    HapticFeedback.lightImpact();

    try {
      final success = await ExportService.shareImage(imageBytes);

      if (success) {
        await onSaveToRecentProjects?.call();
        onSaveComplete?.call();
        _setExportState(ExportState.idle);
        
        Get.snackbar(
          '',
          '',
          titleText: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(LocaleKeys.export_shared.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          messageText: const SizedBox.shrink(),
          snackPosition: SnackPosition.TOP,
          backgroundColor: GroundedTheme.success,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      } else {
        _setExportState(ExportState.idle);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setExportState(ExportState.error);
    }
  }

  Future<void> _saveDraft() async {
    if (_state == ExportState.saving) return;

    _setExportState(ExportState.saving);
    HapticFeedback.lightImpact();

    try {
      await onSaveToRecentProjects?.call();
      _successType = _SuccessType.draft;
      _setExportState(ExportState.success);
      _scaleController.forward();
      HapticFeedback.mediumImpact();

      await Future.delayed(const Duration(milliseconds: 1200));
      onSaveComplete?.call();
      Get.back(result: true);
    } catch (e) {
      _errorMessage = e.toString();
      _setExportState(ExportState.error);
      HapticFeedback.heavyImpact();
    }
  }

  /// Back button — return to the Editor screen.
  /// Blocked while a save operation is in progress.
  void _handleBack() {
    if (_state == ExportState.saving) return;
    Get.back();
  }

  void _setExportState(ExportState state) {
    setState(() => _state = state);
    if (state == ExportState.success || state == ExportState.error) {
      _floatController.stop();
    } else if (state == ExportState.idle && !_floatController.isAnimating) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: _state != ExportState.saving,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            _buildBackground(),
            
            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildHeroImage(screenSize)),
                    _buildBottomSection(bottomPadding),
                  ],
                ),
              ),
            ),
            
            // Success/Error overlay
            if (_state == ExportState.success || _state == ExportState.error)
              _buildOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            const Color(0xFF1a237e).withValues(alpha: 0.3),
            const Color(0xFF0d47a1).withValues(alpha: 0.1),
            Colors.black,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _GlassButton(
            onTap: _state == ExportState.saving ? null : _handleBack,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _state == ExportState.saving ? Colors.white24 : Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          // Title
          Text(
            LocaleKeys.export_title.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Invisible spacer to keep title centered
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildHeroImage(Size screenSize) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect behind image
              Container(
                constraints: BoxConstraints(
                  maxHeight: screenSize.height * 0.50,
                  maxWidth: screenSize.width * 0.92,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(GroundedTheme.radiusLarge),
                  child: ImageFiltered(
                    imageFilter: const ColorFilter.mode(
                      GroundedTheme.primary,
                      BlendMode.srcATop,
                    ),
                    child: Opacity(
                      opacity: 0.3,
                      child: Image(image: _imageProvider, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              // Main image
              Container(
                constraints: BoxConstraints(
                  maxHeight: screenSize.height * 0.50,
                  maxWidth: screenSize.width * 0.92,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(GroundedTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: GroundedTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(GroundedTheme.radiusLarge),
                  child: Image(image: _imageProvider, fit: BoxFit.contain),
                ),
              ),
              // Loading overlay on image
              if (_state == ExportState.saving)
                ClipRRect(
                  borderRadius: BorderRadius.circular(GroundedTheme.radiusLarge),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: screenSize.height * 0.50,
                      maxWidth: screenSize.width * 0.92,
                    ),
                    color: Colors.black54,
                    child: const Center(
                      child: _PulsingLoader(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        GroundedTheme.spacing20,
        GroundedTheme.spacing16,
        GroundedTheme.spacing20,
        bottomPadding + GroundedTheme.spacing12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons first — most important
          if (_state == ExportState.idle) _buildActions(),
          const SizedBox(height: 16),
          // Ad placeholder below actions
          _buildAdSpace(),
        ],
      ),
    );
  }

  Widget _buildAdSpace() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(GroundedTheme.radiusMedium),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.white.withValues(alpha: 0.15),
            size: 16,
          ),
          const SizedBox(width: GroundedTheme.spacing8),
          Text(
            LocaleKeys.export_sponsored.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.15),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        // Primary action - Save with prominent design
        _PrimaryActionButton(
          icon: Icons.download_rounded,
          label: LocaleKeys.export_save_to_gallery.tr,
          onTap: _saveToGallery,
        ),
        const SizedBox(height: 12),
        // Secondary actions row
        Row(
          children: [
            Expanded(
              child: _SecondaryActionButton(
                icon: Icons.share_rounded,
                label: LocaleKeys.export_share.tr,
                onTap: _shareImage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryActionButton(
                icon: Icons.bookmark_add_outlined,
                label: LocaleKeys.export_save_draft.tr,
                onTap: _saveDraft,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverlay() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: _state == ExportState.success
              ? _buildSuccessContent()
              : _buildErrorContent(),
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    final bool isDraft = _successType == _SuccessType.draft;
    final Color primaryColor = isDraft 
        ? GroundedTheme.secondary  // Purple for draft
        : GroundedTheme.success; // Green for gallery
    final Color secondaryColor = isDraft 
        ? const Color(0xFF5E35B1) 
        : const Color(0xFF2E7D32);
    final IconData icon = isDraft 
        ? Icons.bookmark_added_rounded 
        : Icons.check_rounded;
    final String title = isDraft 
        ? LocaleKeys.export_draft_saved.tr 
        : LocaleKeys.export_success.tr;
    final String subtitle = isDraft 
        ? LocaleKeys.export_success_draft_subtitle.tr 
        : LocaleKeys.export_success_gallery_subtitle.tr;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated checkmark
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GroundedTheme.error.withValues(alpha: 0.15),
            border: Border.all(color: GroundedTheme.error.withValues(alpha: 0.5), width: 2),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: GroundedTheme.error,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          LocaleKeys.export_failed.tr,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => _setExportState(ExportState.idle),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            LocaleKeys.common_retry.tr,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Glass morphism button
class _GlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GroundedTheme.radiusMedium),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(GroundedTheme.radiusMedium),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Primary action button with gradient
class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GroundedTheme.radiusLarge),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GroundedTheme.primary,
                Color(0xFF1976D2),
              ],
            ),
            borderRadius: BorderRadius.circular(GroundedTheme.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: GroundedTheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action button with outline style
class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GroundedTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(GroundedTheme.radiusMedium),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing loader animation
class _PulsingLoader extends StatefulWidget {
  const _PulsingLoader();

  @override
  State<_PulsingLoader> createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<_PulsingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating arc
              Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(56, 56),
                  painter: _ArcPainter(),
                ),
              ),
              // Center icon
              Icon(
                Icons.cloud_upload_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 24,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, 0, math.pi * 0.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Export state enum
enum ExportState {
  idle,
  saving,
  success,
  error,
}

/// Success type to show different messages
enum _SuccessType {
  gallery,
  draft,
}
