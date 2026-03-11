import 'package:flutter/material.dart';

/// Font group identifier
enum FontGroup {
  english,
  persian,
}

/// Single font entry in the catalog
class FontEntry {
  final String family;
  final String displayName;
  final FontGroup group;
  final double height;

  const FontEntry({
    required this.family,
    required this.displayName,
    required this.group,
    this.height = 1.0,
  });

  /// Get the TextStyle configured for this font
  TextStyle get style => TextStyle(fontFamily: family, height: height);

  /// Get preview style (larger, for font picker UI)
  TextStyle get previewStyle => TextStyle(
    fontFamily: family,
    fontSize: 18,
    height: height,
  );
}

/// Font Catalog - Central registry for all text-on-image fonts
/// 
/// Adding a new font:
/// 1. Add font file to assets/fonts/{english|farsi}/
/// 2. Register in pubspec.yaml under fonts section
/// 3. Add ONE entry below in the appropriate list
class FontCatalog {
  FontCatalog._();

  /// All English fonts (19 fonts)
  static const List<FontEntry> englishFonts = [
    FontEntry(
      family: 'Roboto',
      displayName: 'Roboto',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Lato',
      displayName: 'Lato',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Raleway',
      displayName: 'Raleway',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Dancing_Script',
      displayName: 'Dancing Script',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Lobster',
      displayName: 'Lobster',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Josefin_Sans',
      displayName: 'Josefin Sans',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Hanken_Grotesk',
      displayName: 'Hanken Grotesk',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Titillium_Web',
      displayName: 'Titillium Web',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Chivo_Mono',
      displayName: 'Chivo Mono',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Barriecito',
      displayName: 'Barriecito',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Bungee_Shade',
      displayName: 'Bungee Shade',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Sevillana',
      displayName: 'Sevillana',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Zen_Tokyo_Zoo',
      displayName: 'Zen Tokyo Zoo',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Rubik_80s_Fade',
      displayName: 'Rubik 80s Fade',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Rubik_Gemstones',
      displayName: 'Rubik Gemstones',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Rubik_Puddles',
      displayName: 'Rubik Puddles',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Rubik_Storm',
      displayName: 'Rubik Storm',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Rubik_Vinyl',
      displayName: 'Rubik Vinyl',
      group: FontGroup.english,
    ),
    FontEntry(
      family: 'Rubik_Wet_Paint',
      displayName: 'Rubik Wet Paint',
      group: FontGroup.english,
    ),
  ];

  /// All Persian/Farsi fonts (45 fonts) - Heights calibrated for text background
  static const List<FontEntry> persianFonts = [
    FontEntry(
      family: 'IranNastaliq',
      displayName: 'نستعلیق',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Eliya',
      displayName: 'ایلیا',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'a_soraya',
      displayName: 'ثریا',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Delbar',
      displayName: 'دلبر',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'badkhat',
      displayName: 'بد خط',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Fedra',
      displayName: 'فدرا',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Ferdosi',
      displayName: 'فردوسی',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Leyla',
      displayName: 'لیلا',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'BNazanin',
      displayName: 'نازنین',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'BTitrBd',
      displayName: 'تیتر',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'MJ',
      displayName: 'ام جی',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'BRoya',
      displayName: 'رویا',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'SOGAND',
      displayName: 'سوگند',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'BTraffic',
      displayName: 'ترافیک',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Vazir',
      displayName: 'وزیر',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Afsaneh',
      displayName: 'افسانه',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Araz',
      displayName: 'آراز',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Casablanca',
      displayName: 'کازابلانکا',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'DimaShekaste',
      displayName: 'دیما شکسته',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'DimaTahriri',
      displayName: 'دیما تحریری',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Mj_Dinar_Medium',
      displayName: 'دینار',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Flow',
      displayName: 'فلو',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Ghalam',
      displayName: 'قلم',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Hesam',
      displayName: 'حسام',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Lalezar',
      displayName: 'لاله زار',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Mosalas',
      displayName: 'مثلث',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Neirizi',
      displayName: 'نیریزی',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'A Ordibehesht shablon',
      displayName: 'اردیبهشت',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Mj_Sayeh_1',
      displayName: 'سایه',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Hekayat',
      displayName: 'حکایت',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'ANegaar',
      displayName: 'نگار',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'b_mitra',
      displayName: 'میترا',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Yekan',
      displayName: 'یکان',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'ARezvan',
      displayName: 'رضوان',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Iranian Sans',
      displayName: 'سانس',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Shabnam',
      displayName: 'شبنم',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'KhatKhati',
      displayName: 'خط خطی',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Koodak_1',
      displayName: 'کودک ۱',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Koodak_2',
      displayName: 'کودک ۲',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Shams',
      displayName: 'شمس',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Khodkar',
      displayName: 'خودکار',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Samim_Bold',
      displayName: 'صمیم',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Gandom',
      displayName: 'گندم',
      group: FontGroup.persian,
    ),
    FontEntry(
      family: 'Dirooz',
      displayName: 'دیروز',
      group: FontGroup.persian,
    ),
  ];

