import 'package:flutter/material.dart';
import '../../../services/analysis/text_analysis_service.dart';
import '../../../widgets/analysis/word_analysis_sheet.dart';
import '../../poems/widgets/poem_stanza_widget.dart';

class PoemText extends StatelessWidget {
  final String text;
  final String languageCode;
  final TextAnalysisService analysisService;
  final double fontSize;

  const PoemText({
    super.key,
    required this.text,
    required this.languageCode,
    required this.analysisService,
    this.fontSize = 24,
  });

  void _showWordAnalysis(BuildContext context, String word) async {
    try {
      final analysis = await analysisService.analyzeWord(word);
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => WordAnalysisSheet(analysis: analysis),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final verses = text.split('\n');
    var lineNumber = 1;

    return Column(
      children: [
        for (final verse in verses)
          if (verse.trim().isNotEmpty)
            PoemStanzaWidget(
              verses: [verse],
              startLineNumber: lineNumber++,
              fontSize: fontSize,
              onWordTap: (word) => _showWordAnalysis(context, word),
            ),
      ],
    );
  }
}
