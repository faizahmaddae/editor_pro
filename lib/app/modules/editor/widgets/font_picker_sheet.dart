import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../generated/locales.g.dart';
import '../../../core/fonts/font_catalog.dart';
import '../../../core/theme/grounded_theme.dart';

/// Grounded-style font picker bottom sheet
class FontPickerSheet extends StatefulWidget {
  final void Function(FontEntry) onFontSelected;

  const FontPickerSheet({
    super.key,
    required this.onFontSelected,
  });

  @override
  State<FontPickerSheet> createState() => _FontPickerSheetState();
}

class _FontPickerSheetState extends State<FontPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Cached filtered results — invalidated when _searchQuery changes
  List<FontEntry>? _cachedEnglish;
  List<FontEntry>? _cachedPersian;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<FontEntry> get _filteredEnglishFonts {
    return _cachedEnglish ??= FontCatalog.search(_searchQuery)
        .where((f) => f.group == FontGroup.english)
        .toList();
  }

  List<FontEntry> get _filteredPersianFonts {
    return _cachedPersian ??= FontCatalog.search(_searchQuery)
        .where((f) => f.group == FontGroup.persian)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchBar(),
          _buildTabs(),
          Expanded(child: _buildFontList()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            LocaleKeys.fonts_title.tr,
            style: GroundedTheme.headlineMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _cachedEnglish = null;
            _cachedPersian = null;
          });
        },
        style: GroundedTheme.bodyLarge.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: LocaleKeys.fonts_search.tr,
          hintStyle: GroundedTheme.bodyMedium.copyWith(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF252525),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      indicatorColor: GroundedTheme.primary,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white54,
      tabs: [
        Tab(text: LocaleKeys.fonts_english.tr),
        Tab(text: LocaleKeys.fonts_persian.tr),
      ],
    );
  }

  Widget _buildFontList() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildFontGrid(_filteredEnglishFonts, LocaleKeys.font_sample_english.tr),
        _buildFontGrid(_filteredPersianFonts, LocaleKeys.font_sample_persian.tr),
      ],
    );
  }

  Widget _buildFontGrid(List<FontEntry> fonts, String sampleText) {
    if (fonts.isEmpty) {
      return Center(
        child: Text(
          LocaleKeys.fonts_no_results.tr,
          style: GroundedTheme.bodyMedium.copyWith(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fonts.length,
      itemBuilder: (context, index) {
        final font = fonts[index];
        return _FontCard(
          fontEntry: font,
          sampleText: sampleText,
          onTap: () {
            widget.onFontSelected(font);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

/// Individual font card showing preview
class _FontCard extends StatelessWidget {
  final FontEntry fontEntry;
  final String sampleText;
  final VoidCallback onTap;

  const _FontCard({
    required this.fontEntry,
    required this.sampleText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fontEntry.displayName,
                        style: GroundedTheme.labelSmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sampleText,
                        style: fontEntry.style.copyWith(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  (Get.locale?.languageCode == 'fa' ||
                          Get.locale?.languageCode == 'ar')
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
