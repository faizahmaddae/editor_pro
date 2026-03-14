import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/core/mixins/converted_configs.dart';
import 'package:pro_image_editor/core/mixins/editor_configs_mixin.dart';

import '../../../core/fonts/font_catalog.dart';
import '../../../core/theme/grounded_theme.dart';
import 'text_shadow_panel.dart';

/// Instagram-style text editor bottom bar
/// Clean, minimal design with elegant font selection
/// Auto-detects Persian/English text and switches fonts accordingly
class GroundedTextBarCustom extends StatefulWidget with SimpleConfigsAccess {
  const GroundedTextBarCustom({
    super.key,
    required this.configs,
    required this.callbacks,
    required this.editor,
    required this.i18nColor,
    required this.showColorPicker,
    required this.showShadowColorPicker,
    required this.onShadowChanged,
  });

  final TextEditorState editor;

  @override
  final ProImageEditorConfigs configs;
  @override
  final ProImageEditorCallbacks callbacks;

  final String i18nColor;
  final Function(Color currentColor) showColorPicker;
  final Function(Color currentColor, Function(Color) onColorChanged) showShadowColorPicker;
  final Function(TextShadowConfig config) onShadowChanged;

  @override
  State<GroundedTextBarCustom> createState() => _GroundedTextBarCustomState();
}

