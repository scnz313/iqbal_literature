import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
// Update import path
import '../../historical_context/widgets/historical_context_sheet.dart';
import '../../../features/poems/models/poem.dart';
import '../controllers/poem_controller.dart';

class PoemCard extends StatelessWidget {
  final String title;
  final Poem poem;

  const PoemCard({
    super.key,
    required this.title,
    required this.poem,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        debugPrint('Long press detected on poem: ${poem.title}');
        _showOptions(context);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          
          return Card(
            elevation: 4.0,
            margin: EdgeInsets.all(isWideScreen ? 12.0 : 8.0),
            child: Padding(
              padding: EdgeInsets.all(isWideScreen ? 20.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: isWideScreen ? 24.0 : 20.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  FutureBuilder<String>(
                    future: Get.find<PoemController>().getBookName(poem.bookId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return Text(
                        snapshot.data!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: isWideScreen ? 16.0 : 14.0,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _showOptions(BuildContext context) {
    debugPrint('Showing options for poem: ${poem.title}');
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Historical Context option
              ListTile(
                leading: const Icon(Icons.history_edu),
                title: const Text('Historical Context'),
                onTap: () {
                  debugPrint('Historical Context tapped');
                  Navigator.pop(context);
                  _showHistoricalContext(context);
                },
              ),
              // Favorites option only
              ListTile(
                leading: Obx(() => Icon(
                  Get.find<PoemController>().isFavorite(poem) 
                      ? Icons.favorite 
                      : Icons.favorite_outline,
                  color: Get.find<PoemController>().isFavorite(poem) 
                      ? Colors.red 
                      : null,
                )),
                title: Obx(() => Text(
                  Get.find<PoemController>().isFavorite(poem)
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                )),
                onTap: () {
                  Navigator.pop(context);
                  Get.find<PoemController>().toggleFavorite(poem);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoricalContext(BuildContext context) {
    debugPrint('📖 Requesting analysis for: ${poem.title}');
    HistoricalContextSheet.show(context, poem);
  }
}
