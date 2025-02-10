import 'package:flutter/material.dart';

class PoemStanzaWidget extends StatelessWidget {
  final List<String> verses;
  final int startLineNumber;
  final double fontSize;
  final Function(String)? onWordTap;

  const PoemStanzaWidget({
    super.key,
    required this.verses,
    required this.startLineNumber,
    this.fontSize = 24,
    this.onWordTap,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
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
            const SizedBox(width: 16),
            
            // Verse text
            Expanded(
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
                onSelectionChanged: (selection, cause) {
                  if (cause == SelectionChangedCause.tap && onWordTap != null) {
                    final selectedText = verse.substring(
                      selection.baseOffset,
                      selection.extentOffset,
                    ).trim();
                    if (selectedText.isNotEmpty) {
                      onWordTap!(selectedText);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
