import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api/openrouter_service.dart';
import '../analysis/word_analysis_sheet.dart';

class SelectableStanzaWidget extends StatelessWidget {
  final String text;
  final double fontSize;

  const SelectableStanzaWidget({
    super.key,
    required this.text,
    this.fontSize = 24,
  });

  void _showWordAnalysis(BuildContext context, String word) async {
    try {
      final analysis = await OpenRouterService.analyzeWord(word);
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
        Get.snackbar(
          'Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontFamily: 'JameelNooriNastaleeq',
        fontSize: fontSize,
        height: 2.2,
        letterSpacing: 0.5,
      ),
      onSelectionChanged: (selection, cause) {
        if (cause == SelectionChangedCause.tap) {
          final selectedText = text.substring(
            selection.baseOffset,
            selection.extentOffset,
          ).trim();
          if (selectedText.isNotEmpty) {
            _showWordAnalysis(context, selectedText);
          }
        }
      },
    );
  }
}
