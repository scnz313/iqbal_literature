import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../controllers/poem_controller.dart';
import 'note_dialog.dart';
import '../../../data/models/notes/word_note.dart';

class PoemStanzaWidget extends StatelessWidget {
  final List<String> verses;
  final int startLineNumber;
  final double fontSize;
  final Function(String) onWordTap;
  final int? poemId;

  PoemStanzaWidget({
    super.key,
    required this.verses,
    required this.startLineNumber,
    this.fontSize = 24,
    required this.onWordTap,
    this.poemId,
  }) {
    assert(verses.isNotEmpty, 'PoemStanzaWidget must have at least one verse');
    debugPrint('📝 Creating PoemStanzaWidget with poemId: $poemId');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).cardColor.withOpacity(0.05),
            Theme.of(context).cardColor.withOpacity(0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: verses.last == verse ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // Center-align content
        children: [
          // Line number with gradient background (on the left)
          Container(
            width: 32,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
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
                  color: Theme.of(context).primaryColor.withOpacity(0.8),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Words container (will appear centered)
          Expanded(
            child: _buildVerseText(
                context, verse, startLineNumber + lineNumber - 1),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseText(BuildContext context, String verse, int verseNumber) {
    // Split the verse into words but maintain proper RTL order
    final words = verse.split(' ').where((word) => word.isNotEmpty).toList();
    // No need to reverse words - Directionality will handle RTL correctly

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            direction: Axis.horizontal,
            spacing: 4.0,
            runSpacing: 8.0,
            children: words.map((word) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => _handleWordDoubleTap(word, verse),
                onLongPress: () {
                  debugPrint('🔍 Long press detected on word: $word');
                  HapticFeedback.heavyImpact();
                  onWordTap(word);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    word,
                    style: TextStyle(
                      fontFamily: 'JameelNooriNastaleeq',
                      fontSize: fontSize,
                      height: 1.8,
                      color: _hasNoteForWord(word)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // This is the old implementation that processes words individually
  // Keeping for reference, but not using it
  Widget _buildVerseTextOld(
      BuildContext context, String verse, int verseNumber) {
    final words = verse.split(' ').where((word) => word.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'JameelNooriNastaleeq',
              fontSize: fontSize,
              height: 1.8,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            children: words.map((word) {
              return WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () => _handleWordDoubleTap(word, verse),
                  onLongPress: () {
                    debugPrint('🔍 Long press detected on word: $word');
                    HapticFeedback.heavyImpact();
                    onWordTap(word);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text(
                      word,
                      style: TextStyle(
                        fontFamily: 'JameelNooriNastaleeq',
                        fontSize: fontSize,
                        height: 1.8,
                        color: _hasNoteForWord(word)
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  bool _hasNoteForWord(String word) {
    final controller = Get.find<PoemController>();
    return controller.hasNoteForWord(word, _calculateWordPosition(word, '', 0));
  }

  int _calculateWordPosition(String word, String verse, int tapPosition) {
    // Create a unique position based on the word and its context
    final basePosition = verse.hashCode;
    return basePosition + tapPosition;
  }

  void _handleWordDoubleTap(String word, String verse) {
    debugPrint('📝 Double tap detected on word: $word');
    HapticFeedback.mediumImpact();
    if (poemId != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(
          content: Text('Opening note editor for "$word"...'),
          duration: const Duration(milliseconds: 800),
        ),
      );

      Future.delayed(const Duration(milliseconds: 50), () {
        showDialog(
          context: Get.context!,
          builder: (context) => NoteDialog(
            poemId: poemId!,
            word: word,
            position: _calculateWordPosition(word, verse, 0),
            verse: verse,
          ),
        ).then((_) {
          debugPrint('📝 Note dialog closed for word: $word');
        });
      });
    } else {
      debugPrint('❌ Cannot show note dialog: poemId is null');
    }
  }
}
