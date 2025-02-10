import 'package:flutter/material.dart';

class HistoricalContextSheet extends StatelessWidget {
  final String bookTitle;
  final String contextData;

  const HistoricalContextSheet({
    super.key,
    required this.bookTitle,
    required this.contextData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_edu),
                const SizedBox(width: 12),
                Text(
                  'Historical Context: $bookTitle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                contextData,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
