import 'package:flutter/material.dart';

/// Format preset for social media/content creation
class FormatPreset {
  final String id;
  final String nameKey; // Locale key for name
  final String subtitleKey; // Locale key for subtitle (platform info)
  final double aspectRatio; // width / height
  final IconData icon;
  final List<Color> gradient;

  const FormatPreset({
    required this.id,
    required this.nameKey,
    required this.subtitleKey,
    required this.aspectRatio,
    required this.icon,
    required this.gradient,
  });
}

/// Collection of format presets for different platforms
class FormatPresets {
  /// YouTube Thumbnail - 16:9 landscape
  static const youtubeThumb = FormatPreset(
    id: 'youtube_thumb',
    nameKey: 'home_format_youtube_thumb',
    subtitleKey: 'home_format_youtube_thumb_sub',
    aspectRatio: 16 / 9, // 1.778
    icon: Icons.smart_display_rounded,
    gradient: [Color(0xFFFF0000), Color(0xFFCC0000)],
  );

  /// Instagram/TikTok Story - 9:16 vertical
  static const story = FormatPreset(
    id: 'story',
    nameKey: 'home_format_story',
    subtitleKey: 'home_format_story_sub',
    aspectRatio: 9 / 16, // 0.5625
    icon: Icons.stay_current_portrait_rounded,
    gradient: [Color(0xFFE1306C), Color(0xFFF77737)],
  );

  /// Instagram Feed Post - 4:5 portrait
  static const instagramPost = FormatPreset(
    id: 'instagram_post',
    nameKey: 'home_format_insta_post',
    subtitleKey: 'home_format_insta_post_sub',
    aspectRatio: 4 / 5, // 0.8
    icon: Icons.photo_rounded,
    gradient: [Color(0xFF405DE6), Color(0xFF833AB4)],
  );

  /// Square Post - 1:1
  static const square = FormatPreset(
    id: 'square',
    nameKey: 'home_format_square',
    subtitleKey: 'home_format_square_sub',
    aspectRatio: 1 / 1, // 1.0
    icon: Icons.crop_square_rounded,
    gradient: [Color(0xFF1DA1F2), Color(0xFF0D8BD9)],
  );

  /// Social Landscape - 1.91:1 (Facebook/Twitter/LinkedIn ads)
  static const socialLandscape = FormatPreset(
    id: 'social_landscape',
    nameKey: 'home_format_social_wide',
    subtitleKey: 'home_format_social_wide_sub',
    aspectRatio: 1.91 / 1, // 1.91
    icon: Icons.panorama_wide_angle_rounded,
    gradient: [Color(0xFF0077B5), Color(0xFF00A0DC)],
  );

  /// Wide Cinematic - 21:9 ultrawide
  static const cinematic = FormatPreset(
    id: 'cinematic',
    nameKey: 'home_format_cinematic',
    subtitleKey: 'home_format_cinematic_sub',
    aspectRatio: 21 / 9, // 2.333
    icon: Icons.movie_filter_rounded,
    gradient: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
  );

  /// Get preset by ID
  static FormatPreset? getById(String id) {
    switch (id) {
      case 'youtube_thumb':
        return youtubeThumb;
      case 'story':
        return story;
      case 'instagram_post':
        return instagramPost;
      case 'square':
        return square;
      case 'social_landscape':
        return socialLandscape;
      case 'cinematic':
        return cinematic;
      default:
        return null;
    }
  }

  /// All available presets in display order
  static List<FormatPreset> get all => [
        youtubeThumb,
        story,
        instagramPost,
        square,
        socialLandscape,
        cinematic,
      ];

  /// Format aspect ratio for display (e.g., "16:9")
  static String formatRatio(double aspectRatio) {
    // Common ratios
    if ((aspectRatio - 16 / 9).abs() < 0.01) return '16:9';
    if ((aspectRatio - 9 / 16).abs() < 0.01) return '9:16';
    if ((aspectRatio - 4 / 5).abs() < 0.01) return '4:5';
    if ((aspectRatio - 1.0).abs() < 0.01) return '1:1';
    if ((aspectRatio - 1.91).abs() < 0.01) return '1.91:1';
    if ((aspectRatio - 21 / 9).abs() < 0.01) return '21:9';
    
    // Fallback: display as decimal
    return aspectRatio.toStringAsFixed(2);
  }
}
