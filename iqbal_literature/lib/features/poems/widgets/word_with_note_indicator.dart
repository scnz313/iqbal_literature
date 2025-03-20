import 'package:flutter/material.dart';

class WordWithNoteIndicator extends StatelessWidget {
  final String word;
  final bool hasNote;
  final VoidCallback onTap;
  final double fontSize;

  const WordWithNoteIndicator({
    super.key,
    required this.word,
    required this.hasNote,
    required this.onTap,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Word text with optional decoration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: hasNote
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                  )
                : null,
            child: Text(
              word,
              style: TextStyle(
                fontFamily: 'JameelNooriNastaleeq',
                fontSize: fontSize,
                color: hasNote
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),

          // Note indicator
          if (hasNote)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
