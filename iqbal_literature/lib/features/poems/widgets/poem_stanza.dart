import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/poem_controller.dart';
import 'note_dialog.dart';
import '../../../widgets/analysis/word_analysis_sheet.dart';

class PoemStanza extends StatefulWidget {
  final int poemId;
  final String stanza;

  const PoemStanza({
    super.key,
    required this.poemId,
    required this.stanza,
  });

  @override
  State<PoemStanza> createState() => _PoemStanzaState();
}

class _PoemStanzaState extends State<PoemStanza> {
  @override
  Widget build(BuildContext context) {
    final words = widget.stanza.split(' ');
    // Note: For RTL languages like Urdu/Persian, we don't need to reverse the words
    // as the Directionality widget with TextDirection.rtl will handle the display correctly

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stanza'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 8.0,
              runSpacing: 4.0,
              children: words
                  .map((word) => _buildWord(word, words.indexOf(word)))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWord(String word, int index) {
    return GestureDetector(
      onDoubleTap: () {
        _showNoteDialog(word, index);
      },
      onLongPress: () {
        _showWordAnalysis(word);
      },
      child: Text(
        word,
        style: _getWordStyle(word),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  void _showNoteDialog(String word, int index) {
    showDialog(
      context: context,
      builder: (context) => NoteDialog(
        poemId: widget.poemId,
        word: word,
        position: index,
        verse: widget.stanza,
      ),
    );
  }

  void _showWordAnalysis(String word) {
    final controller = Get.find<PoemController>();
    controller.analyzeWord(word).then((analysis) {
      if (analysis != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => WordAnalysisSheet(analysis: analysis),
        );
      }
    });
  }

  TextStyle _getWordStyle(String word) {
    // Implement the logic to determine the appropriate TextStyle based on the word
    return const TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
    );
  }
}
