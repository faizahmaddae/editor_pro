import 'dart:io';
import 'package:editor_pro/generated/locales.g.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/grounded_theme.dart';
import '../../../data/services/project_storage.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
import '../widgets/blank_canvas_sheet.dart';

/// Global route observer for detecting navigation events
final RouteObserver<ModalRoute<void>> homeRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Premium Home Screen — World-class photo editor landing
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

// ── Light-mode tokens ────────────────────────────────────
// Tuned for real-device sRGB panels – no withOpacity.
const _kScaffoldLight = Color(0xFFF0F1F5); // cool gray-100
const _kCardLight = Color(0xFFFFFFFF);
const _kCardAltLight = Color(0xFFF6F7FB); // alt surface
const _kBorderLight = Color(0xFFD4D7E0); // gray-300
const _kTextPrimaryLight = Color(0xFF111827); // gray-900
const _kTextSecondaryLight = Color(0xFF6B7280); // gray-500
const _kTextTertiaryLight = Color(0xFF9CA3AF); // gray-400
const _kHandleLight = Color(0xFFC0C4CC);
bool get _isLight => !GroundedTheme.isDarkMode;

class _HomeViewState extends State<HomeView>
    with WidgetsBindingObserver, RouteAware, TickerProviderStateMixin {
  HomeController get controller => Get.find<HomeController>();

  // ── Staggered entrance animations ──────────────────────
  late final AnimationController _staggerController;
  static const _sectionCount = 5;
  late final List<Animation<double>> _sectionAnims;

  // ── Shimmer animation ──────────────────────────────────
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _sectionAnims = List.generate(_sectionCount, (i) {
      final start = (i * 0.12).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _staggerController.forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      homeRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _staggerController.dispose();
    homeRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (kDebugMode) debugPrint('>>> HomeView: didPopNext - Refreshing');
    controller.loadRecentProjects();
    // Restore status bar style after returning from editor (which forces light icons)
    _applyStatusBarStyle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.loadRecentProjects();
      _applyStatusBarStyle();
    }
  }

  /// Sets the correct status bar icon brightness for the current theme mode.
  void _applyStatusBarStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      GroundedTheme.isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );
  }

  // ── Helpers ────────────────────────────────────────────

  /// Wraps a section widget with staggered fade + slide entrance.
  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _sectionAnims[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(_sectionAnims[index]),
        child: child,
      ),
    );
  }

  /// Returns a localized, time-aware greeting.
  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return LocaleKeys.home_greeting_morning.tr;
    if (hour < 17) return LocaleKeys.home_greeting_afternoon.tr;
    return LocaleKeys.home_greeting_evening.tr;
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final overlayStyle = GroundedTheme.isDarkMode
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: _isLight ? _kScaffoldLight : GroundedTheme.background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => controller.loadRecentProjects(),
            color: GroundedTheme.primary,
            backgroundColor: GroundedTheme.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Error banner — no animation, must appear instantly
                SliverToBoxAdapter(child: _buildErrorBanner()),

                // Animated content sections
                SliverToBoxAdapter(child: _animated(0, _buildHeader())),
                SliverToBoxAdapter(child: _animated(1, _buildHeroSection())),
                SliverToBoxAdapter(child: _animated(2, _buildQuickActions())),
                SliverToBoxAdapter(child: _animated(3, _buildRecentEditsHeader())),
                _buildRecentEditsList(),

                // Bottom safe-area padding
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  Content Sections
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildErrorBanner() {
    return Obx(() {
      final error = controller.errorMessage.value;
      if (error.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _isLight
              ? const Color(0xFFFEE2E2) // red-100
              : GroundedTheme.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isLight
                ? const Color(0xFFFCA5A5) // red-300
                : GroundedTheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: GroundedTheme.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                style: GroundedTheme.bodyMedium
                    .copyWith(color: GroundedTheme.error),
              ),
            ),
            GestureDetector(
              onTap: () => controller.errorMessage.value = '',
              child:
                  Icon(Icons.close, color: GroundedTheme.error, size: 18),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _isLight
                      ? const [
                          BoxShadow(
                            color: Color(0x4D3B82F6), // 30%
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                LocaleKeys.app_title.tr,
                style: GroundedTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Semantics(
            label: LocaleKeys.settings_title.tr,
            button: true,
            child: _PremiumIconButton(
              icon: Icons.settings_outlined,
              onTap: () => Get.toNamed(Routes.SETTINGS),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _timeGreeting(),
            style: GroundedTheme.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.home_create_question.tr,
            style: GroundedTheme.bodyLarge.copyWith(
              color: _isLight
                  ? _kTextSecondaryLight
                  : GroundedTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            final isLoading = controller.isLoading.value;
            return Column(
              children: [
                _PrimaryCTAButton(
                  label: LocaleKeys.home_import_photo.tr,
                  icon: Icons.add_photo_alternate_rounded,
                  onTap: controller.pickFromGallery,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryCTAButton(
                        icon: Icons.add_box_rounded,
                        label: LocaleKeys.home_create_new.tr,
                        onTap: () => BlankCanvasSheet.show(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SecondaryCTAButton(
                        icon: Icons.camera_alt_rounded,
                        label: LocaleKeys.home_pick_from_camera.tr,
                        onTap: controller.pickFromCamera,
                        isLoading: isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: LocaleKeys.home_quick_actions.tr),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.0,
              children: [
                _QuickActionCard(
                  icon: Icons.crop_rounded,
                  label: LocaleKeys.home_action_crop.tr,
                  color: const Color(0xFF6366F1),
                  onTap: () => controller.quickAction('cropRotate'),
                ),
                _QuickActionCard(
                  icon: Icons.auto_fix_high_rounded,
                  label: LocaleKeys.home_action_filters.tr,
                  color: const Color(0xFFF59E0B),
                  onTap: () => controller.quickAction('filter'),
                ),
                _QuickActionCard(
                  icon: Icons.tune_rounded,
                  label: LocaleKeys.home_action_adjust.tr,
                  color: const Color(0xFF3B82F6),
                  onTap: () => controller.quickAction('tune'),
                ),
                _QuickActionCard(
                  icon: Icons.blur_on_rounded,
                  label: LocaleKeys.home_action_blur.tr,
                  color: const Color(0xFF10B981),
                  onTap: () => controller.quickAction('blur'),
                ),
                _QuickActionCard(
                  icon: Icons.text_fields_rounded,
                  label: LocaleKeys.home_action_text.tr,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => controller.quickAction('text'),
                ),
                _QuickActionCard(
                  icon: Icons.brush_rounded,
                  label: LocaleKeys.home_action_draw.tr,
                  color: const Color(0xFFEC4899),
                  onTap: () => controller.quickAction('paint'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEditsHeader() {
    return Obx(() {
      if (controller.recentProjects.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: 36, bottom: 14),
        child: _SectionHeader(title: LocaleKeys.home_recent_projects.tr),
      );
    });
  }

  Widget _buildRecentEditsList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return SliverToBoxAdapter(
            child: _animated(4, _buildLoadingSkeleton()));
      }

      if (controller.recentProjects.isEmpty) {
        return SliverToBoxAdapter(child: _animated(4, _buildEmptyState()));
      }

      return SliverToBoxAdapter(
        child: _animated(
          4,
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: controller.recentProjects.length,
              itemBuilder: (context, index) {
                final project = controller.recentProjects[index];
                return _RecentEditCard(
                  project: project,
                  onTap: () => controller.openProject(project),
                  onLongPress: () => _showProjectActions(project),
                  onMenuTap: () => _showProjectActions(project),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLoadingSkeleton() {
    return SizedBox(
      height: 210,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsetsDirectional.only(end: 14),
                decoration: BoxDecoration(
                  color: _isLight ? _kCardLight : GroundedTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isLight ? _kBorderLight : GroundedTheme.border,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: const Alignment(-1.0, -0.3),
                        end: const Alignment(2.0, 0.3),
                        colors: [
                          GroundedTheme.border.withValues(alpha: 0.3),
                          GroundedTheme.border.withValues(alpha: 0.7),
                          GroundedTheme.border.withValues(alpha: 0.3),
                        ],
                        stops: [
                          (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                          _shimmerController.value,
                          (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: Container(
                      color: GroundedTheme.border.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          Container(
                            height: 10,
                            width: 80,
                            decoration: BoxDecoration(
                              color: GroundedTheme.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 8,
                            width: 50,
                            decoration: BoxDecoration(
                              color: GroundedTheme.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(20, 30, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: _isLight ? _kCardLight : GroundedTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isLight ? _kBorderLight : GroundedTheme.border,
        ),
        boxShadow: _isLight
            ? const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _isLight
                  ? const Color(0xFFEFF6FF) // blue-50
                  : const Color(0x263B82F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 26,
              color: GroundedTheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            LocaleKeys.home_no_recent_projects.tr,
            style: GroundedTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: _isLight
                  ? _kTextPrimaryLight
                  : GroundedTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.home_start_editing.tr,
            style: GroundedTheme.bodyMedium.copyWith(
              color: _isLight
                  ? _kTextSecondaryLight
                  : GroundedTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Shows a proper context menu for a recent project card
  void _showProjectActions(Project project) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _isLight ? _kCardLight : GroundedTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: _isLight ? _kHandleLight : GroundedTheme.border,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              // Open
              _ContextMenuItem(
                icon: Icons.edit_rounded,
                label: LocaleKeys.home_open_project.tr,
                onTap: () {
                  Navigator.pop(context);
                  controller.openProject(project);
                },
              ),
              // Share
              _ContextMenuItem(
                icon: Icons.share_rounded,
                label: LocaleKeys.home_share_project.tr,
                onTap: () {
                  Navigator.pop(context);
                  // Future: implement share
                },
              ),
              // Delete — destructive
              _ContextMenuItem(
                icon: Icons.delete_outline_rounded,
                label: LocaleKeys.home_delete_project.tr,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _deleteWithUndo(project);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteWithUndo(Project project) {
    HapticFeedback.mediumImpact();
    controller.softDeleteProject(project);
    bool undone = false;
    Get.snackbar(
      LocaleKeys.home_project_deleted.tr,
      '',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: GroundedTheme.surface,
      colorText: GroundedTheme.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () {
          undone = true;
          controller.undoDeleteProject();
          if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        },
        child: Text(
          LocaleKeys.common_undo.tr,
          style: GroundedTheme.labelLarge.copyWith(
            color: GroundedTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackbarStatus: (status) {
        if (status == SnackbarStatus.CLOSED && !undone) {
          controller.confirmDeleteProject();
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium UI Components
// ─────────────────────────────────────────────────────────────────────────────

/// Section title with accent bar
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 18,
            decoration: BoxDecoration(
              color: GroundedTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GroundedTheme.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings / icon button
class _PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PremiumIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _isLight ? _kCardLight : GroundedTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isLight ? _kBorderLight : GroundedTheme.border,
            ),
            boxShadow: _isLight
                ? const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: _isLight
                ? _kTextSecondaryLight
                : GroundedTheme.textSecondary,
            size: 21,
          ),
        ),
      ),
    );
  }
}

/// ★ Primary hero CTA — gradient blue, strong shadow
class _PrimaryCTAButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  const _PrimaryCTAButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableCard(
      onTap: isLoading ? null : onTap,
      pressScale: 0.97,
      semanticLabel: label,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLight
              ? const [
                  BoxShadow(
                    color: Color(0x4D2563EB),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x333B82F6),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: GroundedTheme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable press-animation wrapper
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final String? semanticLabel;

  const _PressableCard({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = 0.95,
    this.semanticLabel,
  });

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _isPressed = false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? widget.pressScale : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _isPressed ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Secondary CTA (Create New / Camera)
class _SecondaryCTAButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _SecondaryCTAButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableCard(
      onTap: isLoading ? null : onTap,
      pressScale: 0.96,
      semanticLabel: label,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _isLight ? _kCardLight : GroundedTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isLight ? _kBorderLight : GroundedTheme.border,
          ),
          boxShadow: _isLight
              ? const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _isLight
                  ? _kTextPrimaryLight
                  : GroundedTheme.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GroundedTheme.labelLarge.copyWith(
                color: _isLight
                    ? _kTextPrimaryLight
                    : GroundedTheme.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick-action card — white card with colored icon circle + press animation
class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  static const _duration = Duration(milliseconds: 130);
  static const _curve = Curves.easeOut;

  // Rest shadow (light mode) — soft layered depth
  static const _restShadow = [
    BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  // Pressed shadow (light mode) — slightly elevated
  static const _pressedShadow = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  @override
  Widget build(BuildContext context) {
    final iconBg = _isLight
        ? Color.lerp(widget.color, Colors.white, 0.78)!
        : Color.lerp(widget.color, Colors.black, 0.68)!;

    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: _duration,
          curve: _curve,
          child: AnimatedContainer(
            duration: _duration,
            curve: _curve,
            decoration: BoxDecoration(
              color: _isLight ? _kCardLight : GroundedTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isLight ? _kBorderLight : GroundedTheme.border,
              ),
              boxShadow: _isLight
                  ? (_pressed ? _pressedShadow : _restShadow)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.label,
                  style: GroundedTheme.labelSmall.copyWith(
                    color: _isLight
                        ? _kTextPrimaryLight
                        : GroundedTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Recent edit card
class _RecentEditCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMenuTap;

  const _RecentEditCard({
    required this.project,
    required this.onTap,
    required this.onLongPress,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 14),
      child: _PressableCard(
        onTap: onTap,
        onLongPress: onLongPress,
        pressScale: 0.97,
        semanticLabel: _formatDate(project.lastEditedAt),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: _isLight ? _kCardLight : GroundedTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isLight ? _kBorderLight : GroundedTheme.border,
            ),
            boxShadow: _isLight
                ? const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(dpr),
                // Top scrim
                const Positioned(
                  top: 0, left: 0, right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x59000000), Color(0x00000000)],
                      ),
                    ),
                    child: SizedBox(height: 48),
                  ),
                ),
                // Bottom scrim
                const Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xB3000000)],
                      ),
                    ),
                    child: SizedBox(height: 72),
                  ),
                ),
                // Menu
                PositionedDirectional(
                  top: 8, start: 8,
                  child: GestureDetector(
                    onTap: onMenuTap,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0x59000000),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // Editable badge
                if (project.hasEditableHistory)
                  PositionedDirectional(
                    top: 8, end: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: GroundedTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4D000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.layers_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                // Date
                PositionedDirectional(
                  bottom: 10, start: 10, end: 10,
                  child: Text(
                    _formatDate(project.lastEditedAt),
                    style: GroundedTheme.labelSmall.copyWith(
                      color: const Color(0xF2FFFFFF),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      shadows: const [
                        Shadow(
                          color: Color(0x80000000),
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
      ),
    );
  }

  Widget _buildImage(double dpr) {
    final imagePath = project.thumbnailPath ?? project.imagePath;
    final file = File(imagePath);
    final cacheKey = project.lastEditedAt.millisecondsSinceEpoch;

    if (!file.existsSync()) return _buildPlaceholder();

    return Image.file(
      file,
      key: ValueKey('$imagePath-$cacheKey'),
      fit: BoxFit.cover,
      cacheWidth: (160 * dpr).toInt(),
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _isLight ? _kCardAltLight : GroundedTheme.card,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: _isLight ? _kTextTertiaryLight : GroundedTheme.textTertiary,
          size: 32,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return LocaleKeys.home_today.tr;
    } else if (difference.inDays == 1) {
      return LocaleKeys.home_yesterday.tr;
    } else if (difference.inDays < 7) {
      return LocaleKeys.home_days_ago.trParams({'s': '${difference.inDays}'});
    } else {
      final locale = Get.locale?.toString() ?? 'en_US';
      return DateFormat.MMMd(locale).format(date);
    }
  }
}

/// Context menu item for project action bottom sheet
class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? GroundedTheme.error : GroundedTheme.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: GroundedTheme.bodyLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