  /// All fonts combined
  static List<FontEntry> get allFonts => [...englishFonts, ...persianFonts];

  /// Get fonts by group
  static List<FontEntry> getByGroup(FontGroup group) {
    return allFonts.where((f) => f.group == group).toList();
  }

  /// Search fonts by name
  static List<FontEntry> search(String query, {FontGroup? group}) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) {
      return group != null ? getByGroup(group) : allFonts;
    }
    
    return allFonts.where((font) {
      final matchesQuery = font.displayName.toLowerCase().contains(normalizedQuery) ||
          font.family.toLowerCase().contains(normalizedQuery);
      final matchesGroup = group == null || font.group == group;
      return matchesQuery && matchesGroup;
    }).toList();
  }

  /// Get font by family name
  static FontEntry? getByFamily(String family) {
    try {
      return allFonts.firstWhere((f) => f.family == family);
    } catch (_) {
      return null;
    }
  }

  /// Default font
  static FontEntry get defaultFont => englishFonts.first;

  /// Default Persian font  
  static FontEntry get defaultPersianFont => persianFonts.firstWhere(
    (f) => f.family == 'Vazir',
    orElse: () => persianFonts.first,
  );

  /// Default English font
  static FontEntry get defaultEnglishFont => englishFonts.firstWhere(
    (f) => f.family == 'Roboto',
    orElse: () => englishFonts.first,
  );

  /// Detect the dominant language/script in text.
  ///
  /// Counts Persian/Arabic vs Latin characters and returns the majority group.
  /// When [currentGroup] is provided and the counts are tied, the current
  /// group is kept to prevent flickering.
  static FontGroup detectLanguage(String text, {FontGroup? currentGroup}) {
    if (text.isEmpty) return currentGroup ?? FontGroup.english;

    int persianCount = 0;
    int latinCount = 0;

    for (final codeUnit in text.runes) {
      if (_isPersianChar(codeUnit)) {
        persianCount++;
      } else if (_isLatinChar(codeUnit)) {
        latinCount++;
      }
    }

    // No script characters (only digits, spaces, punctuation) — keep current
    if (persianCount == 0 && latinCount == 0) {
      return currentGroup ?? FontGroup.english;
    }

    // Exact tie — keep current to avoid flickering
    if (persianCount == latinCount) {
      return currentGroup ?? FontGroup.english;
    }

    return persianCount > latinCount ? FontGroup.persian : FontGroup.english;
  }

  /// Returns true for Persian/Arabic Unicode codepoints.
  static bool _isPersianChar(int codeUnit) {
    return (codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
        (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
        (codeUnit >= 0x08A0 && codeUnit <= 0x08FF) ||
        (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||
        (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF);
  }

  /// Returns true for Latin alphabet codepoints.
  static bool _isLatinChar(int codeUnit) {
    return (codeUnit >= 0x0041 && codeUnit <= 0x005A) || // A-Z
        (codeUnit >= 0x0061 && codeUnit <= 0x007A) || // a-z
        (codeUnit >= 0x00C0 && codeUnit <= 0x024F); // Latin Extended
  }

  /// Get the default font for a given text based on detected language
  static FontEntry getDefaultFontForText(String text) {
    final lang = detectLanguage(text);
    return lang == FontGroup.persian ? defaultPersianFont : defaultEnglishFont;
  }

  /// Cached TextStyle list - MUST be a constant list so hashCode comparison works
  /// in pro_image_editor's font style selector buttons
  static final List<TextStyle> _textStyleCache = 
      allFonts.map((f) => f.style).toList(growable: false);

  /// Convert catalog to TextStyle list for pro_image_editor
  /// Returns the same cached list instance to ensure hashCode comparison works
  static List<TextStyle> toTextStyles() => _textStyleCache;
}
