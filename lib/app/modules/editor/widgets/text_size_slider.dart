import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/shared/widgets/animated/fade_in_left.dart';
import 'package:pro_image_editor/designs/grounded/constants/grounded_constants.dart';

/// Custom text size slider that works correctly in both LTR and RTL modes.
/// 
/// The original GroundedTextSizeSlider has a bug where the slider direction
/// is inverted in RTL mode. This widget forces LTR direction for the slider
/// to ensure consistent behavior.
class TextSizeSliderCustom extends StatelessWidget {
  const TextSizeSliderCustom({
    super.key,
    required this.textEditor,
  });

  final TextEditorState textEditor;

  @override
  Widget build(BuildContext context) {
    return FadeInLeft(
      duration: kGroundedFadeInDuration * 2,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          margin: const EdgeInsetsDirectional.only(end: 16),
          width: 16,
          height: min(
              280,
              MediaQuery.sizeOf(context).height -
                  MediaQuery.viewInsetsOf(context).bottom -
                  kToolbarHeight -
                  kBottomNavigationBarHeight -
                  MediaQuery.paddingOf(context).top),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'A',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              Flexible(
                // Force LTR direction to fix slider behavior in RTL mode
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: SliderTheme(
                      data: SliderThemeData(
                        overlayShape: SliderComponentShape.noThumb,
                      ),
                      child: StatefulBuilder(builder: (context, setState) {
                        return Slider(
                          onChanged: (value) {
                            textEditor.fontScale = 4.5 - value;
                            setState(() {});
                          },
                          min: 0.5,
                          max: 4,
                          value: max(0.5, min(4.5 - textEditor.fontScale, 4)),
                          thumbColor: Colors.white,
                          inactiveColor: Colors.white60,
                          activeColor: Colors.white60,
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const Text(
                'A',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
