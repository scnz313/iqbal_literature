import 'package:flutter/material.dart';

class WordAnalysisSheet extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const WordAnalysisSheet({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Meaning',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('English: ${analysis['meaning']['english']}'),
          Text('Urdu: ${analysis['meaning']['urdu']}',
              textDirection: TextDirection.rtl),
          const SizedBox(height: 16),
          Text('Pronunciation',
              style: Theme.of(context).textTheme.titleMedium),
          Text(analysis['pronunciation']),
          const SizedBox(height: 16),
          Text('Part of Speech',
              style: Theme.of(context).textTheme.titleMedium),
          Text(analysis['partOfSpeech']),
          const SizedBox(height: 16),
          Text('Examples',
              style: Theme.of(context).textTheme.titleMedium),
          ...List.from(analysis['examples']).map((e) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• $e'),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
