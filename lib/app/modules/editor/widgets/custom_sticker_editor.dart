import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';
import '../../../core/widgets/glass_icon_button.dart';
import 'text_editor_bottom_panel/color_tab.dart';

/// Custom sticker editor with a clean, professional design
/// 
/// Features:
/// - Icon stickers with customizable colors
/// - Image import from gallery
/// - Category-based organization
/// - No unnecessary search bar
class CustomStickerEditor extends StatefulWidget {
  const CustomStickerEditor({super.key});

  @override
  State<CustomStickerEditor> createState() => _CustomStickerEditorState();
}

class _CustomStickerEditorState extends State<CustomStickerEditor>
    with SingleTickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoadingImage = false;
  late TabController _tabController;

  final List<_StickerCategory> categories = [
    _StickerCategory(
      name: LocaleKeys.sticker_shapes,
      icon: Icons.category_rounded,
      stickers: [
        _StickerItem(icon: Icons.star_rounded, color: Colors.amber),
        _StickerItem(icon: Icons.favorite_rounded, color: Colors.red),
        _StickerItem(icon: Icons.circle_rounded, color: Colors.blue),
        _StickerItem(icon: Icons.square_rounded, color: Colors.green),
        _StickerItem(icon: Icons.change_history_rounded, color: Colors.orange),
        _StickerItem(icon: Icons.hexagon_rounded, color: Colors.purple),
        _StickerItem(icon: Icons.pentagon_rounded, color: Colors.teal),
        _StickerItem(icon: Icons.diamond_rounded, color: Colors.pink),
        _StickerItem(icon: Icons.cruelty_free_rounded, color: Colors.brown),
        _StickerItem(icon: Icons.eco_rounded, color: Colors.lightGreen),
        _StickerItem(icon: Icons.spa_rounded, color: Colors.pinkAccent),
        _StickerItem(icon: Icons.local_florist_rounded, color: Colors.deepOrange),
      ],
    ),
    _StickerCategory(
      name: LocaleKeys.sticker_arrows,
      icon: Icons.arrow_forward_rounded,
      stickers: [
        _StickerItem(icon: Icons.arrow_upward_rounded, color: Colors.white),
        _StickerItem(icon: Icons.arrow_downward_rounded, color: Colors.white),
        _StickerItem(icon: Icons.arrow_back_rounded, color: Colors.white),
        _StickerItem(icon: Icons.arrow_forward_rounded, color: Colors.white),
        _StickerItem(icon: Icons.north_east_rounded, color: Colors.white),
        _StickerItem(icon: Icons.south_east_rounded, color: Colors.white),
        _StickerItem(icon: Icons.south_west_rounded, color: Colors.white),
        _StickerItem(icon: Icons.north_west_rounded, color: Colors.white),
        _StickerItem(icon: Icons.keyboard_double_arrow_up_rounded, color: Colors.white),
        _StickerItem(icon: Icons.keyboard_double_arrow_down_rounded, color: Colors.white),
        _StickerItem(icon: Icons.subdirectory_arrow_right_rounded, color: Colors.white),
        _StickerItem(icon: Icons.undo_rounded, color: Colors.white),
      ],
    ),
    _StickerCategory(
      name: LocaleKeys.sticker_social,
      icon: Icons.thumb_up_rounded,
      stickers: [
        _StickerItem(icon: Icons.thumb_up_rounded, color: Colors.blue),
        _StickerItem(icon: Icons.thumb_down_rounded, color: Colors.red),
        _StickerItem(icon: Icons.chat_bubble_rounded, color: Colors.green),
        _StickerItem(icon: Icons.share_rounded, color: Colors.orange),
        _StickerItem(icon: Icons.bookmark_rounded, color: Colors.purple),
        _StickerItem(icon: Icons.notifications_rounded, color: Colors.amber),
        _StickerItem(icon: Icons.verified_rounded, color: Colors.lightBlue),
        _StickerItem(icon: Icons.tag_rounded, color: Colors.pink),
        _StickerItem(icon: Icons.person_rounded, color: Colors.teal),
        _StickerItem(icon: Icons.group_rounded, color: Colors.indigo),
        _StickerItem(icon: Icons.public_rounded, color: Colors.cyan),
        _StickerItem(icon: Icons.wifi_rounded, color: Colors.deepPurple),
      ],
    ),
    _StickerCategory(
      name: LocaleKeys.sticker_weather,
      icon: Icons.wb_sunny_rounded,
      stickers: [
        _StickerItem(icon: Icons.wb_sunny_rounded, color: Colors.amber),
        _StickerItem(icon: Icons.cloud_rounded, color: Colors.grey),
        _StickerItem(icon: Icons.water_drop_rounded, color: Colors.blue),
        _StickerItem(icon: Icons.ac_unit_rounded, color: Colors.lightBlue),
        _StickerItem(icon: Icons.bolt_rounded, color: Colors.yellow),
        _StickerItem(icon: Icons.nights_stay_rounded, color: Colors.indigo),
        _StickerItem(icon: Icons.wb_cloudy_rounded, color: Colors.blueGrey),
        _StickerItem(icon: Icons.sunny_snowing, color: Colors.orange),
        _StickerItem(icon: Icons.thunderstorm_rounded, color: Colors.deepPurple),
        _StickerItem(icon: Icons.waves_rounded, color: Colors.cyan),
        _StickerItem(icon: Icons.air_rounded, color: Colors.teal),
        _StickerItem(icon: Icons.thermostat_rounded, color: Colors.red),
      ],
    ),
    _StickerCategory(
      name: LocaleKeys.sticker_objects,
      icon: Icons.lightbulb_rounded,
      stickers: [
        _StickerItem(icon: Icons.lightbulb_rounded, color: Colors.yellow),
        _StickerItem(icon: Icons.local_fire_department_rounded, color: Colors.orange),
        _StickerItem(icon: Icons.music_note_rounded, color: Colors.purple),
        _StickerItem(icon: Icons.camera_alt_rounded, color: Colors.grey),
        _StickerItem(icon: Icons.phone_rounded, color: Colors.green),
        _StickerItem(icon: Icons.email_rounded, color: Colors.red),
        _StickerItem(icon: Icons.location_on_rounded, color: Colors.redAccent),
        _StickerItem(icon: Icons.key_rounded, color: Colors.amber),
        _StickerItem(icon: Icons.lock_rounded, color: Colors.blueGrey),
        _StickerItem(icon: Icons.shopping_cart_rounded, color: Colors.teal),
        _StickerItem(icon: Icons.restaurant_rounded, color: Colors.brown),
        _StickerItem(icon: Icons.flight_rounded, color: Colors.lightBlue),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    if (_isLoadingImage) return;

    setState(() => _isLoadingImage = true);
    HapticFeedback.selectionClick();

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);

        // Copy image to app documents for persistence (so it can be restored)
        final appDir = await getApplicationDocumentsDirectory();
        final stickersDir = Directory('${appDir.path}/stickers');
        if (!await stickersDir.exists()) {
          await stickersDir.create(recursive: true);
        }
        
        // Generate unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = pickedFile.path.split('.').last;
        final persistedPath = '${stickersDir.path}/sticker_$timestamp.$extension';
        final persistedFile = await imageFile.copy(persistedPath);

        // Precache the image
        if (!mounted) return;
        await precacheImage(FileImage(persistedFile), context);

        if (mounted) {
          Navigator.pop(
            context,
            WidgetLayer(
              widget: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  persistedFile,
                  fit: BoxFit.contain,
                  width: 200,
                  height: 200,
                ),
              ),
              // Set explicit width for proper layer sizing and hit-testing after restore
              width: 200,
              // Provide exportConfigs with fileUrl so the layer can be restored
              exportConfigs: WidgetLayerExportConfigs(
                fileUrl: persistedPath,
              ),
              // Tag for layer identification in reorder sheet
              meta: const {'layerType': 'gallery_image'},
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          LocaleKeys.common_error.tr,
          LocaleKeys.sticker_image_load_failed.tr,
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  void _addSticker(_StickerItem sticker, Color color) {
    HapticFeedback.selectionClick();
    // Generate a unique ID for the sticker based on icon code point and color
    final stickerId = 'icon_${sticker.icon.codePoint}_${color.toARGB32()}';
    Navigator.pop(
      context,
      WidgetLayer(
        widget: Icon(
          sticker.icon,
          size: 100,
          color: color,
        ),
        // Set explicit width for proper layer sizing and hit-testing after restore
        width: 100,
        // Provide exportConfigs with id for restoration via _widgetLoader
        exportConfigs: WidgetLayerExportConfigs(
          id: stickerId,
        ),
        // Tag for layer identification in reorder sheet
        meta: {
          'layerType': 'sticker',
          'iconCodePoint': sticker.icon.codePoint,
          'iconColor': color.toARGB32(),
        },
      ),
    );
  }

  void _showColorPicker(_StickerItem sticker) {
    Color selectedColor = sticker.color;
    double opacity = 1.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: GroundedTheme.surfaceElevatedDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(GroundedTheme.radiusXLarge)),
          ),
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Preview
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      sticker.icon,
                      size: 48,
                      color: selectedColor.withValues(alpha: opacity),
                    ),
                  ),
                ),
                // ColorTab from text panel
                ColorTab(
                  currentColor: selectedColor,
                  onColorChanged: (c) {
                    setSheetState(() {
                      selectedColor = c.withValues(alpha: 1);
                      opacity = c.a;
                    });
                  },
                  opacity: opacity,
                  onOpacityChanged: (v) {
                    setSheetState(() => opacity = v);
                  },
                ),
                // Add button — glass style
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _addSticker(
                        sticker,
                        selectedColor.withValues(alpha: opacity),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          LocaleKeys.sticker_add.tr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GroundedTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            _buildAppBar(),
            // Gallery import button
            _buildGalleryButton(),
            // Category tabs
            _buildCategoryTabs(),
            // Sticker grid
            Expanded(child: _buildStickerGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.3),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              GlassIconButton(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                icon: Icons.close_rounded,
                tooltip: LocaleKeys.common_close.tr,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _isLoadingImage ? null : _pickImageFromGallery,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoadingImage)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white70,
                    ),
                  )
                else
                  const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isLoadingImage
                      ? LocaleKeys.sticker_loading.tr
                      : LocaleKeys.sticker_from_gallery.tr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: GroundedTheme.primary,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        splashFactory: NoSplash.splashFactory,
        tabs: categories.map((category) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  category.name.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStickerGrid() {
    return TabBarView(
      controller: _tabController,
      children: categories.map((category) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
          ),
          itemCount: category.stickers.length,
          itemBuilder: (context, index) {
            final sticker = category.stickers[index];
            return Semantics(
              label: '${category.name.tr} ${index + 1}',
              button: true,
              child: Material(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _showColorPicker(sticker),
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Icon(
                      sticker.icon,
                      size: 34,
                      color: sticker.color,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class _StickerCategory {
  final String name;
  final IconData icon;
  final List<_StickerItem> stickers;

  const _StickerCategory({
    required this.name,
    required this.icon,
    required this.stickers,
  });
}

class _StickerItem {
  final IconData icon;
  final Color color;

  const _StickerItem({
    required this.icon,
    required this.color,
  });
}

// _GlassIconButton removed — using shared GlassIconButton from core/widgets/
