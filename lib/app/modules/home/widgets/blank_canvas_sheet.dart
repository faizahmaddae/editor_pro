import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';
import '../../../routes/app_pages.dart';

/// Premium bottom sheet for creating a blank canvas with preset or custom sizes.
///
/// v3 improvements over v2:
/// - Grouped section cards with distinct visual containers
/// - Scrollable background chips (not cramped equal-width)
/// - Hero-sized canvas preview (120px+) above CTA
/// - Preset cards with gradient-border selection (not solid fill)
/// - Color palette with distinct "Custom…" pill instead of mimicking a dot
/// - Animated orientation toggle with rotating icon
/// - Refined spacing on a strict 4px grid (8/12/16/20/24/32)
/// - CTA arrow icon ("proceed") instead of "+" ("add")
/// - Spring-based micro-interactions on selections
/// - Custom size input inside a visually distinct inset card
class BlankCanvasSheet extends StatefulWidget {
  const BlankCanvasSheet({super.key});

  /// Show the blank canvas creation sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      builder: (context) => const BlankCanvasSheet(),
    );
  }

  @override
  State<BlankCanvasSheet> createState() => _BlankCanvasSheetState();
}

class _BlankCanvasSheetState extends State<BlankCanvasSheet>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────
  int _selectedPresetIndex = 0;
  bool _isPortrait = true;

  final _widthController = TextEditingController(text: '1080');
  final _heightController = TextEditingController(text: '1920');

  int _selectedBackground = 0; // 0=transparent, 1=white, 2=black, 3=custom color, 4=image
  Color _customColor = const Color(0xFFFF6B6B);
  String? _backgroundImagePath;
  Rect? _backgroundImageCropRect;
  double? _cropAspectRatio;

  // ── Entrance animation ───────────────────────────────────
  late final AnimationController _staggerController;
  static const _sectionCount = 5; // header, presets, bg, preview, button
  late final List<Animation<double>> _sectionAnims;

  // ── Presets ──────────────────────────────────────────────
  static const List<CanvasPreset> _presets = [
    CanvasPreset(
      id: 'story',
      nameKey: 'blank_preset_story',
      width: 1080,
      height: 1920,
      aspectLabel: '9:16',
      icon: Icons.stay_current_portrait_rounded,
      gradient: [Color(0xFFE1306C), Color(0xFFF77737)],
    ),
    CanvasPreset(
      id: 'post',
      nameKey: 'blank_preset_post',
      width: 1080,
      height: 1080,
      aspectLabel: '1:1',
      icon: Icons.crop_square_rounded,
      gradient: [Color(0xFF405DE6), Color(0xFF833AB4)],
    ),
    CanvasPreset(
      id: 'youtube',
      nameKey: 'blank_preset_youtube',
      width: 1280,
      height: 720,
      aspectLabel: '16:9',
      icon: Icons.smart_display_rounded,
      gradient: [Color(0xFFFF0000), Color(0xFFCC0000)],
    ),
    CanvasPreset(
      id: 'feed',
      nameKey: 'blank_preset_feed',
      width: 1080,
      height: 1350,
      aspectLabel: '4:5',
      icon: Icons.photo_rounded,
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    CanvasPreset(
      id: 'pinterest',
      nameKey: 'blank_preset_pinterest',
      width: 1000,
      height: 1500,
      aspectLabel: '2:3',
      icon: Icons.push_pin_rounded,
      gradient: [Color(0xFFE60023), Color(0xFFBD081C)],
    ),
    CanvasPreset(
      id: 'landscape',
      nameKey: 'blank_preset_landscape',
      width: 1920,
      height: 1080,
      aspectLabel: '16:9',
      icon: Icons.landscape_rounded,
      gradient: [Color(0xFF10B981), Color(0xFF34D399)],
    ),
    CanvasPreset(
      id: 'a4',
      nameKey: 'blank_preset_a4',
      width: 2480,
      height: 3508,
      aspectLabel: 'A4',
      icon: Icons.description_rounded,
      gradient: [Color(0xFF6B7280), Color(0xFF9CA3AF)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // ── Computed values ──────────────────────────────────────

  Size get _selectedSize {
    if (_selectedPresetIndex >= 0 && _selectedPresetIndex < _presets.length) {
      final p = _presets[_selectedPresetIndex];
      final w = p.width.toDouble();
      final h = p.height.toDouble();
      if (_isPortrait) {
        return Size(math.min(w, h), math.max(w, h));
      } else {
        return Size(math.max(w, h), math.min(w, h));
      }
    }
    final width = double.tryParse(_widthController.text) ?? 1080;
    final height = double.tryParse(_heightController.text) ?? 1920;
    return Size(width.clamp(100, 4096), height.clamp(100, 4096));
  }

  Color? get _backgroundColor {
    switch (_selectedBackground) {
      case 1:
        return Colors.white;
      case 2:
        return Colors.black;
      case 3:
        return _customColor;
      default:
        return null;
    }
  }

  bool get _hasImageBackground =>
      _selectedBackground == 4 && _backgroundImagePath != null;

  void _createCanvas() {
    final size = _selectedSize;
    final bgColor = _backgroundColor;
    Navigator.pop(context);

    final args = <String, dynamic>{
      'mode': 'blank',
      'canvasSize': {'width': size.width, 'height': size.height},
      'backgroundColor': bgColor?.toARGB32(),
      'presetId': _selectedPresetIndex >= 0
          ? _presets[_selectedPresetIndex].id
          : 'custom',
    };

    if (_hasImageBackground) {
      args['backgroundImagePath'] = _backgroundImagePath;
      if (_backgroundImageCropRect != null && _cropAspectRatio != null) {
        final currentAR = size.width / size.height;
        if ((currentAR - _cropAspectRatio!).abs() < 0.01) {
          final r = _backgroundImageCropRect!;
          args['backgroundImageCropRect'] = {
            'left': r.left,
            'top': r.top,
            'width': r.width,
            'height': r.height,
          };
        }
      }
    }

    Get.toNamed(Routes.EDITOR, arguments: args);
  }

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (image != null && mounted) {
      final cropRect = await Navigator.of(context).push<Rect>(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) => _ImagePositionScreen(
            imagePath: image.path,
            canvasAspectRatio: _selectedSize.width / _selectedSize.height,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      );
      if (cropRect != null && mounted) {
        setState(() {
          _backgroundImagePath = image.path;
          _backgroundImageCropRect = cropRect;
          _cropAspectRatio = _selectedSize.width / _selectedSize.height;
          _selectedBackground = 4;
        });
      }
    }
  }

  void _swapCustomDimensions() {
    HapticFeedback.selectionClick();
    final tmp = _widthController.text;
    _widthController.text = _heightController.text;
    _heightController.text = tmp;
    setState(() {});
  }

  /// Staggered fade + slide entrance with parallax depth.
  Widget _animated(int index, Widget child) {
    final slideOffset = 0.04 + (index * 0.01);
    return FadeTransition(
      opacity: _sectionAnims[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, slideOffset),
          end: Offset.zero,
        ).animate(_sectionAnims[index]),
        child: child,
      ),
    );
  }

  // ── Light-mode design system ─────────────────────────────
  // Tuned for real-device sRGB panels – stronger contrast, no washed-out look.
  static const _sheetBgLight = Color(0xFFEFF1F5);
  static const _cardFillLight = Color(0xFFFFFFFF);
  static const _borderLight = Color(0xFFD0D4DC);
  static const _labelLight = Color(0xFF4B5563);
  static const _handleLight = Color(0xFFBCC1CA);
  bool get _isLight => !GroundedTheme.isDarkMode;

  /// Wraps section content in a grouped card container.
  Widget _sectionCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isLight ? _cardFillLight : GroundedTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLight ? _borderLight : GroundedTheme.border,
        ),
        boxShadow: _isLight
            ? const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final sheetColor = _isLight ? _sheetBgLight : GroundedTheme.surface;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Pinned drag handle — always visible ───
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _isLight ? _handleLight : GroundedTheme.border,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                // ── Pinned header ─────────────────────────
                _animated(0, _buildHeader()),

                const SizedBox(height: 20),

                // ── Scrollable content area ───────────────
                Flexible(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    slivers: [
                      SliverToBoxAdapter(
                        child: _animated(1, _buildSizeSection()),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                      SliverToBoxAdapter(
                        child: _animated(2, _buildBackgroundSection()),
                      ),
                      // Custom color picker (animated expand)
                      SliverToBoxAdapter(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: _selectedBackground == 3
                              ? _buildCustomColorPicker()
                              : const SizedBox.shrink(),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                      SliverToBoxAdapter(
                        child: _animated(3, _buildHeroPreview()),
                      ),
                      // Bottom breathing room for CTA
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                    ],
                  ),
                ),

                // ── Pinned CTA button — always visible ────
                _animated(
                  4,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: _CreateButton(onTap: _createCanvas),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sections ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isLight
                  ? const [
                      BoxShadow(
                        color: Color(0x4D3B82F6),
                        blurRadius: 16,
                        offset: Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: const Icon(
              Icons.add_box_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.blank_title.tr,
                  style: GroundedTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  LocaleKeys.blank_subtitle.tr,
                  style: GroundedTheme.labelSmall.copyWith(
                    color: GroundedTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Size section: label + orientation toggle + preset list + custom input
  Widget _buildSizeSection() {
    return _sectionCard(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label + orientation toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.aspect_ratio_rounded,
                  size: 20,
                  color: _isLight ? _labelLight : GroundedTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  LocaleKeys.blank_size.tr,
                  style: GroundedTheme.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _isLight ? _labelLight : GroundedTheme.textSecondary,
                    letterSpacing: 0.5,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                _OrientationToggle(
                  isPortrait: _isPortrait,
                  onToggle: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isPortrait = !_isPortrait);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Preset list with edge-fade
          SizedBox(
            height: 82,
            child: ShaderMask(
              shaderCallback: (bounds) {
                final isRtl =
                    Directionality.of(context) == TextDirection.rtl;
                return LinearGradient(
                  begin:
                      isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  end:
                      isRtl ? Alignment.centerLeft : Alignment.centerRight,
                  colors: const [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.04, 0.92, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _presets.length + 1,
                itemBuilder: (context, index) {
                  if (index == _presets.length) {
                    return _PresetCard(
                      isSelected: _selectedPresetIndex < 0,
                      icon: Icons.tune_rounded,
                      label: LocaleKeys.blank_custom.tr,
                      subtitle: LocaleKeys.blank_custom_sub.tr,
                      gradient: const [Color(0xFF374151), Color(0xFF4B5563)],
                      onTap: () =>
                          setState(() => _selectedPresetIndex = -1),
                    );
                  }
                  final preset = _presets[index];
                  return _PresetCard(
                    isSelected: _selectedPresetIndex == index,
                    icon: preset.icon,
                    label: preset.nameKey.tr,
                    subtitle: preset.aspectLabel,
                    gradient: preset.gradient,
                    onTap: () =>
                        setState(() => _selectedPresetIndex = index),
                  );
                },
              ),
            ),
          ),

          // Custom size input (animated expand)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _selectedPresetIndex < 0
                ? _buildCustomSizeInput()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSizeInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GroundedTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SizeInputField(
                controller: _widthController,
                label: LocaleKeys.blank_width.tr,
                onChanged: (_) => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: IconButton(
                onPressed: _swapCustomDimensions,
                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                color: GroundedTheme.primary,
                tooltip: LocaleKeys.blank_swap.tr,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x1F3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(40, 40),
                ),
              ),
            ),
            Expanded(
              child: _SizeInputField(
                controller: _heightController,
                label: LocaleKeys.blank_height.tr,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Background section: scrollable chips + conditional color picker
  Widget _buildBackgroundSection() {
    return _sectionCard(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: _isLight ? _labelLight : GroundedTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  LocaleKeys.blank_background.tr,
                  style: GroundedTheme.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _isLight ? _labelLight : GroundedTheme.textSecondary,
                    letterSpacing: 0.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Scrollable chip row
          SizedBox(
            height: 76,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _BackgroundChip(
                  isSelected: _selectedBackground == 0,
                  isTransparent: true,
                  label: LocaleKeys.blank_bg_transparent.tr,
                  onTap: () => setState(() => _selectedBackground = 0),
                ),
                _BackgroundChip(
                  isSelected: _selectedBackground == 1,
                  color: Colors.white,
                  label: LocaleKeys.blank_bg_white.tr,
                  onTap: () => setState(() => _selectedBackground = 1),
                ),
                _BackgroundChip(
                  isSelected: _selectedBackground == 2,
                  color: Colors.black,
                  label: LocaleKeys.blank_bg_black.tr,
                  onTap: () => setState(() => _selectedBackground = 2),
                ),
                _BackgroundChip(
                  isSelected: _selectedBackground == 3,
                  color: _customColor,
                  label: LocaleKeys.blank_bg_color.tr,
                  onTap: () => setState(() => _selectedBackground = 3),
                ),
                _BackgroundChip(
                  isSelected: _selectedBackground == 4,
                  isImage: true,
                  imagePath: _backgroundImagePath,
                  label: LocaleKeys.blank_bg_image.tr,
                  onTap: () {
                    if (_selectedBackground == 4 ||
                        _backgroundImagePath == null) {
                      _pickBackgroundImage();
                    } else {
                      setState(() => _selectedBackground = 4);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomColorPicker() {
    const colors = [
      // Row 1 — Vivid
      Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFFBBF24),
      Color(0xFF84CC16), Color(0xFF22C55E), Color(0xFF14B8A6),
      Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF8B5CF6),
      // Row 2 — Muted / pastel / neutral
      Color(0xFFFF9EAA), Color(0xFFFFD6A5), Color(0xFFFFF3B0),
      Color(0xFFA7F3D0), Color(0xFFBAE6FD), Color(0xFFC4B5FD),
      Color(0xFF6B7280), Color(0xFF374151), Color(0xFF1F2937),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isLight ? _cardFillLight : GroundedTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isLight ? _borderLight : GroundedTheme.border,
          ),
        ),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((color) {
                final isSelected =
                    _customColor.toARGB32() == color.toARGB32();
                return _ColorDot(
                  color: color,
                  isSelected: isSelected,
                  onTap: () => setState(() => _customColor = color),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            // "Custom..." pill button — visually distinct from dots
            _CustomColorPill(
              currentColor: _customColor,
              onTap: _showFullColorPicker,
            ),
          ],
        ),
      ),
    );
  }

  void _showFullColorPicker() {
    Color tempColor = _customColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GroundedTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          LocaleKeys.blank_pick_color.tr,
          style: GroundedTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: HueRingPicker(
            pickerColor: tempColor,
            onColorChanged: (c) => tempColor = c,
            enableAlpha: false,
            displayThumbColor: true,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              LocaleKeys.blank_cancel.tr,
              style: TextStyle(color: GroundedTheme.textSecondary),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GroundedTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() => _customColor = tempColor);
              Navigator.pop(ctx);
            },
            child: Text(LocaleKeys.blank_select.tr),
          ),
        ],
      ),
    );
  }

  /// Hero-sized preview: large canvas visualization above the CTA
  Widget _buildHeroPreview() {
    final size = _selectedSize;
    final ratio = size.width / size.height;
    final bgColor = _backgroundColor;

    // Fit the canvas ratio into a generous 130px-tall box
    const maxH = 130.0;
    const maxW = 220.0;
    final double previewW, previewH;
    if (ratio >= maxW / maxH) {
      previewW = maxW;
      previewH = maxW / ratio;
    } else {
      previewH = maxH;
      previewW = maxH * ratio;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: _isLight ? _cardFillLight : GroundedTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isLight ? const Color(0xFFE5E7EB) : GroundedTheme.border,
          ),
          boxShadow: _isLight
              ? const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Large canvas preview
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: previewW,
              height: previewH,
              decoration: BoxDecoration(
                color: _hasImageBackground
                    ? null
                    : bgColor ??
                        GroundedTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isLight
                      ? const Color(0xFFE5E7EB)
                      : GroundedTheme.border.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (bgColor ?? GroundedTheme.primary)
                        .withValues(alpha: _isLight ? 0.18 : 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _hasImageBackground
                    ? Image.file(
                        File(_backgroundImagePath!),
                        fit: BoxFit.cover,
                        width: previewW,
                        height: previewH,
                      )
                    : bgColor == null
                        ? CustomPaint(
                            painter: _CheckerboardPainter(),
                            size: Size(previewW, previewH),
                          )
                        : null,
              ),
            ),
            const SizedBox(height: 16),
            // Dimension label
            Text(
              '${size.width.toInt()} \u00D7 ${size.height.toInt()} px',
              style: GroundedTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _hasImageBackground
                  ? LocaleKeys.blank_bg_image.tr
                  : bgColor == null
                      ? LocaleKeys.blank_bg_transparent.tr
                      : LocaleKeys.blank_solid_bg.tr,
              style: GroundedTheme.labelSmall.copyWith(
                color: _isLight ? _labelLight : GroundedTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class CanvasPreset {
  final String id;
  final String nameKey;
  final int width;
  final int height;
  final String aspectLabel;
  final IconData icon;
  final List<Color> gradient;

  const CanvasPreset({
    required this.id,
    required this.nameKey,
    required this.width,
    required this.height,
    required this.aspectLabel,
    required this.icon,
    required this.gradient,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Portrait / Landscape orientation toggle pill with rotating icon
class _OrientationToggle extends StatelessWidget {
  final bool isPortrait;
  final VoidCallback onToggle;

  const _OrientationToggle({
    required this.isPortrait,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isPortrait ? LocaleKeys.blank_portrait.tr : LocaleKeys.blank_landscape_orient.tr,
      button: true,
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: !GroundedTheme.isDarkMode
                ? const Color(0x143B82F6)
                : GroundedTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: !GroundedTheme.isDarkMode
                  ? const Color(0x403B82F6)
                  : GroundedTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rotating icon
              AnimatedRotation(
                turns: isPortrait ? 0.0 : 0.25,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.stay_current_portrait_rounded,
                  size: 16,
                  color: GroundedTheme.primary,
                ),
              ),
              const SizedBox(width: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  isPortrait
                      ? LocaleKeys.blank_portrait.tr
                      : LocaleKeys.blank_landscape_orient.tr,
                  key: ValueKey(isPortrait),
                  style: GroundedTheme.labelSmall.copyWith(
                    color: GroundedTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preset card — v3: gradient border + tinted fill on selection with bounce
class _PresetCard extends StatefulWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _PresetCard({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_PresetCard> createState() => _PresetCardState();
}

class _PresetCardState extends State<_PresetCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.97), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceCtrl,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(covariant _PresetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.label} ${widget.subtitle}',
      selected: widget.isSelected,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: _bounceAnim,
            builder: (context, child) => Transform.scale(
              scale: _bounceAnim.value,
              child: child,
            ),
            child: Builder(
            builder: (context) {
              final isLight = !GroundedTheme.isDarkMode;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 78,
                margin: const EdgeInsetsDirectional.only(end: 10),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.gradient.first.withValues(alpha: isLight ? 0.10 : 0.16)
                      : (isLight ? const Color(0xFFF8F9FC) : GroundedTheme.surface),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isSelected
                        ? widget.gradient.first
                        : (isLight ? const Color(0xFFD4D7E0) : GroundedTheme.border),
                    width: widget.isSelected ? 2 : 1,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: widget.gradient.first.withValues(alpha: isLight ? 0.25 : 0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : isLight
                          ? const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Small gradient indicator dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: widget.isSelected ? 28 : 24,
                      height: widget.isSelected ? 28 : 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: widget.gradient),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: widget.isSelected ? 16 : 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.label,
                      style: GroundedTheme.labelSmall.copyWith(
                        color: widget.isSelected
                            ? GroundedTheme.textPrimary
                            : GroundedTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.subtitle,
                      style: GroundedTheme.labelSmall.copyWith(
                        color: widget.isSelected
                            ? widget.gradient.first.withValues(alpha: 0.8)
                            : GroundedTheme.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        ),
      ),
    );
  }
}

/// Background chip — scrollable, roomy, consistent swatches with press animation
class _BackgroundChip extends StatefulWidget {
  final bool isSelected;
  final Color? color;
  final bool isTransparent;
  final bool isImage;
  final String? imagePath;
  final String label;
  final VoidCallback onTap;

  const _BackgroundChip({
    required this.isSelected,
    this.color,
    this.isTransparent = false,
    this.isImage = false,
    this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  State<_BackgroundChip> createState() => _BackgroundChipState();
}

class _BackgroundChipState extends State<_BackgroundChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Semantics(
        label: widget.label,
        selected: widget.isSelected,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Builder(
              builder: (context) {
                final isLightMode = !GroundedTheme.isDarkMode;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? GroundedTheme.primary.withValues(alpha: isLightMode ? 0.10 : 0.16)
                        : (isLightMode ? const Color(0xFFF8F9FC) : GroundedTheme.surface),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.isSelected
                          ? GroundedTheme.primary
                          : (isLightMode ? const Color(0xFFD4D7E0) : GroundedTheme.border),
                      width: widget.isSelected ? 2 : 1,
                    ),
                    boxShadow: widget.isSelected && isLightMode
                        ? [
                            BoxShadow(
                              color: GroundedTheme.primary.withValues(alpha: 0.22),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : isLightMode
                            ? const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSwatch(),
                      const SizedBox(height: 4),
                      Text(
                        widget.label,
                        style: GroundedTheme.labelSmall.copyWith(
                          color: widget.isSelected
                              ? GroundedTheme.primary
                              : GroundedTheme.textSecondary,
                          fontWeight:
                              widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 10,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwatch() {
    const size = 34.0;
    const radius = 10.0;

    if (widget.isImage) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: GroundedTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: widget.imagePath != null
              ? Image.file(
                  File(widget.imagePath!),
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                )
              : Container(
                  color: GroundedTheme.surface,
                  child: Icon(
                    Icons.image_rounded,
                    size: 16,
                    color: GroundedTheme.textTertiary,
                  ),
                ),
        ),
      );
    }

    if (widget.isTransparent) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: GroundedTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: CustomPaint(painter: _CheckerboardPainter()),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(radius),
        border: widget.color == Colors.white || widget.color == Colors.black
            ? Border.all(color: GroundedTheme.border)
            : null,
      ),
    );
  }
}

/// Color dot in palette grid with spring-scale selection animation
class _ColorDot extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ColorDot> createState() => _ColorDotState();
}

class _ColorDotState extends State<_ColorDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _scaleCtrl,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(covariant _ColorDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Builder(
          builder: (context) {
            final isLightMode = !GroundedTheme.isDarkMode;
            // Use dark ring/check on bright colors in light mode
            final ringColor = isLightMode
                ? const Color(0xFF1A1A1A)
                : Colors.white;
            final checkColor = widget.color.computeLuminance() > 0.5
                ? const Color(0xFF1A1A1A)
                : Colors.white;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.isSelected
                      ? ringColor
                      : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: widget.isSelected
                  ? Icon(Icons.check_rounded, color: checkColor, size: 16)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

/// "Custom..." pill button — visually distinct from color dots
class _CustomColorPill extends StatelessWidget {
  final Color currentColor;
  final VoidCallback onTap;

  const _CustomColorPill({
    required this.currentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: !GroundedTheme.isDarkMode
              ? const Color(0xFFF5F6F8)
              : GroundedTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: !GroundedTheme.isDarkMode
                ? const Color(0xFFD1D5DB)
                : GroundedTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              LocaleKeys.blank_custom_color.tr,
              style: GroundedTheme.labelSmall.copyWith(
                color: GroundedTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 10,
              color: GroundedTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Size input field for custom dimensions
class _SizeInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  const _SizeInputField({
    required this.controller,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GroundedTheme.labelSmall.copyWith(
            color: GroundedTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          style: GroundedTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: GroundedTheme.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: GroundedTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: GroundedTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: GroundedTheme.primary, width: 2),
            ),
            suffixText: 'px',
            suffixStyle: GroundedTheme.labelSmall.copyWith(
              color: GroundedTheme.textTertiary,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Create canvas CTA button — v3: arrow icon + gradient shift on press
class _CreateButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CreateButton({required this.onTap});

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        // Slight delay so press animation is visible before navigation
        Future.delayed(const Duration(milliseconds: 60), widget.onTap);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 56,
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPressed
                ? const [Color(0xFF2563EB), Color(0xFF1D4ED8)]
                : const [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? const Color(0x332563EB)
                  : (!GroundedTheme.isDarkMode
                      ? const Color(0x4D2563EB)
                      : const Color(0x332563EB)),
              blurRadius: _isPressed ? 10 : 24,
              offset: Offset(0, _isPressed ? 4 : 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              LocaleKeys.blank_create.tr,
              style: GroundedTheme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image position editor (full-screen)
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen editor for positioning an image within a target canvas aspect
/// ratio. Returns a normalised [Rect] (0..1) representing the visible portion.
class _ImagePositionScreen extends StatefulWidget {
  final String imagePath;
  final double canvasAspectRatio;

  const _ImagePositionScreen({
    required this.imagePath,
    required this.canvasAspectRatio,
  });

  @override
  State<_ImagePositionScreen> createState() => _ImagePositionScreenState();
}

class _ImagePositionScreenState extends State<_ImagePositionScreen> {
  final _transformController = TransformationController();
  bool _didCenterImage = false;

  Size? _imageSize;

  // ── Editor dark tokens ─────────────────────────────────────
  static const _bg = Color(0xFF0C0C11);
  static const _bgElevated = Color(0xFF1C1C24);
  static const _textHint = Color(0x80FFFFFF); // 50%

  static const _systemUi = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: _bg,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  Future<void> _resolveImageSize() async {
    final stream = FileImage(File(widget.imagePath)).resolve(
      ImageConfiguration.empty,
    );
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
    }));
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Rect _computeCropRect(Size viewfinderSize) {
    if (_imageSize == null) return const Rect.fromLTWH(0, 0, 1, 1);

    final imgW = _imageSize!.width;
    final imgH = _imageSize!.height;
    final viewAR = viewfinderSize.width / viewfinderSize.height;
    final imgAR = imgW / imgH;

    late final double renderedW, renderedH;
    if (imgAR > viewAR) {
      renderedH = viewfinderSize.height;
      renderedW = renderedH * imgAR;
    } else {
      renderedW = viewfinderSize.width;
      renderedH = renderedW / imgAR;
    }

    final m = _transformController.value;
    final scale = m.getMaxScaleOnAxis();
    final tx = m.getTranslation().x;
    final ty = m.getTranslation().y;

    final visLeft = -tx / scale;
    final visTop = -ty / scale;
    final visW = viewfinderSize.width / scale;
    final visH = viewfinderSize.height / scale;

    return Rect.fromLTWH(
      (visLeft / renderedW).clamp(0.0, 1.0),
      (visTop / renderedH).clamp(0.0, 1.0),
      (visW / renderedW).clamp(0.0, 1.0),
      (visH / renderedH).clamp(0.0, 1.0),
    );
  }

  void _onDone(Size viewfinderSize) {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, _computeCropRect(viewfinderSize));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final safeW = mq.size.width - 48;
    final safeH = mq.size.height - mq.padding.top - mq.padding.bottom - 100;

    late final double vfW, vfH;
    if (widget.canvasAspectRatio >= safeW / safeH) {
      vfW = safeW;
      vfH = safeW / widget.canvasAspectRatio;
    } else {
      vfH = safeH;
      vfW = safeH * widget.canvasAspectRatio;
    }
    final viewfinderSize = Size(vfW, vfH);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUi,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────
              _buildTopBar(viewfinderSize),

              // ── Hint ─────────────────────────────────
              _buildHint(),

              // ── Viewfinder ───────────────────────────
              Expanded(
                child: Center(
                  child: _imageSize == null
                      ? const CircularProgressIndicator(
                          color: Color(0x61FFFFFF),
                          strokeWidth: 2.5,
                        )
                      : _buildViewfinder(viewfinderSize),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Size viewfinderSize) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
            iconSize: 24,
            tooltip: LocaleKeys.blank_cancel.tr,
          ),
          const Spacer(),
          // Title
          Text(
            LocaleKeys.blank_crop_title.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          // Done button
          TextButton(
            onPressed: () => _onDone(viewfinderSize),
            style: TextButton.styleFrom(
              backgroundColor: GroundedTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, size: 16),
                const SizedBox(width: 5),
                Text(
                  LocaleKeys.blank_crop_done.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_rounded, color: _textHint, size: 13),
          const SizedBox(width: 5),
          Text(
            LocaleKeys.blank_crop_hint.tr,
            style: const TextStyle(
              color: _textHint,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder(Size viewfinderSize) {
    final imgAR = _imageSize!.width / _imageSize!.height;
    final vfAR = viewfinderSize.width / viewfinderSize.height;

    late final double renderedW, renderedH;
    if (imgAR > vfAR) {
      renderedH = viewfinderSize.height;
      renderedW = renderedH * imgAR;
    } else {
      renderedW = viewfinderSize.width;
      renderedH = renderedW / imgAR;
    }

    if (!_didCenterImage) {
      _didCenterImage = true;
      final dx = -(renderedW - viewfinderSize.width) / 2;
      final dy = -(renderedH - viewfinderSize.height) / 2;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _transformController.value = Matrix4.identity()
            ..translate(dx, dy);
        }
      });
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: viewfinderSize.width,
        height: viewfinderSize.height,
        child: Stack(
          children: [
            // Canvas background
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _bgElevated,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            // Interactive image
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 5.0,
                constrained: false,
                child: SizedBox(
                  width: renderedW,
                  height: renderedH,
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                    width: renderedW,
                    height: renderedH,
                  ),
                ),
              ),
            ),
            // Frame border overlay
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0x33FFFFFF),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            // Corner accents (top-left, top-right, bottom-left, bottom-right)
            ..._buildCornerAccents(viewfinderSize),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerAccents(Size viewfinderSize) {
    const size = 20.0;
    const thickness = 2.5;
    const offset = -0.5;
    const color = Color(0xCCFFFFFF);
    const radius = Radius.circular(18);

    Widget corner({
      required Alignment alignment,
      required BorderRadius borderRadius,
    }) {
      return Positioned(
        top: alignment.y < 0 ? offset : null,
        bottom: alignment.y > 0 ? offset : null,
        left: alignment.x < 0 ? offset : null,
        right: alignment.x > 0 ? offset : null,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border(
                top: alignment.y < 0
                    ? const BorderSide(color: color, width: thickness)
                    : BorderSide.none,
                bottom: alignment.y > 0
                    ? const BorderSide(color: color, width: thickness)
                    : BorderSide.none,
                left: alignment.x < 0
                    ? const BorderSide(color: color, width: thickness)
                    : BorderSide.none,
                right: alignment.x > 0
                    ? const BorderSide(color: color, width: thickness)
                    : BorderSide.none,
              ),
              borderRadius: borderRadius,
            ),
          ),
        ),
      );
    }

    return [
      corner(
        alignment: Alignment.topLeft,
        borderRadius: const BorderRadius.only(topLeft: radius),
      ),
      corner(
        alignment: Alignment.topRight,
        borderRadius: const BorderRadius.only(topRight: radius),
      ),
      corner(
        alignment: Alignment.bottomLeft,
        borderRadius: const BorderRadius.only(bottomLeft: radius),
      ),
      corner(
        alignment: Alignment.bottomRight,
        borderRadius: const BorderRadius.only(bottomRight: radius),
      ),
    ];
  }
}

/// Checkerboard painter for transparent background preview
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const cellSize = 6.0;
    for (var i = 0; i < (size.width / cellSize).ceil(); i++) {
      for (var j = 0; j < (size.height / cellSize).ceil(); j++) {
        paint.color = (i + j) % 2 == 0
            ? const Color(0xFFE5E5E5)
            : const Color(0xFFFFFFFF);
        canvas.drawRect(
          Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
