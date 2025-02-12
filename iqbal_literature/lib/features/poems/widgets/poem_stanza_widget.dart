import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PoemStanzaWidget extends StatelessWidget {
  final List<String> verses;
  final int startLineNumber;
  final double fontSize;
  final Function(String) onWordTap;

  const PoemStanzaWidget({
    super.key,
    required this.verses,
    required this.startLineNumber,
    this.fontSize = 24,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).cardColor.withAlpha(13), // 0.05 opacity
            Theme.of(context).cardColor.withAlpha(26), // 0.1 opacity
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha(26), // 0.1 opacity
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < verses.length; i++)
            _buildVerseLine(context, verses[i], startLineNumber + i),
        ],
      ),
    );
  }

  Widget _buildVerseLine(BuildContext context, String verse, int lineNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withAlpha(26), // 0.1 opacity
            width: verses.last == verse ? 0 : 1,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Line number with gradient background
            Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withAlpha(26), // 0.1 opacity
                    Theme.of(context).primaryColor.withAlpha(13), // 0.05 opacity
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$lineNumber',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor.withAlpha(204), // 0.8 opacity
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Verse text with GestureDetector for double-tap
            Expanded(
              child: GestureDetector(
                onDoubleTapDown: (details) {
                  final word = _getWordAtPosition(details, context, verse);
                  if (word.isNotEmpty) {
                    onWordTap(word);
                  }
                },
                child: SelectableText(
                  verse,
                  style: TextStyle(
                    fontFamily: 'JameelNooriNastaleeq',
                    fontSize: fontSize,
                    height: 2.2,
                    letterSpacing: 0.5,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  enableInteractiveSelection: true, // Enable default text selection
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWordAtPosition(TapDownDetails details, BuildContext context, String verse) {
    try {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final offset = box.globalToLocal(details.globalPosition);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: verse,
          style: TextStyle(
            fontFamily: 'JameelNooriNastaleeq',
            fontSize: fontSize,
            height: 2.2,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.rtl,
        maxLines: null,
      );

      textPainter.layout(maxWidth: box.size.width);
      final position = textPainter.getPositionForOffset(offset);
      
      // Get the word at position
      final words = verse.split(' ');
      final wordIndex = verse.substring(0, position.offset).split(' ').length - 1;
      
      if (wordIndex >= 0 && wordIndex < words.length) {
        return words[wordIndex].trim();
      }
    } catch (e) {
      debugPrint('Error getting word at position: $e');
    }
    return '';
  }
}
