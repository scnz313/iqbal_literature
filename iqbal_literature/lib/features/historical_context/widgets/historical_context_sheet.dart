import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/poems/controllers/poem_controller.dart';
import '../../../features/poems/models/poem.dart';
import '../models/historical_context.dart';

class HistoricalContextSheet extends StatelessWidget {
  final Poem poem;

  const HistoricalContextSheet({
    super.key, 
    required this.poem,
  });

  static void show(BuildContext context, Poem poem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8, // Increased for better visibility
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => HistoricalContextSheet(poem: poem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PoemController>();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Historical Context',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              poem.title,
              style: const TextStyle(fontFamily: 'JameelNooriNastaleeq'),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: controller.getHistoricalContext(poem.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final data = snapshot.data;
                if (data == null || data.isEmpty) {
                  return _buildErrorState('No historical context available');
                }

                final historicalContext = HistoricalContext.fromMap(data);
                return _buildContent(context, historicalContext);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analyzing historical context...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HistoricalContext data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Basic sections
        _buildSection(context, 'Year', data.year),
        const SizedBox(height: 24),
        _buildExpandableSection(
          context,
          'Historical Context',
          data.historicalContext,
        ),
        const SizedBox(height: 24),
        _buildExpandableSection(
          context,
          'Significance',
          data.significance,
        ),
        const SizedBox(height: 24),

        // Additional sections from API
        if (data.culturalImportance?.isNotEmpty ?? false)
          _buildExpandableSection(
            context,
            'Cultural Importance',
            data.culturalImportance!,
          ),
        if (data.religiousThemes?.isNotEmpty ?? false)
          _buildExpandableSection(
            context,
            'Religious Themes',
            data.religiousThemes!,
          ),
        if (data.politicalMessages?.isNotEmpty ?? false)
          _buildExpandableSection(
            context,
            'Political Messages',
            data.politicalMessages!,
          ),
        if (data.imagery?.isNotEmpty ?? false)
          _buildExpandableSection(
            context,
            'Imagery',
            data.imagery!,
          ),
        if (data.metaphor?.isNotEmpty ?? false)
          _buildExpandableSection(
            context,
            'Metaphor',
            data.metaphor!,
          ),
        if (data.symbolism?.isNotEmpty ?? false)
          _buildExpandableSection(
            context,
            'Symbolism',
            data.symbolism!,
          ),
        if (data.theme?.isNotEmpty ?? false)
          _buildExpandableSection(
            context,
            'Theme',
            data.theme!,
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    if (content.isEmpty || content == 'Not available') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(
          content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection(BuildContext context, String title, String content) {
    if (content.isEmpty || content == 'Not available') {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
