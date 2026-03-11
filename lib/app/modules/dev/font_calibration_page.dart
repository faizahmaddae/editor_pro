import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Direct import for internal RoundedBackgroundText widget
import 'package:pro_image_editor/features/text_editor/widgets/rounded_background_text/rounded_background_text.dart';
import '../../core/fonts/font_catalog.dart';

/// Font Line Height Calibration Tool
/// 
/// Use this page to find the best line height for each font.
/// Adjust the slider until the background fits the text properly,
/// then copy the results to share.
class FontCalibrationPage extends StatefulWidget {
  const FontCalibrationPage({super.key});

  @override
  State<FontCalibrationPage> createState() => _FontCalibrationPageState();
}

class _FontCalibrationPageState extends State<FontCalibrationPage> {
  // Store adjusted heights for all fonts
  late Map<String, double> _heights;
  
  // Current font index
  int _currentIndex = 0;
  
  // Filter to show only Persian fonts (where the issue is)
  bool _persianOnly = true;
  
  List<FontEntry> get _fonts => _persianOnly 
      ? FontCatalog.persianFonts 
      : FontCatalog.allFonts;
  
  FontEntry get _currentFont => _fonts[_currentIndex];
  
  @override
  void initState() {
    super.initState();
    // Initialize with current catalog heights
    _heights = {
      for (var font in FontCatalog.allFonts)
        font.family: font.height,
    };
  }
  
  double get _currentHeight => _heights[_currentFont.family] ?? 1.0;
  
  set _currentHeight(double value) {
    setState(() {
      _heights[_currentFont.family] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        title: Text(
          'Font Calibration (${_currentIndex + 1}/${_fonts.length})',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Toggle Persian only
          IconButton(
            icon: Icon(
              _persianOnly ? Icons.translate : Icons.font_download,
              color: Colors.white,
            ),
            tooltip: _persianOnly ? 'Show All Fonts' : 'Persian Only',
            onPressed: () {
              setState(() {
                _persianOnly = !_persianOnly;
                _currentIndex = 0;
              });
            },
          ),
          // Copy results button
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            tooltip: 'Copy Results',
            onPressed: _copyResults,
          ),
        ],
      ),
      body: Column(
        children: [
          // Font info header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF252525),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentFont.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentFont.family,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Height: ${_currentHeight.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Preview area
          Expanded(
            child: Container(
              color: Colors.grey[850],
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: _buildTextPreview(),
                ),
              ),
            ),
          ),
          
          // Height slider
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF161616),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('0.5', style: TextStyle(color: Colors.grey)),
                    Expanded(
                      child: Slider(
                        value: _currentHeight,
                        min: 0.5,
                        max: 3.0,
                        divisions: 50,
                        label: _currentHeight.toStringAsFixed(2),
                        onChanged: (value) {
                          _currentHeight = value;
                        },
                      ),
                    ),
                    const Text('3.0', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                
                // Quick presets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPresetButton(1.0),
                    _buildPresetButton(1.2),
                    _buildPresetButton(1.4),
                    _buildPresetButton(1.6),
                    _buildPresetButton(1.8),
                    _buildPresetButton(2.0),
                  ],
                ),
              ],
            ),
          ),
          
          // Navigation
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF252525),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentIndex > 0
                      ? () => setState(() => _currentIndex--)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                ),
                Text(
                  '${_currentIndex + 1} / ${_fonts.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: _currentIndex < _fonts.length - 1
                      ? () => setState(() => _currentIndex++)
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextPreview() {
    final style = TextStyle(
      fontFamily: _currentFont.family,
      fontSize: 32,
      height: _currentHeight,
      color: Colors.white,
    );
    
    // Sample text in Persian and English
    final singleLineText = _currentFont.group == FontGroup.persian
        ? 'سلام دنیا'
        : 'Hello World';
    final multiLineText = _currentFont.group == FontGroup.persian
        ? 'سلام دنیا\nخط دوم متن'
        : 'Hello World\nSecond Line';
    
    final textDirection = _currentFont.group == FontGroup.persian 
        ? TextDirection.rtl 
        : TextDirection.ltr;
    
    return Directionality(
      textDirection: textDirection,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Single line - Editor style (RoundedBackgroundText)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const Text(
                    'Editor Style (Single Line):',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  RoundedBackgroundText(
                    singleLineText,
                    style: style,
                    backgroundColor: Colors.blue,
                    textAlign: TextAlign.center,
                    maxTextWidth: 300,
                  ),
                ],
              ),
            ),
            
            // Multi-line - Editor style (RoundedBackgroundText)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const Text(
                    'Editor Style (Multi-Line):',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  RoundedBackgroundText(
                    multiLineText,
                    style: style,
                    backgroundColor: Colors.blue,
                    textAlign: TextAlign.center,
                    maxTextWidth: 300,
                  ),
                ],
              ),
            ),
            
            // Without background (reference)
            Column(
              children: [
                const Text(
                  'Without Background:',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  multiLineText,
                  style: style,
                  textAlign: TextAlign.center,
                  textDirection: textDirection,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPresetButton(double value) {
    final isSelected = (_currentHeight - value).abs() < 0.05;
    return TextButton(
      onPressed: () => _currentHeight = value,
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[800],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  
  void _copyResults() {
    // Generate the results as a simple format
    final buffer = StringBuffer();
    buffer.writeln('=== FONT HEIGHT CALIBRATION RESULTS ===\n');
    
    // Only include fonts where height was changed from original
    final changedFonts = <String>[];
    
    for (var font in FontCatalog.allFonts) {
      final newHeight = _heights[font.family] ?? 1.0;
      if ((newHeight - font.height).abs() > 0.01) {
        changedFonts.add('${font.family}: ${newHeight.toStringAsFixed(1)}');
      }
    }
    
    if (changedFonts.isEmpty) {
      buffer.writeln('No changes made.');
    } else {
      buffer.writeln('Changed fonts:');
      for (var change in changedFonts) {
        buffer.writeln('  $change');
      }
    }
    
    buffer.writeln('\n--- Full Persian Fonts List ---\n');
    for (var font in FontCatalog.persianFonts) {
      final height = _heights[font.family] ?? 1.0;
      buffer.writeln("'${font.family}': $height");
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Results copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
