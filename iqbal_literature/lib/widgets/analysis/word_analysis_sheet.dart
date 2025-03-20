import 'package:flutter/material.dart';

class WordAnalysisSheet extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const WordAnalysisSheet({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    // Safely extract nested map values
    final Map<String, dynamic> meaning = analysis['meaning'] is Map
        ? Map<String, dynamic>.from(analysis['meaning'])
        : {'english': 'Not available', 'urdu': 'دستیاب نہیں'};

    // Safely extract values with fallbacks
    final String english = meaning['english']?.toString() ?? 'Not available';
    final String urdu = meaning['urdu']?.toString() ?? 'دستیاب نہیں';
    final String pronunciation =
        analysis['pronunciation']?.toString() ?? 'Not available';
    final String partOfSpeech =
        analysis['partOfSpeech']?.toString() ?? 'Unknown';

    // Safely extract examples list
    final List<dynamic> examples = analysis['examples'] is List
        ? List<dynamic>.from(analysis['examples'])
        : ['Example not available'];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Meaning section
                  _buildSection(
                    context,
                    title: 'Meaning',
                    icon: Icons.translate,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(context, 'English:', english),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, 'Urdu:', urdu, isRtl: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pronunciation section
                  _buildSection(
                    context,
                    title: 'Pronunciation',
                    icon: Icons.record_voice_over,
                    content: Text(
                      pronunciation,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Part of Speech section
                  _buildSection(
                    context,
                    title: 'Part of Speech',
                    icon: Icons.category,
                    content: Text(
                      partOfSpeech,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Examples section
                  _buildSection(
                    context,
                    title: 'Examples',
                    icon: Icons.format_quote,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: examples
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• ${e.toString()}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Close button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Powered by Gemini AI',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value,
      {bool isRtl = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
      ],
    );
  }
}
