import 'package:flutter/material.dart';
import '../../../services/analysis/text_analysis_service.dart';
import '../../../widgets/analysis/word_analysis_sheet.dart';
import '../../poems/widgets/poem_stanza_widget.dart';
import 'package:get/get.dart';
import '../controllers/poem_controller.dart';

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
      final controller = Get.find<PoemController>();
      final analysis = await controller.analyzeWord(word);
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          enableDrag: true,
          useSafeArea: true,
          isDismissible: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (_, scrollController) =>
                WordAnalysisSheet(analysis: analysis),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Get.snackbar(
          'Error',
          'Failed to analyze word: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
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
