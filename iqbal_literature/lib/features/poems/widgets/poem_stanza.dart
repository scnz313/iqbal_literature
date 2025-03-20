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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stanza'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ... existing code ...
          ],
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