class _GroundedTextBarCustomState extends State<GroundedTextBarCustom>
    with ImageEditorConvertedConfigs, SimpleConfigsAccessState {
  late final ScrollController _fontScrollCtrl;
  
  // Track which font group is displayed (auto-detected or manually toggled)
  FontGroup _currentFontGroup = FontGroup.english;
  
  // Track if we've already applied auto font for this language switch
  FontGroup? _lastAutoAppliedGroup;
  
  // Flag to prevent auto-font when editing existing text
  bool _isEditingExistingText = false;
  
  // Shadow panel visibility
  bool _showShadowPanel = false;
  
  // Shadow configuration
  TextShadowConfig _shadowConfig = const TextShadowConfig();
  
  // Text formatting state
  bool _isBold = false;
  bool _isItalic = false;

  @override
  void initState() {
    super.initState();
    _fontScrollCtrl = ScrollController();
    
    // Check if we're editing existing text (has content on init)
    _isEditingExistingText = widget.editor.textCtrl.text.isNotEmpty;
    
    // Restore shadow config from existing text style if editing
    _restoreShadowFromStyle();
    
    // Restore bold/italic state from existing text style if editing
    _restoreFormattingFromStyle();
    
    // Listen to text changes for auto language detection
    widget.editor.textCtrl.addListener(_onTextChanged);
    
    // Initial detection based on any existing text (deferred to avoid build issues)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _detectAndUpdateLanguage(widget.editor.textCtrl.text, canJumpScroll: false, applyDefaultFont: false);
      }
    });
  }

  @override
  void dispose() {
    widget.editor.textCtrl.removeListener(_onTextChanged);
    _fontScrollCtrl.dispose();
    super.dispose();
  }
  
  void _toggleShadowPanel() {
    setState(() {
      _showShadowPanel = !_showShadowPanel;
    });
    if (_showShadowPanel) {
      // Hide keyboard when showing shadow panel
      widget.editor.focusNode.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } else {
      // Show keyboard when hiding shadow panel
      widget.editor.focusNode.requestFocus();
    }
  }
  
  // Store the background mode before shadow was enabled
  LayerBackgroundMode? _savedBackgroundMode;
  
  void _onShadowConfigChanged(TextShadowConfig config) {
    final wasEnabled = _shadowConfig.enabled;
    final isEnabled = config.enabled;
    
    // When enabling shadow, switch to onlyColor (no background)
    if (!wasEnabled && isEnabled) {
      _savedBackgroundMode = widget.editor.backgroundColorMode;
      // Set to onlyColor to remove background — cap iterations to avoid infinite loop
      for (int i = 0; i < 5 && widget.editor.backgroundColorMode != LayerBackgroundMode.onlyColor; i++) {
        widget.editor.toggleBackgroundMode();
      }
    }
    // When disabling shadow, restore previous background mode
    else if (wasEnabled && !isEnabled && _savedBackgroundMode != null) {
      for (int i = 0; i < 5 && widget.editor.backgroundColorMode != _savedBackgroundMode; i++) {
        widget.editor.toggleBackgroundMode();
      }
      _savedBackgroundMode = null;
    }
    
    setState(() => _shadowConfig = config);
    widget.onShadowChanged(config);
  }
  
  void _showShadowColorPicker() {
    widget.showShadowColorPicker(_shadowConfig.color, (color) {
      final newConfig = _shadowConfig.copyWith(color: color);
      _onShadowConfigChanged(newConfig);
    });
  }
  
  /// Restore shadow configuration from existing text style (when editing)
  void _restoreShadowFromStyle() {
    final shadows = widget.editor.selectedTextStyle.shadows;
    if (shadows != null && shadows.isNotEmpty) {
      final shadow = shadows.first;
      _shadowConfig = TextShadowConfig(
        enabled: true,
        color: shadow.color,
        blurRadius: shadow.blurRadius,
        offset: shadow.offset,
      );
      // Also notify parent so it knows shadow is active
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onShadowChanged(_shadowConfig);
        }
      });
    }
  }
  
  /// Restore bold/italic state from existing text style (when editing)
  void _restoreFormattingFromStyle() {
    final style = widget.editor.selectedTextStyle;
    _isBold = style.fontWeight == FontWeight.bold || 
              style.fontWeight == FontWeight.w700 ||
              style.fontWeight == FontWeight.w800 ||
              style.fontWeight == FontWeight.w900;
    _isItalic = style.fontStyle == FontStyle.italic;
  }
  
  /// Toggle bold formatting
  void _toggleBold() {
    setState(() => _isBold = !_isBold);
    _applyCurrentFormatting();
  }
  
  /// Toggle italic formatting
  void _toggleItalic() {
    setState(() => _isItalic = !_isItalic);
    _applyCurrentFormatting();
  }
  
  /// Apply current formatting (bold/italic) to the text style
  void _applyCurrentFormatting() {
    final currentStyle = widget.editor.selectedTextStyle;
    final newStyle = currentStyle.copyWith(
      fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
      shadows: _shadowConfig.toShadowList(),
    );
    widget.editor.setTextStyle(newStyle);
  }
  
  /// Apply font while preserving all current user customizations
  void _applyFontWithShadow(TextStyle fontStyle) {
    final currentStyle = widget.editor.selectedTextStyle;
    final newStyle = currentStyle.copyWith(
      fontFamily: fontStyle.fontFamily,
      fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
      shadows: _shadowConfig.toShadowList(),
    );
    widget.editor.setTextStyle(newStyle);
  }
  
  /// Called whenever the text changes - detects language and updates fonts
  void _onTextChanged() {
    // Defer to next frame to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Only apply default font if NOT editing existing text
        _detectAndUpdateLanguage(
          widget.editor.textCtrl.text,
          applyDefaultFont: !_isEditingExistingText,
        );
        // After first change, we're no longer editing existing text
        _isEditingExistingText = false;
      }
    });
  }
  
  /// Detects the language of the text and updates font list + default font
  void _detectAndUpdateLanguage(String text, {bool canJumpScroll = true, bool applyDefaultFont = true}) {
    final detectedGroup = FontCatalog.detectLanguage(text, currentGroup: _currentFontGroup);
    
    // Only update if language changed
    if (detectedGroup != _currentFontGroup) {
      setState(() {
        _currentFontGroup = detectedGroup;
        // Only jump scroll if controller is attached
        if (canJumpScroll && _fontScrollCtrl.hasClients) {
          _fontScrollCtrl.jumpTo(0);
        }
      });
      
      // Auto-apply default font for the detected language (only if allowed and only once per switch)
      if (applyDefaultFont && _lastAutoAppliedGroup != detectedGroup) {
        // Check if current font already belongs to the detected group - if so, don't change it
        if (!_isCurrentFontInGroup(detectedGroup)) {
          _lastAutoAppliedGroup = detectedGroup;
          _applyDefaultFontForGroup(detectedGroup);
        }
      }
    }
  }
  
  /// Check if the currently selected font belongs to the given group
  bool _isCurrentFontInGroup(FontGroup group) {
    final currentStyle = widget.editor.selectedTextStyle;
    final fonts = group == FontGroup.persian ? FontCatalog.persianFonts : FontCatalog.englishFonts;
    final allFonts = FontCatalog.allFonts;
    final styles = textEditorConfigs.customTextStyles!;
    
    for (final font in fonts) {
      final fontIndex = allFonts.indexOf(font);
      if (fontIndex >= 0 && fontIndex < styles.length) {
        if (styles[fontIndex].hashCode == currentStyle.hashCode) {
          return true;
        }
      }
    }
    return false;
  }
  
  /// Applies the default font for the given language group (preserves shadow)
  void _applyDefaultFontForGroup(FontGroup group) {
    final defaultFont = group == FontGroup.persian 
        ? FontCatalog.defaultPersianFont 
        : FontCatalog.defaultEnglishFont;
    
    final allFonts = FontCatalog.allFonts;
    final styles = textEditorConfigs.customTextStyles!;
    final fontIndex = allFonts.indexOf(defaultFont);
    
    if (fontIndex >= 0 && fontIndex < styles.length) {
      _applyFontWithShadow(styles[fontIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              // Font list (hide when shadow panel is open to save space)
              if (!_showShadowPanel) ...[
                _buildFontList(),
                const SizedBox(height: 16),
              ],
              // Tool bar (icons only)
              _buildToolBar(),
              const SizedBox(height: 12),
              // Shadow panel (shown when shadow button is tapped)
              if (_showShadowPanel)
                TextShadowPanel(
                  initialConfig: _shadowConfig,
                  onConfigChanged: _onShadowConfigChanged,
                  onClose: _toggleShadowPanel,
                  onColorPickerTap: _showShadowColorPicker,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontList() {
    final styles = textEditorConfigs.customTextStyles!;
    final allFonts = FontCatalog.allFonts;
    final fonts = _currentFontGroup == FontGroup.persian 
        ? FontCatalog.persianFonts 
        : FontCatalog.englishFonts;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        controller: _fontScrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: fonts.length,
        itemBuilder: (context, index) {
          final fontEntry = fonts[index];
          final allFontsIndex = allFonts.indexOf(fontEntry);
          if (allFontsIndex < 0 || allFontsIndex >= styles.length) {
            return const SizedBox.shrink();
          }

          final item = styles[allFontsIndex];
          final selected = widget.editor.selectedTextStyle;
          // Compare font family instead of hashCode to ignore shadow differences
          final isSelected = selected.fontFamily == item.fontFamily;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FontChip(
              label: fontEntry.displayName,
              fontStyle: item,
              isSelected: isSelected,
              onTap: () => _applyFontWithShadow(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolBar() {
    final isPersian = _currentFontGroup == FontGroup.persian;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Language toggle (Persian/English) - manual override
          _ToolButton(
            icon: isPersian ? Icons.language : Icons.abc_rounded,
            label: isPersian ? 'فا' : 'En',
            isActive: true,
            onTap: () {
              setState(() {
                // Manual toggle overrides auto-detection
                _currentFontGroup = isPersian ? FontGroup.english : FontGroup.persian;
                _lastAutoAppliedGroup = _currentFontGroup; // Prevent auto-switch back
                _fontScrollCtrl.jumpTo(0);
              });
              // Apply default font for the manually selected group
              _applyDefaultFontForGroup(_currentFontGroup);
            },
            isSmall: true,
          ),
          // Bold
          _ToolButton(
            icon: Icons.format_bold_rounded,
            isActive: _isBold,
            onTap: _toggleBold,
            isSmall: true,
          ),
          // Italic
          _ToolButton(
            icon: Icons.format_italic_rounded,
            isActive: _isItalic,
            onTap: _toggleItalic,
            isSmall: true,
          ),
          // Color
          _ToolButton(
            icon: Icons.palette_outlined,
            isActive: false,
            onTap: () => widget.showColorPicker(widget.editor.primaryColor),
            customChild: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.editor.primaryColor,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            isSmall: true,
          ),
          // Shadow
          _ToolButton(
            icon: Icons.blur_on_rounded,
            isActive: _showShadowPanel || _shadowConfig.enabled,
            onTap: _toggleShadowPanel,
            customChild: _shadowConfig.enabled 
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.blur_on_rounded, color: Colors.white, size: 22),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: GroundedTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
            isSmall: true,
          ),
          // Align
          _ToolButton(
            icon: _getAlignIcon(),
            isActive: false,
            onTap: () => widget.editor.toggleTextAlign(),
            isSmall: true,
          ),
          // Background mode
          _ToolButton(
            icon: Icons.format_color_fill_rounded,
            isActive: false,
            onTap: () => widget.editor.toggleBackgroundMode(),
            isSmall: true,
          ),
        ],
      ),
    );
  }

  IconData _getAlignIcon() {
    switch (widget.editor.align) {
      case TextAlign.left:
        return Icons.format_align_left_rounded;
      case TextAlign.right:
        return Icons.format_align_right_rounded;
      case TextAlign.center:
      default:
        return Icons.format_align_center_rounded;
    }
  }
}

/// Elegant font chip with glass effect
class _FontChip extends StatelessWidget {
  const _FontChip({
    required this.label,
    required this.fontStyle,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final TextStyle fontStyle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected 
              ? Colors.white 
              : Colors.white.withValues(alpha: 0.12),
          border: Border.all(
            color: isSelected 
                ? Colors.white 
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label.length > 10 ? '${label.substring(0, 9)}…' : label,
            style: fontStyle.copyWith(
              fontSize: 14,
              height: 1.0,
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean tool button
class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.label,
    this.customChild,
    this.isSmall = false,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String? label;
  final Widget? customChild;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final size = isSmall ? 44.0 : 52.0;
    final iconSize = isSmall ? 22.0 : 24.0;
    
    return Semantics(
      label: label ?? icon.toString(),
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
                ? Colors.white.withValues(alpha: 0.25) 
                : Colors.white.withValues(alpha: 0.1),
            border: isActive 
                ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5)
                : null,
          ),
          child: Center(
            child: customChild ?? (
              label != null 
                ? Text(
                    label!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmall ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: label == 'فا' ? 'Vazir' : null,
                    ),
                  )
                : Icon(
                    icon,
                    color: Colors.white,
                    size: iconSize,
                  )
            ),
          ),
        ),
      ),
    );
  }
}
