import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Utility class for handling RTL (Right-to-Left) layout support.
/// Provides convenience methods and extensions for directional-aware layouts.
class RtlHelper {
  RtlHelper._();

  /// RTL language codes
  static const Set<String> rtlLanguages = {'fa', 'ar', 'he', 'ur'};

  /// Check if current locale is RTL
  static bool get isRtl {
    final locale = Get.locale;
    return locale != null && rtlLanguages.contains(locale.languageCode);
  }

  /// Check if a specific locale is RTL
  static bool isLocaleRtl(Locale? locale) {
    return locale != null && rtlLanguages.contains(locale.languageCode);
  }

  /// Get the text direction for current locale
  static TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Get directional padding (uses start/end instead of left/right)
  static EdgeInsetsDirectional paddingOnly({
    double start = 0,
    double end = 0,
    double top = 0,
    double bottom = 0,
  }) {
    return EdgeInsetsDirectional.only(
      start: start,
      end: end,
      top: top,
      bottom: bottom,
    );
  }

  /// Get symmetric directional padding
  static EdgeInsetsDirectional paddingSymmetric({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsetsDirectional.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  /// Get directional alignment based on RTL
  static AlignmentDirectional get alignStart => AlignmentDirectional.centerStart;
  static AlignmentDirectional get alignEnd => AlignmentDirectional.centerEnd;
  
  /// Get directional cross axis alignment
  static CrossAxisAlignment get crossAxisStart => CrossAxisAlignment.start;
  static CrossAxisAlignment get crossAxisEnd => CrossAxisAlignment.end;

  /// Get the appropriate TextAlign.start or TextAlign.end
  static TextAlign get textAlignStart => TextAlign.start;
  static TextAlign get textAlignEnd => TextAlign.end;

  /// Get the appropriate icon for back button (arrow direction).
  /// [Icons.arrow_back] has [matchTextDirection] so Flutter auto-mirrors
  /// it in RTL — no manual swap needed.
  static IconData get backIcon => Icons.arrow_back;

  /// Get the appropriate icon for forward navigation.
  /// [Icons.arrow_forward] has [matchTextDirection] so Flutter auto-mirrors
  /// it in RTL — no manual swap needed.
  static IconData get forwardIcon => Icons.arrow_forward;

  /// Get directional border radius
  static BorderRadiusDirectional borderRadiusOnly({
    double topStart = 0,
    double topEnd = 0,
    double bottomStart = 0,
    double bottomEnd = 0,
  }) {
    return BorderRadiusDirectional.only(
      topStart: Radius.circular(topStart),
      topEnd: Radius.circular(topEnd),
      bottomStart: Radius.circular(bottomStart),
      bottomEnd: Radius.circular(bottomEnd),
    );
  }

  /// Get horizontal directional border radius
  static BorderRadiusDirectional borderRadiusHorizontal({
    double start = 0,
    double end = 0,
  }) {
    return BorderRadiusDirectional.horizontal(
      start: Radius.circular(start),
      end: Radius.circular(end),
    );
  }
}

/// Extension on BuildContext for easy RTL checks
extension RtlContextExtension on BuildContext {
  /// Check if current context is in RTL mode
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Get the text direction of current context
  TextDirection get textDirection => Directionality.of(this);

  /// Get directional EdgeInsets from regular EdgeInsets
  EdgeInsetsDirectional toDirectional(EdgeInsets insets) {
    return EdgeInsetsDirectional.only(
      start: insets.left,
      end: insets.right,
      top: insets.top,
      bottom: insets.bottom,
    );
  }
}

/// Extension on EdgeInsets for converting to directional
extension EdgeInsetsDirectionalExtension on EdgeInsets {
  /// Convert to directional insets (left becomes start, right becomes end)
  EdgeInsetsDirectional get directional => EdgeInsetsDirectional.only(
        start: left,
        end: right,
        top: top,
        bottom: bottom,
      );
}

/// Extension on Alignment for directional conversions
extension AlignmentDirectionalExtension on Alignment {
  /// Convert to AlignmentDirectional (x: -1 becomes start, x: 1 becomes end)
  AlignmentDirectional get directional {
    if (x < 0) {
      return AlignmentDirectional(x, y);
    } else if (x > 0) {
      return AlignmentDirectional(x, y);
    }
    return AlignmentDirectional(0, y);
  }
}
