import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/designs/grounded/grounded_design.dart';
import 'package:pro_image_editor/core/mixins/converted_configs.dart';
import 'package:pro_image_editor/core/mixins/editor_configs_mixin.dart';

import '../../../../generated/locales.g.dart';
import 'custom_sticker_editor.dart';
import 'image_layer_editor.dart';

/// InShot-style main editor bottom bar
/// Clean icons with elegant styling and RTL support
class MainEditorBottomBarCustom extends StatefulWidget with SimpleConfigsAccess {
  const MainEditorBottomBarCustom({
    super.key,
    required this.configs,
    required this.callbacks,
    required this.editor,
    required this.toolbarScrollController,
  });

  final ProImageEditorState editor;
  
  /// External scroll controller to preserve scroll position across rebuilds
  final ScrollController toolbarScrollController;

  @override
  final ProImageEditorConfigs configs;
  @override
  final ProImageEditorCallbacks callbacks;

  @override
  State<MainEditorBottomBarCustom> createState() => _MainEditorBottomBarCustomState();
}

class _MainEditorBottomBarCustomState extends State<MainEditorBottomBarCustom>
    with ImageEditorConvertedConfigs, SimpleConfigsAccessState {

  void _openEmojiEditor() async {
    HapticFeedback.selectionClick();
    Layer? layer = await widget.editor.openPage(GroundedEmojiEditor(
      configs: configs,
      callbacks: callbacks,
    ));
    if (layer == null || !mounted) return;
    layer.scale = configs.emojiEditor.initScale;
    widget.editor.addLayer(layer);
  }

  void _openStickerEditor() async {
    HapticFeedback.selectionClick();
    Layer? layer = await widget.editor.openPage(const CustomStickerEditor());
    if (layer == null || !mounted) return;
    widget.editor.addLayer(layer);
  }

  void _openImageLayerEditor() async {
    HapticFeedback.selectionClick();
    Layer? layer = await widget.editor.openPage(const ImageLayerEditor());
    if (layer == null || !mounted) return;
    widget.editor.addLayer(layer);
  }

  @override
  Widget build(BuildContext context) {
    // Hide when sub-editor is open, but keep mounted to preserve scroll position
    final isHidden = widget.editor.isSubEditorOpen && !widget.editor.isSubEditorClosing;

    return Offstage(
      offstage: isHidden,
      child: Container(
        color: const Color(0xFF000000),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tools row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
              child: SingleChildScrollView(
                key: const PageStorageKey<String>('editor_toolbar_scroll'),
                controller: widget.toolbarScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8, end: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: _buildToolList()
                        .asMap()
                        .entries
                        .map((entry) => Padding(
                              // No start padding on first item to align with undo/redo
                              padding: EdgeInsetsDirectional.only(
                                start: entry.key == 0 ? 0 : 4,
                                end: 0,
                              ),
                              child: entry.value,
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildToolList() {
    final tools = widget.editor.configs.mainEditor.tools;

    final baseTools = tools
        .map((tool) {
          switch (tool) {
            case SubEditorMode.paint:
              return _ToolItem(
                icon: Icons.brush_rounded,
                label: i18n.paintEditor.bottomNavigationBarText,
                onTap: widget.editor.openPaintEditor,
              );

            case SubEditorMode.text:
              return _ToolItem(
                icon: Icons.text_fields_rounded,
                label: i18n.textEditor.bottomNavigationBarText,
                onTap: widget.editor.openTextEditor,
              );

            case SubEditorMode.cropRotate:
              return _ToolItem(
                icon: Icons.crop_rotate_rounded,
                label: i18n.cropRotateEditor.bottomNavigationBarText,
                onTap: widget.editor.openCropRotateEditor,
              );

            case SubEditorMode.tune:
              return _ToolItem(
                icon: Icons.tune_rounded,
                label: i18n.tuneEditor.bottomNavigationBarText,
                onTap: widget.editor.openTuneEditor,
              );

            case SubEditorMode.filter:
              return _ToolItem(
                icon: Icons.auto_awesome_rounded,
                label: i18n.filterEditor.bottomNavigationBarText,
                onTap: widget.editor.openFilterEditor,
              );

            case SubEditorMode.blur:
              return _ToolItem(
                icon: Icons.blur_on_rounded,
                label: i18n.blurEditor.bottomNavigationBarText,
                onTap: widget.editor.openBlurEditor,
              );

            case SubEditorMode.emoji:
              return _ToolItem(
                icon: Icons.emoji_emotions_rounded,
                label: i18n.emojiEditor.bottomNavigationBarText,
                onTap: _openEmojiEditor,
              );

            case SubEditorMode.sticker:
              return _ToolItem(
                icon: Icons.sticky_note_2_rounded,
                label: i18n.stickerEditor.bottomNavigationBarText,
                onTap: _openStickerEditor,
              );

            // v12 additions — not used in this app
            case SubEditorMode.audio:
            case SubEditorMode.videoClips:
              return null;
          }
        })
        .whereType<Widget>()
        .toList();

    // Add Image tool at the end
    final toolList = baseTools;
    toolList.add(
      _ToolItem(
        icon: Icons.add_photo_alternate_rounded,
        label: LocaleKeys.tools_image.tr,
        onTap: _openImageLayerEditor,
      ),
    );

    return toolList;
  }
}

/// Clean tool item with icon and label
class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1AFFFFFF), // 10% white
                  border: Border.all(
                    color: const Color(0x1AFFFFFF),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xB3FFFFFF), // 70% white
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
