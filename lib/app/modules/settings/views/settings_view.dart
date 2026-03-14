import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/theme/grounded_theme.dart';
import '../../../routes/app_pages.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GroundedTheme.background,
      appBar: AppBar(
        backgroundColor: GroundedTheme.surface,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          LocaleKeys.settings_title.tr,
          style: GroundedTheme.titleLarge,
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // === Appearance Section ===
          _SectionHeader(LocaleKeys.settings_appearance.tr),
          _CardGroup(children: [
            _buildThemeModeTile(),
            const _GroupDivider(),
            _buildLanguageTile(),
          ]),

          const SizedBox(height: 28),

          // === Export Section ===
          _SectionHeader(LocaleKeys.settings_export.tr),
          Obx(() => _CardGroup(children: [
            _buildOutputFormatTile(),
            const _GroupDivider(),
            _buildExportQualityTile(),
            const _GroupDivider(),
            _buildMaxOutputSizeTile(),
            const _GroupDivider(),
            _buildSwitchTile(
              title: LocaleKeys.settings_save_gallery.tr,
              subtitle: LocaleKeys.settings_save_gallery_desc.tr,
              value: controller.saveToGallery.value,
              onChanged: controller.toggleSaveToGallery,
              icon: Icons.photo_library_outlined,
            ),
          ])),

          const SizedBox(height: 28),

          // === Performance Section ===
          _SectionHeader(LocaleKeys.settings_performance.tr),
          Obx(() => _CardGroup(children: [
            _buildSwitchTile(
              title: LocaleKeys.settings_background_gen.tr,
              subtitle: LocaleKeys.settings_background_gen_desc.tr,
              value: controller.enableBackgroundGeneration.value,
              onChanged: controller.toggleBackgroundGeneration,
              icon: Icons.speed_outlined,
            ),
            const _GroupDivider(),
            _buildSwitchTile(
              title: LocaleKeys.settings_isolate_gen.tr,
              subtitle: LocaleKeys.settings_isolate_gen_desc.tr,
              value: controller.enableIsolateGeneration.value,
              onChanged: controller.toggleIsolateGeneration,
              icon: Icons.memory_outlined,
            ),
          ])),

          const SizedBox(height: 28),

          // === Editor Section ===
          _SectionHeader(LocaleKeys.settings_editor.tr),
          Obx(() => _CardGroup(children: [
            _buildSwitchTile(
              title: LocaleKeys.settings_show_grid.tr,
              subtitle: LocaleKeys.settings_show_grid_desc.tr,
              value: controller.showGrid.value,
              onChanged: controller.toggleShowGrid,
              icon: Icons.grid_on_outlined,
            ),
            const _GroupDivider(),
            _buildSwitchTile(
              title: LocaleKeys.settings_enable_zoom.tr,
              subtitle: LocaleKeys.settings_enable_zoom_desc.tr,
              value: controller.enableZoom.value,
              onChanged: controller.toggleZoom,
              icon: Icons.zoom_in_outlined,
            ),
          ])),

          const SizedBox(height: 28),

          // === About Section ===
          _SectionHeader(LocaleKeys.settings_about.tr),
          _CardGroup(children: [
            _buildAboutTile(),
            const _GroupDivider(),
            _buildVersionTile(),
            const _GroupDivider(),
            _buildResetDefaultsTile(),
          ]),

          // === Dev Tools (debug only) ===
          if (kDebugMode) ...[
            const SizedBox(height: 28),
            _SectionHeader(LocaleKeys.settings_dev_tools.tr),
            _CardGroup(children: [
              _buildNavTile(
                title: LocaleKeys.settings_font_calibration.tr,
                subtitle: LocaleKeys.settings_font_calibration_desc.tr,
                icon: Icons.text_fields,
                iconColor: Colors.orange,
                onTap: () => Get.toNamed(Routes.FONT_CALIBRATION),
              ),
            ]),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ===== Individual tile builders =====

  Widget _buildThemeModeTile() {
    return Obx(() => SwitchListTile(
      secondary: _IconBox(
        icon: controller.isDarkMode.value
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
      ),
      title: Text(
        LocaleKeys.settings_dark_mode.tr,
        style: GroundedTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        controller.isDarkMode.value
            ? LocaleKeys.settings_dark_mode_on.tr
            : LocaleKeys.settings_dark_mode_off.tr,
        style: GroundedTheme.bodyMedium.copyWith(
          color: GroundedTheme.textTertiary,
        ),
      ),
      value: controller.isDarkMode.value,
      activeColor: Colors.white,
      activeTrackColor: const Color(0xB33B82F6),
      inactiveTrackColor: const Color(0x3D9CA3AF),
      inactiveThumbColor: Colors.white,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onChanged: controller.toggleThemeMode,
    ));
  }

  Widget _buildLanguageTile() {
    return Obx(() => ListTile(
      leading: const _IconBox(icon: Icons.language),
      title: Text(
        LocaleKeys.settings_language.tr,
        style: GroundedTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        controller.currentLanguageName,
        style: GroundedTheme.bodyMedium.copyWith(
          color: GroundedTheme.textTertiary,
        ),
      ),
      trailing: const _DirectionalChevron(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _showLanguageDialog(),
    ));
  }

  Widget _buildOutputFormatTile() {
    return ListTile(
      leading: const _IconBox(icon: Icons.image_outlined),
      title: Text(
        LocaleKeys.settings_output_format.tr,
        style: GroundedTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        controller.currentFormatLabel,
        style: GroundedTheme.bodyMedium.copyWith(
          color: GroundedTheme.textTertiary,
        ),
      ),
      trailing: const _DirectionalChevron(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _showFormatDialog(),
    );
  }

  Widget _buildExportQualityTile() {
    return ListTile(
      leading: const _IconBox(icon: Icons.high_quality_outlined),
      title: Text(
        LocaleKeys.settings_export_quality.tr,
        style: GroundedTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        controller.currentQualityLabel,
        style: GroundedTheme.bodyMedium.copyWith(
          color: GroundedTheme.textTertiary,
        ),
      ),
      trailing: const _DirectionalChevron(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _showQualitySheet(),
    );
  }

  Widget _buildMaxOutputSizeTile() {
    return ListTile(
      leading: const _IconBox(icon: Icons.photo_size_select_large_outlined),
      title: Text(
        LocaleKeys.settings_max_size.tr,
        style: GroundedTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        controller.currentSizeLabel,
        style: GroundedTheme.bodyMedium.copyWith(
          color: GroundedTheme.textTertiary,
        ),
      ),
      trailing: const _DirectionalChevron(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _showSizeDialog(),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      secondary: _IconBox(icon: icon),
      title: Text(
        title,
        style: GroundedTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GroundedTheme.bodyMedium.copyWith(
          color: GroundedTheme.textTertiary,
        ),
      ),
      value: value,
      activeColor: Colors.white,
      activeTrackColor: const Color(0xB33B82F6),
      inactiveTrackColor: const Color(0x3D9CA3AF),
      inactiveThumbColor: Colors.white,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onChanged: onChanged,
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      leading: const _IconBox(icon: Icons.info_outline),
      title: Text(
        LocaleKeys.app_title.tr,
        style: GroundedTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        LocaleKeys.settings_about_desc.tr,
        style: GroundedTheme.bodyMedium.copyWith(
          color: GroundedTheme.textTertiary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildVersionTile() {
    return ListTile(
      leading: const _IconBox(icon: Icons.verified_outlined),
      title: Text(
        LocaleKeys.settings_version.tr,
        style: GroundedTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Obx(() => Text(
        controller.appVersion.value.isNotEmpty
            ? controller.appVersion.value
            : LocaleKeys.common_loading.tr,
        style: GroundedTheme.bodyMedium.copyWith(
          color: GroundedTheme.textTertiary,
        ),
      )),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildResetDefaultsTile() {
    return ListTile(
      leading: _IconBox(
        icon: Icons.restore_outlined,
        color: GroundedTheme.warning,
      ),
      title: Text(
        LocaleKeys.settings_reset_defaults.tr,
        style: GroundedTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        LocaleKeys.settings_reset_defaults_desc.tr,
        style: GroundedTheme.bodyMedium.copyWith(
          color: GroundedTheme.textTertiary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _showResetConfirmDialog(),
    );
  }

  Widget _buildNavTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = GroundedTheme.primary,
  }) {
    return ListTile(
      onTap: onTap,
      leading: _IconBox(icon: icon, color: iconColor),
      title: Text(
        title,
        style: GroundedTheme.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GroundedTheme.bodyMedium.copyWith(
          color: GroundedTheme.textTertiary,
        ),
      ),
      trailing: const _DirectionalChevron(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // ===== Dialogs & Sheets =====

  void _showLanguageDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: GroundedTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          LocaleKeys.settings_select_language.tr,
          style: GroundedTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.languages.map((lang) {
            final locale = lang['locale'] as Locale;
            final isSelected = controller.currentLocale.value.languageCode ==
                locale.languageCode;

            return Semantics(
              selected: isSelected,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text(
                  lang['name'] as String,
                  style: GroundedTheme.titleMedium.copyWith(
                    color: isSelected
                        ? GroundedTheme.primary
                        : GroundedTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  lang['nativeName'] as String,
                  style: GroundedTheme.bodyMedium,
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: GroundedTheme.primary)
                    : null,
                onTap: () {
                  controller.changeLanguage(locale);
                  Get.back();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Quality picker — bottom sheet with a slider
  void _showQualitySheet() {
    final tempQuality = controller.exportQuality.value.obs;
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: GroundedTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GroundedTheme.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LocaleKeys.settings_export_quality.tr,
              style: GroundedTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Obx(() {
              final q = tempQuality.value;
              String label;
              if (q <= 60) {
                label = LocaleKeys.settings_quality_low.tr;
              } else if (q <= 75) {
                label = LocaleKeys.settings_quality_medium.tr;
              } else if (q <= 90) {
                label = LocaleKeys.settings_quality_high.tr;
              } else {
                label = LocaleKeys.settings_quality_max.tr;
              }
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: GroundedTheme.titleMedium),
                      Text(
                        '$q%',
                        style: GroundedTheme.titleMedium.copyWith(
                          color: GroundedTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: q.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 18,
                    activeColor: GroundedTheme.primary,
                    inactiveColor: GroundedTheme.border,
                    onChanged: (v) => tempQuality.value = v.round(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('10%', style: GroundedTheme.labelSmall),
                      Text('100%', style: GroundedTheme.labelSmall),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: GroundedTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  controller.setExportQuality(tempQuality.value);
                  Get.back();
                },
                child: Text(
                  LocaleKeys.common_apply.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showFormatDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: GroundedTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          LocaleKeys.settings_output_format.tr,
          style: GroundedTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SettingsController.formatValues.map((value) {
            final isSelected = controller.outputFormat.value == value;
            return Semantics(
              selected: isSelected,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text(
                  controller.formatLabel(value),
                  style: GroundedTheme.titleMedium.copyWith(
                    color: isSelected
                        ? GroundedTheme.primary
                        : GroundedTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  controller.formatDesc(value),
                  style: GroundedTheme.labelSmall,
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: GroundedTheme.primary)
                    : null,
                onTap: () {
                  controller.setOutputFormat(value);
                  Get.back();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSizeDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: GroundedTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          LocaleKeys.settings_max_size.tr,
          style: GroundedTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SettingsController.sizeValues.map((value) {
            final isSelected = controller.maxOutputSize.value == value;
            return Semantics(
              selected: isSelected,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text(
                  controller.sizeLabel(value),
                  style: GroundedTheme.titleMedium.copyWith(
                    color: isSelected
                        ? GroundedTheme.primary
                        : GroundedTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  controller.sizeDesc(value),
                  style: GroundedTheme.labelSmall,
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: GroundedTheme.primary)
                    : null,
                onTap: () {
                  controller.setMaxOutputSize(value);
                  Get.back();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResetConfirmDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: GroundedTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          LocaleKeys.settings_reset_defaults.tr,
          style: GroundedTheme.titleLarge,
        ),
        content: Text(
          LocaleKeys.settings_reset_confirm.tr,
          style: GroundedTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              LocaleKeys.common_cancel.tr,
              style: TextStyle(color: GroundedTheme.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GroundedTheme.warning,
            ),
            onPressed: () {
              Get.back();
              controller.resetToDefaults();
            },
            child: Text(LocaleKeys.common_confirm.tr),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Shared private widgets
// =====================================================================

/// Section header with primary-colored uppercase label
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: GroundedTheme.labelSmall.copyWith(
          color: GroundedTheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Groups child tiles into a single rounded card with surface background
class _CardGroup extends StatelessWidget {
  final List<Widget> children;
  const _CardGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final isLight = !GroundedTheme.isDarkMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: GroundedTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight ? const Color(0xFFE5E7EB) : GroundedTheme.border,
          width: 0.5,
        ),
        boxShadow: isLight
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
            : const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: isLight
              ? const Color(0x0F3B82F6)
              : const Color(0x1AFFFFFF),
          highlightColor: isLight
              ? const Color(0x0A3B82F6)
              : const Color(0x0DFFFFFF),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

/// Thin divider inside a card group
class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 60,
      color: GroundedTheme.divider,
    );
  }
}

/// Rounded icon container used as leading widget in every tile
class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, this.color = GroundedTheme.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

/// Trailing chevron that flips in RTL.
class _DirectionalChevron extends StatelessWidget {
  const _DirectionalChevron();

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      isRtl ? Icons.chevron_left : Icons.chevron_right,
      color: GroundedTheme.textTertiary,
      size: 20,
    );
  }
}
